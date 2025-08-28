<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Location;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Events\LocationUpdated;

class LocationController extends Controller
{
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'accuracy' => 'required|numeric|min:0',
            'battery_level' => 'required|integer|between:0,100',
        ]);

        $location = Location::create([
            'user_id' => $request->user()->id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'accuracy' => $request->accuracy,
            'battery_level' => $request->battery_level,
            'timestamp' => now(),
        ]);

        // Broadcast real-time location update
        broadcast(new LocationUpdated($location));

        return response()->json([
            'success' => true,
            'message' => 'Location updated successfully'
        ]);
    }

    public function track($childId): JsonResponse
    {
        $latestLocation = Location::where('user_id', $childId)
            ->latest('timestamp')
            ->first();

        if (!$latestLocation) {
            return response()->json([
                'success' => false,
                'message' => 'No location data found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'location' => $latestLocation
        ]);
    }

    public function history($childId, Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'nullable|date',
            'limit' => 'nullable|integer|min:1|max:100'
        ]);

        $query = Location::where('user_id', $childId);

        if ($request->date) {
            $query->whereDate('timestamp', $request->date);
        }

        $locations = $query->orderBy('timestamp', 'desc')
            ->limit($request->limit ?? 50)
            ->get();

        return response()->json([
            'success' => true,
            'locations' => $locations
        ]);
    }
}
