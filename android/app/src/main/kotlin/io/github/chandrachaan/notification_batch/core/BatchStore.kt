package io.github.chandrachaan.notification_batch.core

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.time.Clock
import java.time.Duration

/** A notification that was removed from the shade and is waiting for the next delivery. */
data class HeldItem(
    val id: String,
    /** The StatusBarNotification key. An app that updates a notification reuses it. */
    val key: String,
    val packageName: String,
    val appLabel: String,
    val title: String,
    val text: String,
    val postedAt: Long,
) {
    fun toJson(): JSONObject =
        JSONObject()
            .put("id", id)
            .put("key", key)
            .put("packageName", packageName)
            .put("appLabel", appLabel)
            .put("title", title)
            .put("text", text)
            .put("postedAt", postedAt)

    companion object {
        fun fromJson(json: JSONObject) =
            HeldItem(
                id = json.getString("id"),
                key = json.getString("key"),
                packageName = json.getString("packageName"),
                appLabel = json.optString("appLabel", json.getString("packageName")),
                title = json.optString("title"),
                text = json.optString("text"),
                postedAt = json.getLong("postedAt"),
            )
    }
}

/**
 * Settings and held notifications, kept as two small [JsonFile]s in the app's private storage.
 * Settings live in their own file so a damaged inbox can never reset the user's choices.
 * All methods are thread-safe.
 */
class BatchStore(private val dir: File, private val clock: Clock = Clock.systemUTC()) {
    private val lock = Any()
    private val settingsFile = JsonFile(File(dir, "settings.json"))
    private val inboxFile = JsonFile(File(dir, "inbox.json"))

    private var settings: BatchSettings = readSettings()
    private var held: List<HeldItem>
    private var delivered: List<HeldItem>
    private var lastDeliveryAt: Long?

    init {
        val inbox = readInbox()
        held = inbox.held
        delivered = inbox.delivered
        lastDeliveryAt = inbox.lastDeliveryAt
    }

    fun settings(): BatchSettings = synchronized(lock) { settings }

    fun saveSettings(newSettings: BatchSettings) =
        synchronized(lock) {
            settings = newSettings
            settingsFile.write(newSettings.toJson())
        }

    /** Newest first. */
    fun held(): List<HeldItem> = synchronized(lock) { held }

    /** Newest first, only from the last [DELIVERED_KEEP]. */
    fun delivered(): List<HeldItem> = synchronized(lock) { recent(delivered) }

    fun lastDeliveryAt(): Long? = synchronized(lock) { lastDeliveryAt }

    fun find(id: String): HeldItem? = synchronized(lock) { (held + delivered).firstOrNull { it.id == id } }

    /**
     * Keeps [item] for the next delivery. An update to a notification that is already held
     * replaces it, so a chatty progress update does not show up ten times.
     * Returns false if it replaced an existing item.
     */
    fun hold(item: HeldItem): Boolean =
        synchronized(lock) {
            val replaced = held.any { it.key == item.key }
            held = (listOf(item) + held.filterNot { it.key == item.key }).take(MAX_HELD)
            writeInbox()
            !replaced
        }

    /** Moves everything held to the delivered list and returns it, newest first. */
    fun takeHeld(): List<HeldItem> =
        synchronized(lock) {
            val taken = held
            if (taken.isEmpty()) return emptyList()
            held = emptyList()
            delivered = recent(taken + delivered).take(MAX_DELIVERED)
            lastDeliveryAt = clock.millis()
            writeInbox()
            taken
        }

    private fun recent(items: List<HeldItem>): List<HeldItem> {
        val cutoff = clock.millis() - DELIVERED_KEEP.toMillis()
        return items.filter { it.postedAt >= cutoff }
    }

    private fun writeInbox() {
        inboxFile.write(
            JSONObject()
                .put("version", 1)
                .put("held", JSONArray(held.map(HeldItem::toJson)))
                .put("delivered", JSONArray(delivered.map(HeldItem::toJson)))
                .put("lastDeliveryAt", lastDeliveryAt ?: JSONObject.NULL),
        )
    }

    private fun readSettings(): BatchSettings =
        settingsFile.read()?.let(BatchSettings::fromJson) ?: BatchSettings()

    private fun readInbox(): Inbox {
        val json = inboxFile.read() ?: return Inbox()
        return try {
            Inbox(
                held = json.optJSONArray("held").items(),
                delivered = json.optJSONArray("delivered").items(),
                lastDeliveryAt = if (json.isNull("lastDeliveryAt")) null else json.optLong("lastDeliveryAt"),
            )
        } catch (e: JSONException) {
            inboxFile.setAside(e)
            Inbox()
        }
    }

    private fun JSONArray?.items(): List<HeldItem> =
        if (this == null) emptyList() else (0 until length()).map { HeldItem.fromJson(getJSONObject(it)) }

    private data class Inbox(
        val held: List<HeldItem> = emptyList(),
        val delivered: List<HeldItem> = emptyList(),
        val lastDeliveryAt: Long? = null,
    )

    companion object {
        /** A runaway app should not fill the phone. The oldest items go first. */
        const val MAX_HELD = 500
        const val MAX_DELIVERED = 300
        val DELIVERED_KEEP: Duration = Duration.ofHours(48)
    }
}
