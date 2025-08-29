<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Location;
use App\Models\FamilyMember;
use App\Models\Alert;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Events\LocationUpdated;
use App\Http\Controllers\Api\GeofenceController;

class LocationController extends Controller
{
    protected $geofenceController;

    public function __construct()
    {
        $this->geofenceController = new GeofenceController();
    }

    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'accuracy' => 'required|numeric|min:0',
            'battery_level' => 'required|integer|between:0,100',
        ]);

        $user = $request->user();

        // Check for low battery alert
        if ($request->battery_level <= 20) {
            $this->triggerLowBatteryAlert($user->id, $request->battery_level);
        }

        $location = Location::create([
            'user_id' => $user->id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'accuracy' => $request->accuracy,
            'battery_level' => $request->battery_level,
            'timestamp' => now(),
        ]);

        // Check geofence violations
        $this->geofenceController->checkViolation(
            $user->id,
            $request->latitude,
            $request->longitude
        );

        // Broadcast real-time location update
        broadcast(new LocationUpdated($location));

        return response()->json([
            'success' => true,
            'message' => 'Location updated successfully'
        ]);
    }

    public function track($childId): JsonResponse
    {
        // Verify parent-child relationship
        if (!$this->verifyParentChildRelationship(auth()->user()->id, $childId)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access'
            ], 403);
        }

        $latestLocation = Location::where('user_id', $childId)
            ->latest('timestamp')
            ->first();

        if (!$latestLocation) {
            return response()->json([
                'success' => false,
                'message' => 'No location data found'
            ], 404);
        }

        // Calculate time since last update
        $lastUpdate = now()->diffInMinutes($latestLocation->timestamp);

        return response()->json([
            'success' => true,
            'location' => $latestLocation,
            'last_update_minutes' => $lastUpdate,
            'is_recent' => $lastUpdate <= 10 // Consider recent if within 10 minutes
        ]);
    }

    public function history($childId, Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'nullable|date',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'limit' => 'nullable|integer|min:1|max:500'
        ]);

        if (!$this->verifyParentChildRelationship(auth()->user()->id, $childId)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access'
            ], 403);
        }

        $query = Location::where('user_id', $childId);

        if ($request->date) {
            $query->whereDate('timestamp', $request->date);
        } elseif ($request->start_date && $request->end_date) {
            $query->whereBetween('timestamp', [$request->start_date, $request->end_date]);
        } else {
            // Default to last 7 days
            $query->where('timestamp', '>=', now()->subWeek());
        }

        $locations = $query->orderBy('timestamp', 'desc')
            ->limit($request->limit ?? 100)
            ->get();

        // Calculate total distance traveled (approximate)
        $totalDistance = $this->calculateTotalDistance($locations);

        return response()->json([
            'success' => true,
            'locations' => $locations,
            'total_points' => $locations->count(),
            'approximate_distance_km' => round($totalDistance / 1000, 2),
            'date_range' => [
                'start' => $locations->last()?->timestamp,
                'end' => $locations->first()?->timestamp
            ]
        ]);
    }

    public function trackAllChildren(): JsonResponse
    {
        $user = auth()->user();

        if ($user->role !== 'parent') {
            return response()->json([
                'success' => false,
                'message' => 'Only parents can access this endpoint'
            ], 403);
        }

        $familyMember = FamilyMember::where('user_id', $user->id)->first();

        if (!$familyMember) {
            return response()->json([
                'success' => false,
                'message' => 'Not part of any family'
            ], 400);
        }

        // Get all children in the family
        $children = FamilyMember::with('user')
            ->where('family_id', $familyMember->family_id)
            ->where('role', 'child')
            ->get();

        $childrenLocations = [];

        foreach ($children as $child) {
            $latestLocation = Location::where('user_id', $child->user_id)
                ->latest('timestamp')
                ->first();

            $lastUpdate = $latestLocation ?
                now()->diffInMinutes($latestLocation->timestamp) : null;

            $childrenLocations[] = [
                'child' => $child->user,
                'location' => $latestLocation,
                'last_update_minutes' => $lastUpdate,
                'is_recent' => $lastUpdate && $lastUpdate <= 10,
                'status' => $this->getLocationStatus($latestLocation, $lastUpdate)
            ];
        }

        return response()->json([
            'success' => true,
            'children_locations' => $childrenLocations,
            'total_children' => $children->count()
        ]);
    }

    private function triggerLowBatteryAlert($childId, $batteryLevel): void
    {
        // Check if we already sent a low battery alert in the last 2 hours
        $recentAlert = Alert::where('child_user_id', $childId)
            ->where('type', 'battery')
            ->where('triggered_at', '>=', now()->subHours(2))
            ->first();

        if (!$recentAlert) {
            Alert::create([
                'child_user_id' => $childId,
                'type' => 'battery',
                'priority' => $batteryLevel <= 10 ? 'high' : 'medium',
                'title' => 'Low Battery Alert',
                'message' => "Child's device battery is at {$batteryLevel}%",
                'data' => [
                    'battery_level' => $batteryLevel,
                    'alert_threshold' => 20
                ],
                'triggered_at' => now()
            ]);
        }
    }

    private function calculateTotalDistance($locations)
    {
        if ($locations->count() < 2) {
            return 0;
        }

        $totalDistance = 0;
        $previousLocation = null;

        foreach ($locations->reverse() as $location) {
            if ($previousLocation) {
                $distance = $this->calculateDistance(
                    $previousLocation->latitude,
                    $previousLocation->longitude,
                    $location->latitude,
                    $location->longitude
                );
                $totalDistance += $distance;
            }
            $previousLocation = $location;
        }

        return $totalDistance;
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // meters

        $latDelta = deg2rad($lat2 - $lat1);
        $lonDelta = deg2rad($lon2 - $lon1);

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($lonDelta / 2) * sin($lonDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    private function getLocationStatus($location, $lastUpdateMinutes)
    {
        if (!$location) {
            return 'no_data';
        }

        if ($lastUpdateMinutes <= 5) {
            return 'online';
        } elseif ($lastUpdateMinutes <= 30) {
            return 'recent';
        } elseif ($lastUpdateMinutes <= 120) {
            return 'offline';
        } else {
            return 'inactive';
        }
    }

    private function verifyParentChildRelationship($parentId, $childId): bool
    {
        $parentMember = FamilyMember::where('user_id', $parentId)
            ->where('role', 'parent')
            ->first();

        if (!$parentMember) return false;

        $childMember = FamilyMember::where('user_id', $childId)
            ->where('family_id', $parentMember->family_id)
            ->where('role', 'child')
            ->first();

        return $childMember !== null;
    }
}
