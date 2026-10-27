package io.github.chandrachaan.notification_batch.core

import org.json.JSONArray
import org.json.JSONObject

/** What the user chose in the app. The Flutter UI writes it; the listener reads it. */
data class BatchSettings(
    val batchedPackages: Set<String> = emptySet(),
    val deliveryMinutes: List<Int> = DEFAULT_DELIVERY_MINUTES,
    val paused: Boolean = false,
    val urgentWords: List<String> = emptyList(),
    val letStarredContactsThrough: Boolean = false,
    val setupDone: Boolean = false,
) {
    fun toJson(): JSONObject =
        JSONObject()
            .put("version", 1)
            .put("batchedPackages", JSONArray(batchedPackages.sorted()))
            .put("deliveryMinutes", JSONArray(deliveryMinutes))
            .put("paused", paused)
            .put("urgentWords", JSONArray(urgentWords))
            .put("letStarredContactsThrough", letStarredContactsThrough)
            .put("setupDone", setupDone)

    companion object {
        /** 09:00, 13:00 and 19:00. */
        val DEFAULT_DELIVERY_MINUTES = listOf(9 * 60, 13 * 60, 19 * 60)

        const val MINUTES_PER_DAY = 24 * 60

        /**
         * Sorted, unique and inside one day. Falls back to the defaults when nothing valid is left,
         * because a batch with no delivery time would never arrive.
         */
        fun normalizeMinutes(minutes: Iterable<Int>): List<Int> {
            val valid = minutes.filter { it in 0 until MINUTES_PER_DAY }.distinct().sorted()
            return valid.ifEmpty { DEFAULT_DELIVERY_MINUTES }
        }

        fun normalizeWords(words: Iterable<String>): List<String> =
            words.map { it.trim() }.filter { it.isNotEmpty() }.distinctBy { it.lowercase() }

        fun fromJson(json: JSONObject): BatchSettings =
            BatchSettings(
                batchedPackages = json.optJSONArray("batchedPackages").strings().toSet(),
                deliveryMinutes = normalizeMinutes(json.optJSONArray("deliveryMinutes").ints()),
                paused = json.optBoolean("paused", false),
                urgentWords = normalizeWords(json.optJSONArray("urgentWords").strings()),
                letStarredContactsThrough = json.optBoolean("letStarredContactsThrough", false),
                setupDone = json.optBoolean("setupDone", false),
            )

        private fun JSONArray?.strings(): List<String> =
            if (this == null) emptyList() else (0 until length()).mapNotNull { optString(it, null) }

        private fun JSONArray?.ints(): List<Int> =
            if (this == null) {
                emptyList()
            } else {
                (0 until length()).mapNotNull { index -> (opt(index) as? Number)?.toInt() }
            }
    }
}
