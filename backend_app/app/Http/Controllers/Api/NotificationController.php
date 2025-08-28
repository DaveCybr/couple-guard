<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NotificationMirror;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Events\NotificationReceived;

class NotificationController extends Controller
{
    public function send(Request $request): JsonResponse
    {
        $request->validate([
            'app_package' => 'required|string',
            'title' => 'required|string',
            'content' => 'required|string',
            'priority' => 'required|integer|between:1,5',
            'category' => 'nullable|string',
        ]);

        $notification = NotificationMirror::create([
            'child_user_id' => $request->user()->id,
            'app_package' => $request->app_package,
            'title' => $request->title,
            'content' => $request->content,
            'priority' => $request->priority,
            'category' => $request->category,
            'timestamp' => now(),
        ]);

        // Broadcast to parent devices
        broadcast(new NotificationReceived($notification));

        return response()->json([
            'success' => true,
            'message' => 'Notification sent successfully'
        ]);
    }

    public function list($childId, Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'nullable|date',
            'app_package' => 'nullable|string',
            'limit' => 'nullable|integer|min:1|max:100'
        ]);

        $query = NotificationMirror::where('child_user_id', $childId);

        if ($request->date) {
            $query->whereDate('timestamp', $request->date);
        }

        if ($request->app_package) {
            $query->where('app_package', $request->app_package);
        }

        $notifications = $query->orderBy('timestamp', 'desc')
            ->limit($request->limit ?? 50)
            ->get();

        return response()->json([
            'success' => true,
            'notifications' => $notifications
        ]);
    }

    public function markRead(Request $request): JsonResponse
    {
        $request->validate([
            'notification_ids' => 'required|array',
            'notification_ids.*' => 'integer|exists:notification_mirrors,id'
        ]);

        NotificationMirror::whereIn('id', $request->notification_ids)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notifications marked as read'
        ]);
    }
}
