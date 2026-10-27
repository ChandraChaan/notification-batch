package io.github.chandrachaan.notification_batch.platform

import android.app.PendingIntent

/**
 * The original tap actions of held notifications. A PendingIntent cannot be written to disk, so
 * these only live as long as the process; after a restart a held item opens its app instead.
 */
class LiveIntents(private val capacity: Int = 600) {
    private val intents =
        object : LinkedHashMap<String, PendingIntent>(64, 0.75f, true) {
            override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, PendingIntent>) =
                size > capacity
        }

    @Synchronized
    fun put(id: String, intent: PendingIntent) {
        intents[id] = intent
    }

    @Synchronized
    fun get(id: String): PendingIntent? = intents[id]
}
