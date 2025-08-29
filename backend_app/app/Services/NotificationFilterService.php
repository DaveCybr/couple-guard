<?php

namespace App\Services;

use App\Models\AppSettings;
use App\Models\FamilyMember;
use App\Models\Alert;

class NotificationFilterService
{
    public function shouldFilterNotification($childId, $appPackage, $content)
    {
        $familyMember = FamilyMember::where('user_id', $childId)->first();
        if (!$familyMember) return false;

        $settings = AppSettings::where('family_id', $familyMember->family_id)
            ->where('child_user_id', $childId)
            ->first();

        if (!$settings) return false;

        // Check app filters
        if (isset($settings->notification_filters[$appPackage])) {
            return !$settings->notification_filters[$appPackage];
        }

        return false;
    }

    public function checkBlockedContent($childId, $title, $content)
    {
        $familyMember = FamilyMember::where('user_id', $childId)->first();
        if (!$familyMember) return null;

        $settings = AppSettings::where('family_id', $familyMember->family_id)
            ->where('child_user_id', $childId)
            ->first();

        if (!$settings || empty($settings->blocked_keywords)) return null;

        $fullContent = strtolower($title . ' ' . $content);

        foreach ($settings->blocked_keywords as $keyword) {
            if (strpos($fullContent, strtolower($keyword)) !== false) {
                return $keyword;
            }
        }

        return null;
    }

    public function triggerContentAlert($childId, $appPackage, $keyword, $title, $content)
    {
        Alert::create([
            'child_user_id' => $childId,
            'type' => 'content',
            'priority' => 'high',
            'title' => 'Blocked Content Detected',
            'message' => "Detected blocked keyword: {$keyword}",
            'data' => [
                'app_package' => $appPackage,
                'keyword' => $keyword,
                'title' => $title,
                'content_preview' => substr($content, 0, 100),
                'detected_at' => now()->toISOString()
            ],
            'triggered_at' => now()
        ]);
    }
}
