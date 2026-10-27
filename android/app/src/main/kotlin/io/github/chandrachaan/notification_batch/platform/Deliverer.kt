package io.github.chandrachaan.notification_batch.platform

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Icon
import io.github.chandrachaan.notification_batch.MainActivity
import io.github.chandrachaan.notification_batch.R
import io.github.chandrachaan.notification_batch.core.HeldItem

/**
 * Shows a batch as one notification group: a summary that alerts once, and one silent child per
 * held item so each can be tapped on its own.
 */
class Deliverer(private val context: Context) {
    private val manager = context.getSystemService(NotificationManager::class.java)

    fun post(items: List<HeldItem>, contentIntent: (HeldItem) -> PendingIntent) {
        ensureChannel()
        // Android keeps at most 50 notifications per app, so the oldest items wait in the app.
        val shown = items.take(MAX_CHILDREN)
        manager.cancelAll()
        shown.forEachIndexed { index, item ->
            manager.notify(CHILD_ID_BASE + index, child(item, contentIntent(item)))
        }
        manager.notify(SUMMARY_ID, summary(items))
    }

    /** Ids of held items from an earlier batch that the user has not opened or dismissed yet. */
    fun itemIdsStillShowing(): List<String> =
        manager.activeNotifications.mapNotNull { it.notification.extras.getString(EXTRA_ITEM_ID) }

    private fun child(item: HeldItem, contentIntent: PendingIntent): Notification {
        val builder =
            Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_batch)
                .setContentTitle(item.title.ifBlank { item.appLabel })
                .setContentText(item.text)
                .setStyle(Notification.BigTextStyle().bigText(item.text))
                .setSubText(item.appLabel)
                .setWhen(item.postedAt)
                .setShowWhen(true)
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setGroup(GROUP)
                .setGroupAlertBehavior(Notification.GROUP_ALERT_SUMMARY)
                .setOnlyAlertOnce(true)
                .addExtras(android.os.Bundle().apply { putString(EXTRA_ITEM_ID, item.id) })
        appIcon(item.packageName)?.let { builder.setLargeIcon(Icon.createWithBitmap(it)) }
        return builder.build()
    }

    private fun summary(items: List<HeldItem>): Notification {
        val res = context.resources
        val apps = items.map { it.appLabel }.distinct()
        val title = res.getQuantityString(R.plurals.batch_summary_title, items.size, items.size)
        val text = apps.joinToString(", ")
        val style = Notification.InboxStyle().setBigContentTitle(title)
        items.take(SUMMARY_LINES).forEach { style.addLine("${it.appLabel} · ${it.title.ifBlank { it.text }}") }
        if (items.size > SUMMARY_LINES) {
            val more = items.size - SUMMARY_LINES
            style.setSummaryText(res.getQuantityString(R.plurals.batch_summary_more, more, more))
        }
        val open =
            PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        return Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_batch)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(style)
            .setNumber(items.size)
            .setContentIntent(open)
            .setAutoCancel(true)
            .setGroup(GROUP)
            .setGroupSummary(true)
            .setGroupAlertBehavior(Notification.GROUP_ALERT_SUMMARY)
            .build()
    }

    private fun appIcon(packageName: String): Bitmap? =
        try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val size = context.resources.getDimensionPixelSize(android.R.dimen.notification_large_icon_width)
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also { bitmap ->
                drawable.setBounds(0, 0, size, size)
                drawable.draw(Canvas(bitmap))
            }
        } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
            null
        }

    private fun ensureChannel() {
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.channel_batches_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = context.getString(R.string.channel_batches_description) }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "batches"
        private const val GROUP = "io.github.chandrachaan.notification_batch.BATCH"
        private const val EXTRA_ITEM_ID = "io.github.chandrachaan.notification_batch.ITEM_ID"
        private const val SUMMARY_ID = 1
        private const val CHILD_ID_BASE = 100
        private const val MAX_CHILDREN = 24
        private const val SUMMARY_LINES = 6
    }
}
