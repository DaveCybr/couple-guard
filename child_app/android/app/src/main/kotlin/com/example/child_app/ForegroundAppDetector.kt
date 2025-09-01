package com.satellite.child_app

import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build

object ForegroundAppDetector {
    fun getCurrentApp(context: Context): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getCurrentAppUsageStats(context)
        } else {
            getCurrentAppLegacy(context)
        }
    }

    private fun getCurrentAppUsageStats(context: Context): String? {
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 1000 * 60 // Last minute

            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                beginTime,
                endTime
            )

            if (usageStatsList.isNotEmpty()) {
                val recentApp = usageStatsList.maxByOrNull { it.lastTimeUsed }
                return recentApp?.packageName
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private fun getCurrentAppLegacy(context: Context): String? {
        try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningTasks = activityManager.getRunningTasks(1)
            
            if (runningTasks.isNotEmpty()) {
                return runningTasks[0].topActivity?.packageName
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
