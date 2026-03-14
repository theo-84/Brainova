package com.example.brainova

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class UsageStatsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "brainova/usage_stats")
        channel?.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context
        if (ctx == null) {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        when (call.method) {
            "checkPermission" -> {
                result.success(hasUsagePermission(ctx))
            }
            "openUsageSettings" -> {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                ctx.startActivity(intent)
                result.success(true)
            }
            "queryUsageStats" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: 0L
                val usageStats = queryAndAggregateUsageStats(ctx, startTime, endTime)
                result.success(usageStats)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun queryAndAggregateUsageStats(ctx: Context, startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsManager = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // Query starting from 24 hours before startTime to catch apps already 
        // in the foreground at the boundary (midnight).
        val queryStart = startTime - (24L * 60 * 60 * 1000)
        val events = usageStatsManager.queryEvents(queryStart, endTime)
        val event = android.app.usage.UsageEvents.Event()

        val foregroundStart = mutableMapOf<String, Long>()
        val totalTime = mutableMapOf<String, Long>()
        val lastUsedMap = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName
            val ts = event.timeStamp

            when (event.eventType) {
                // MOVE_TO_FOREGROUND (1)
                android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    // Record when this app came to the foreground
                    foregroundStart[pkg] = ts
                }
                // MOVE_TO_BACKGROUND (2)
                android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val startTs = foregroundStart.remove(pkg)
                    if (startTs != null) {
                        // Clamp the interval to our [startTime, endTime] window
                        val effectiveStart = maxOf(startTs, startTime)
                        val effectiveEnd = minOf(ts, endTime)
                        
                        if (effectiveEnd > effectiveStart) {
                            totalTime[pkg] = (totalTime[pkg] ?: 0L) + (effectiveEnd - effectiveStart)
                            lastUsedMap[pkg] = ts
                        }
                    }
                }
            }
        }

        // Handle apps still in foreground at endTime
        for ((pkg, startTs) in foregroundStart) {
            val effectiveStart = maxOf(startTs, startTime)
            val effectiveEnd = endTime
            
            if (effectiveEnd > effectiveStart) {
                totalTime[pkg] = (totalTime[pkg] ?: 0L) + (effectiveEnd - effectiveStart)
                lastUsedMap[pkg] = endTime
            }
        }

        return totalTime
            .filter { (_, v) -> v > 0 }
            .map { (pkg, time) ->
                mapOf(
                    "packageName" to pkg,
                    "totalTimeInForeground" to time,
                    "lastTimeUsed" to (lastUsedMap[pkg] ?: endTime)
                )
            }
    }

    private fun hasUsagePermission(ctx: Context): Boolean {
        val appOps = ctx.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            ctx.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
