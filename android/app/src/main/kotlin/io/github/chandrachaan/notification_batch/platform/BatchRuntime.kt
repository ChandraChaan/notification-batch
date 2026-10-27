package io.github.chandrachaan.notification_batch.platform

import android.app.ActivityOptions
import android.app.Notification
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.github.chandrachaan.notification_batch.core.BatchPolicy
import io.github.chandrachaan.notification_batch.core.BatchSettings
import io.github.chandrachaan.notification_batch.core.BatchStore
import io.github.chandrachaan.notification_batch.core.Decision
import io.github.chandrachaan.notification_batch.core.DeliverySchedule
import io.github.chandrachaan.notification_batch.core.HeldItem
import java.io.File
import java.lang.ref.WeakReference
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Everything the listener, the alarms and the Flutter UI share. All work that touches the store
 * runs on one background thread, in order.
 */
class BatchRuntime private constructor(context: Context) {
    private val context: Context = context.applicationContext
    val store = BatchStore(File(this.context.filesDir, "batch"))
    val executor: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "notification-batch") }
    private val liveIntents = LiveIntents()
    private val starred = StarredContactsReader(this.context)
    private val deliverer = Deliverer(this.context)
    private val changeListeners = CopyOnWriteArraySet<() -> Unit>()

    @Volatile private var service: WeakReference<NotificationListenerService>? = null

    val isListenerConnected: Boolean
        get() = service?.get() != null

    fun onListenerConnected(listener: NotificationListenerService) {
        service = WeakReference(listener)
        executor.execute {
            reschedule()
            deliverIfOverdue()
            notifyChanged()
        }
    }

    fun onListenerDisconnected() {
        service = null
        notifyChanged()
    }

    fun onPosted(listener: NotificationListenerService, sbn: StatusBarNotification) =
        executor.execute {
            try {
                handlePosted(listener, sbn)
            } catch (e: RuntimeException) {
                // Never let one odd notification take the listener down. It stays in the shade.
                Log.w(TAG, "Could not handle a notification from ${sbn.packageName}", e)
            }
            deliverIfOverdue()
        }

    private fun handlePosted(listener: NotificationListenerService, sbn: StatusBarNotification) {
        val settings = store.settings()
        // Fast path: most notifications come from apps that are not batched.
        if (settings.paused || sbn.packageName !in settings.batchedPackages) return

        val facts =
            FactsReader.read(sbn) { senders ->
                settings.letStarredContactsThrough && starred.isStarred(senders)
            }
        when (BatchPolicy.decide(facts, settings, context.packageName)) {
            Decision.NotBatched, is Decision.LetThrough -> Unit
            Decision.Hold -> {
                val item =
                    HeldItem(
                        id = "${sbn.postTime}:${sbn.key}",
                        key = sbn.key,
                        packageName = sbn.packageName,
                        appLabel = appLabel(sbn.packageName),
                        title = facts.title,
                        text = facts.text,
                        postedAt = sbn.postTime,
                    )
                // Store first, remove second: a crash in between leaves a duplicate, never a loss.
                store.hold(item)
                sbn.notification.contentIntent?.let { liveIntents.put(item.id, it) }
                listener.cancelNotification(sbn.key)
                removeEmptySummary(listener, sbn)
                notifyChanged()
            }
            Decision.HoldSummary -> {
                if (!hasVisibleChildren(listener, sbn, exceptKey = sbn.key)) {
                    listener.cancelNotification(sbn.key)
                }
            }
        }
    }

    /** After a child is held, its group summary would sit in the shade with nothing under it. */
    private fun removeEmptySummary(listener: NotificationListenerService, child: StatusBarNotification) {
        val active = listener.activeNotifications ?: return
        val summary = active.firstOrNull { it.groupKey == child.groupKey && it.isSummary() } ?: return
        if (summary.isOngoing || hasVisibleChildren(listener, summary, exceptKey = child.key)) return
        val facts = FactsReader.read(summary) { false }
        if (BatchPolicy.decide(facts, store.settings(), context.packageName) == Decision.HoldSummary) {
            listener.cancelNotification(summary.key)
        }
    }

    private fun hasVisibleChildren(
        listener: NotificationListenerService,
        summary: StatusBarNotification,
        exceptKey: String,
    ): Boolean =
        listener.activeNotifications.orEmpty().any {
            it.groupKey == summary.groupKey && it.key != exceptKey && !it.isSummary()
        }

    private fun StatusBarNotification.isSummary() = notification.flags and Notification.FLAG_GROUP_SUMMARY != 0

    /** Posts everything held as one batch. Call on [executor]. */
    fun deliver() {
        val items = store.takeHeld()
        if (items.isNotEmpty()) {
            val stillShowing = deliverer.itemIdsStillShowing().mapNotNull(store::find)
            val batch = (items + stillShowing).distinctBy { it.id }.sortedByDescending { it.postedAt }
            deliverer.post(batch, ::contentIntentFor)
            notifyChanged()
        }
        reschedule()
    }

    /** Catches up when an alarm was missed: phone off, app updated, alarm deferred by the system. */
    fun deliverIfOverdue() {
        val settings = store.settings()
        val oldest = store.held().minOfOrNull { it.postedAt } ?: return
        val overdue =
            DeliverySchedule.isOverdue(
                oldestHeld = Instant.ofEpochMilli(oldest),
                now = Instant.now(),
                minutes = settings.deliveryMinutes,
                zone = ZoneId.systemDefault(),
            )
        if (overdue) deliver()
    }

    fun reschedule(): Long? = DeliveryScheduler.schedule(context, store.settings().deliveryMinutes)

    fun nextDeliveryAt(): Long? =
        DeliverySchedule.nextAfter(Instant.now(), store.settings().deliveryMinutes, ZoneId.systemDefault())
            ?.toEpochMilli()

    fun saveSettings(settings: BatchSettings) {
        store.saveSettings(settings)
        reschedule()
        notifyChanged()
    }

    /** Opens what a held item pointed at: its own tap action if Android still has it, else its app. */
    fun open(id: String): Boolean {
        val item = store.find(id) ?: return false
        liveIntents.get(id)?.let { intent ->
            try {
                if (Build.VERSION.SDK_INT >= 34) {
                    // The user tapped the item in this app, so lend it our right to open an activity.
                    val options =
                        ActivityOptions.makeBasic().setPendingIntentBackgroundActivityStartMode(allowWhileVisible())
                    intent.send(context, 0, null, null, null, null, options.toBundle())
                } else {
                    intent.send()
                }
                return true
            } catch (e: PendingIntent.CanceledException) {
                Log.i(TAG, "The original tap action is gone, opening the app instead", e)
            }
        }
        val launch = context.packageManager.getLaunchIntentForPackage(item.packageName) ?: return false
        context.startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        return true
    }

    @Suppress("DEPRECATION")
    private fun allowWhileVisible(): Int =
        if (Build.VERSION.SDK_INT >= 36) {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_IF_VISIBLE
        } else {
            ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
        }

    private fun contentIntentFor(item: HeldItem): PendingIntent {
        liveIntents.get(item.id)?.let { return it }
        val launch =
            context.packageManager.getLaunchIntentForPackage(item.packageName)
                ?: Intent(context, io.github.chandrachaan.notification_batch.MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            item.id.hashCode(),
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    fun isListenerEnabled(): Boolean {
        val component = ComponentName(context, BatchListenerService::class.java)
        if (Build.VERSION.SDK_INT >= 27) {
            val manager = context.getSystemService(android.app.NotificationManager::class.java)
            return manager.isNotificationListenerAccessGranted(component)
        }
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        return enabled?.split(':')?.any { ComponentName.unflattenFromString(it) == component } == true
    }

    fun appLabel(packageName: String): String =
        try {
            val info = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(info).toString()
        } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
            packageName
        }

    fun addChangeListener(listener: () -> Unit) = changeListeners.add(listener)

    fun removeChangeListener(listener: () -> Unit) = changeListeners.remove(listener)

    private fun notifyChanged() = changeListeners.forEach { it() }

    companion object {
        private const val TAG = "NotificationBatch"

        @Volatile private var instance: BatchRuntime? = null

        fun get(context: Context): BatchRuntime =
            instance ?: synchronized(this) { instance ?: BatchRuntime(context).also { instance = it } }
    }
}
