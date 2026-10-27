package io.github.chandrachaan.notification_batch.platform

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.github.chandrachaan.notification_batch.core.DeliverySchedule
import java.time.Instant
import java.time.ZoneId

/** One alarm for the next delivery time. Each delivery schedules the one after it. */
object DeliveryScheduler {
    private const val ACTION_DELIVER = "io.github.chandrachaan.notification_batch.DELIVER"

    /** Without exact alarms Android may run the alarm up to this much later. */
    private const val WINDOW_MILLIS = 10 * 60 * 1000L

    fun schedule(context: Context, deliveryMinutes: List<Int>): Long? {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val intent = pendingIntent(context)
        val next = DeliverySchedule.nextAfter(Instant.now(), deliveryMinutes, ZoneId.systemDefault())
        if (next == null) {
            alarms.cancel(intent)
            return null
        }
        val at = next.toEpochMilli()
        try {
            if (canUseExactAlarms(context)) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
            } else {
                alarms.setWindow(AlarmManager.RTC_WAKEUP, at, WINDOW_MILLIS, intent)
            }
        } catch (e: SecurityException) {
            Log.w("NotificationBatch", "Exact alarm refused, using a window", e)
            alarms.setWindow(AlarmManager.RTC_WAKEUP, at, WINDOW_MILLIS, intent)
        }
        return at
    }

    fun canUseExactAlarms(context: Context): Boolean =
        Build.VERSION.SDK_INT < 31 || context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    private fun pendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, DeliveryReceiver::class.java).setAction(ACTION_DELIVER),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
}

/** Fires at a delivery time. */
class DeliveryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        val runtime = BatchRuntime.get(context)
        runtime.executor.execute {
            try {
                runtime.deliver()
            } finally {
                pending.finish()
            }
        }
    }
}

/** Boot, app update, clock or time zone change: the next alarm has to be set again. */
class SystemEventsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        val runtime = BatchRuntime.get(context)
        runtime.executor.execute {
            try {
                runtime.reschedule()
                runtime.deliverIfOverdue()
            } finally {
                pending.finish()
            }
        }
    }
}
