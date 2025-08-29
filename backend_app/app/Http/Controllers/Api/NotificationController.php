<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NotificationMirror;
use App\Models\AppSettings;
use App\Models\FamilyMember;
use App\Models\Alert;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Events\NotificationReceived;

class NotificationController extends Controller
{
    public function send(Request $request): JsonResponse
    {
        $request->validate([
            'app_package' => 'required|string',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'priority' => 'required|integer|between:1,5',
            'category' => 'nullable|string',
        ]);

        // Get app settings for content filtering
        $familyMember = FamilyMember::where('user_id', $request->user()->id)->first();

        if ($familyMember) {
            $settings = AppSettings::where('family_id', $familyMember->family_id)
                ->where('child_user_id', $request->user()->id)
                ->first();

            // Check if this app should be monitored
            if ($settings && isset($settings->notification_filters[$request->app_package])) {
                if (!$settings->notification_filters[$request->app_package]) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Notification filtered - app not monitored'
                    ]);
                }
            }

            // Check for blocked keywords
            if ($settings && !empty($settings->blocked_keywords)) {
                $content = strtolower($request->title . ' ' . $request->content);
                foreach ($settings->blocked_keywords as $keyword) {
                    if (strpos($content, strtolower($keyword)) !== false) {
                        // Trigger content alert
                        Alert::create([
                            'child_user_id' => $request->user()->id,
                            'type' => 'content',
                            'priority' => 'high',
                            'title' => 'Blocked Content Detected',
                            'message' => "Detected blocked keyword: {$keyword}",
                            'data' => [
                                'app_package' => $request->app_package,
                                'keyword' => $keyword,
                                'title' => $request->title,
                                'content_preview' => substr($request->content, 0, 100)
                            ],
                            'triggered_at' => now()
                        ]);
                        break;
                    }
                }
            }
        }

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

    public function batchSend(Request $request): JsonResponse
    {
        $request->validate([
            'notifications' => 'required|array|max:50',
            'notifications.*.app_package' => 'required|string',
            'notifications.*.title' => 'required|string|max:255',
            'notifications.*.content' => 'required|string',
            'notifications.*.priority' => 'required|integer|between:1,5',
            'notifications.*.category' => 'nullable|string',
            'notifications.*.timestamp' => 'required|date',
        ]);

        $createdNotifications = [];

        foreach ($request->notifications as $notifData) {
            $notification = NotificationMirror::create([
                'child_user_id' => $request->user()->id,
                'app_package' => $notifData['app_package'],
                'title' => $notifData['title'],
                'content' => $notifData['content'],
                'priority' => $notifData['priority'],
                'category' => $notifData['category'] ?? null,
                'timestamp' => $notifData['timestamp'],
            ]);

            $createdNotifications[] = $notification;

            // Broadcast each notification
            broadcast(new NotificationReceived($notification));
        }

        return response()->json([
            'success' => true,
            'message' => 'Batch notifications sent successfully',
            'count' => count($createdNotifications)
        ]);
    }
}
