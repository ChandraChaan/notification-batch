package io.github.chandrachaan.notification_batch.platform

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.provider.Telephony
import android.telecom.TelecomManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.chandrachaan.notification_batch.core.BatchSettings
import io.github.chandrachaan.notification_batch.core.HeldItem
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/**
 * The one place the Flutter UI talks to Android. Mirrors `lib/core/platform/batch_platform.dart`.
 * Slow work runs on the runtime's thread; results always go back on the main thread.
 */
class PlatformBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val runtime = BatchRuntime.get(activity)
    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(messenger, "notification_batch/platform")
    private val changes = EventChannel(messenger, "notification_batch/changes")
    private var pendingPermission: MethodChannel.Result? = null

    init {
        // Opening the app is a good moment to catch up on a batch whose alarm was missed.
        runtime.executor.execute(runtime::deliverIfOverdue)
        methods.setMethodCallHandler(this)
        changes.setStreamHandler(
            object : EventChannel.StreamHandler {
                private var listener: (() -> Unit)? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val forward = { main.post { events.success("changed") }; Unit }
                    listener = forward
                    runtime.addChangeListener(forward)
                }

                override fun onCancel(arguments: Any?) {
                    listener?.let(runtime::removeChangeListener)
                    listener = null
                }
            },
        )
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        changes.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> background(result) { status() }
            "getSettings" -> background(result) { runtime.store.settings().toJson().toString() }
            "saveSettings" -> {
                val json = call.arguments as? String ?: return result.error("bad_args", "Expected JSON", null)
                background(result) { runtime.saveSettings(BatchSettings.fromJson(JSONObject(json))) }
            }
            "getHeld" -> background(result) { runtime.store.held().map(::itemMap) }
            "getDelivered" -> background(result) { runtime.store.delivered().map(::itemMap) }
            "deliverNow" -> background(result) { runtime.deliver() }
            "openItem" -> {
                val id = call.arguments as? String ?: return result.error("bad_args", "Expected an id", null)
                background(result) { runtime.open(id) }
            }
            "getInstalledApps" -> background(result) { installedApps() }
            "getAppIcon" -> {
                val pkg = call.arguments as? String ?: return result.error("bad_args", "Expected a package", null)
                background(result) { appIcon(pkg) }
            }
            "openListenerSettings" -> result.success(openListenerSettings())
            "openAppDetails" ->
                result.success(
                    start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))),
                )
            "openExactAlarmSettings" ->
                result.success(
                    Build.VERSION.SDK_INT >= 31 &&
                        start(
                            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${activity.packageName}")),
                        ),
                )
            "requestPostNotifications" -> requestPermission("android.permission.POST_NOTIFICATIONS", result)
            "requestContacts" -> requestPermission(Manifest.permission.READ_CONTACTS, result)
            else -> result.notImplemented()
        }
    }

    /** Forwarded by the activity. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        pendingPermission?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        pendingPermission = null
    }

    private fun requestPermission(permission: String, result: MethodChannel.Result) {
        val notNeeded = permission == "android.permission.POST_NOTIFICATIONS" && Build.VERSION.SDK_INT < 33
        if (notNeeded || activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        activity.requestPermissions(arrayOf(permission), PERMISSION_REQUEST)
    }

    private fun status(): Map<String, Any?> {
        val notificationsAllowed =
            activity.getSystemService(android.app.NotificationManager::class.java).areNotificationsEnabled()
        return mapOf(
            "listenerEnabled" to runtime.isListenerEnabled(),
            "listenerConnected" to runtime.isListenerConnected,
            "notificationsAllowed" to notificationsAllowed,
            "contactsAllowed" to
                (activity.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED),
            "exactAlarmsAllowed" to DeliveryScheduler.canUseExactAlarms(activity),
            "nextDeliveryAt" to runtime.nextDeliveryAt(),
            "heldCount" to runtime.store.held().size,
            "lastDeliveryAt" to runtime.store.lastDeliveryAt(),
        )
    }

    private fun itemMap(item: HeldItem): Map<String, Any> =
        mapOf(
            "id" to item.id,
            "packageName" to item.packageName,
            "appLabel" to item.appLabel,
            "title" to item.title,
            "text" to item.text,
            "postedAt" to item.postedAt,
        )

    private fun installedApps(): List<Map<String, Any>> {
        val pm = activity.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val sms = Telephony.Sms.getDefaultSmsPackage(activity)
        val dialer = activity.getSystemService(TelecomManager::class.java)?.defaultDialerPackage
        return pm.queryIntentActivities(launcher, 0)
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != activity.packageName }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "label" to pm.getApplicationLabel(info).toString(),
                    "category" to info.category,
                    "isSystem" to (info.flags and ApplicationInfo.FLAG_SYSTEM != 0),
                    "isDefaultSms" to (info.packageName == sms),
                    "isDefaultDialer" to (info.packageName == dialer),
                )
            }
    }

    private fun appIcon(packageName: String): ByteArray? =
        try {
            val drawable = activity.packageManager.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, ICON_PX, ICON_PX)
            drawable.draw(Canvas(bitmap))
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                out.toByteArray()
            }
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }

    private fun openListenerSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= 30) {
            val detail =
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    ComponentName(activity, BatchListenerService::class.java).flattenToString(),
                )
            if (start(detail)) return true
        }
        return start(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun start(intent: Intent): Boolean =
        try {
            activity.startActivity(intent)
            true
        } catch (e: android.content.ActivityNotFoundException) {
            false
        }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        runtime.executor.execute {
            try {
                val value = work().takeUnless { it == Unit }
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.javaClass.simpleName, e.message) }
            }
        }
    }

    private companion object {
        const val PERMISSION_REQUEST = 4021
        const val ICON_PX = 96
    }
}
