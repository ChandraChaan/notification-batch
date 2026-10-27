package io.github.chandrachaan.notification_batch.platform

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/** Android hands every posted notification to this service once the user grants notification access. */
class BatchListenerService : NotificationListenerService() {
    private val runtime by lazy { BatchRuntime.get(this) }

    override fun onListenerConnected() {
        runtime.onListenerConnected(this)
    }

    override fun onListenerDisconnected() {
        runtime.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn != null) runtime.onPosted(this, sbn)
    }
}
