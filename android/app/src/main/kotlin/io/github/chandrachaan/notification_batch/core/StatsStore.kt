package io.github.chandrachaan.notification_batch.core

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.time.LocalDate

/** What happened on one day, in the phone's local calendar. */
data class DayStats(
    val date: LocalDate,
    /** Interruptions saved, per app. */
    val held: Map<String, Int> = emptyMap(),
    /** Notifications from batched apps that were let through, per reason. */
    val letThrough: Map<LetThroughReason, Int> = emptyMap(),
) {
    fun toJson(): JSONObject =
        JSONObject()
            .put("date", date.toString())
            .put("held", JSONObject(held))
            .put("letThrough", JSONObject(letThrough.mapKeys { it.key.name }))

    companion object {
        fun fromJson(json: JSONObject) =
            DayStats(
                date = LocalDate.parse(json.getString("date")),
                held = json.optJSONObject("held").counts(),
                letThrough =
                    json.optJSONObject("letThrough").counts().mapNotNull { (name, count) ->
                        LetThroughReason.entries.firstOrNull { it.name == name }?.let { it to count }
                    }.toMap(),
            )

        private fun JSONObject?.counts(): Map<String, Int> =
            if (this == null) emptyMap() else keys().asSequence().associateWith { optInt(it) }
    }
}

/**
 * Daily counts for the stats screen, kept for [KEEP_DAYS] days. Only numbers and app names are
 * stored here, never what a notification said. Thread-safe.
 */
class StatsStore(dir: File) {
    private val lock = Any()
    private val file = JsonFile(File(dir, "stats.json"))
    private var days: Map<LocalDate, DayStats>
    private var labels: Map<String, String>

    init {
        val json = file.read()
        var loadedDays = emptyMap<LocalDate, DayStats>()
        var loadedLabels = emptyMap<String, String>()
        if (json != null) {
            try {
                val array = json.optJSONArray("days") ?: JSONArray()
                loadedDays = (0 until array.length()).map { DayStats.fromJson(array.getJSONObject(it)) }
                    .associateBy { it.date }
                val labelJson = json.optJSONObject("labels")
                loadedLabels = labelJson?.keys()?.asSequence()?.associateWith { labelJson.optString(it) }.orEmpty()
            } catch (e: JSONException) {
                file.setAside(e)
            } catch (e: java.time.format.DateTimeParseException) {
                file.setAside(e)
            }
        }
        days = loadedDays
        labels = loadedLabels
    }

    fun recordHeld(date: LocalDate, packageName: String, appLabel: String) =
        update(date, label = packageName to appLabel) { day ->
            day.copy(held = day.held.plus(packageName to (day.held[packageName] ?: 0) + 1))
        }

    fun recordLetThrough(date: LocalDate, reason: LetThroughReason) =
        update(date) { day -> day.copy(letThrough = day.letThrough.plus(reason to (day.letThrough[reason] ?: 0) + 1)) }

    /** Oldest first. */
    fun days(): List<DayStats> = synchronized(lock) { days.values.sortedBy { it.date } }

    fun labels(): Map<String, String> = synchronized(lock) { labels }

    private fun update(date: LocalDate, label: Pair<String, String>? = null, change: (DayStats) -> DayStats) =
        synchronized(lock) {
            val cutoff = date.minusDays(KEEP_DAYS - 1)
            val changed = change(days[date] ?: DayStats(date))
            days = (days + (date to changed)).filterKeys { !it.isBefore(cutoff) }
            val stillUsed = days.values.flatMap { it.held.keys }.toSet()
            labels = (labels + listOfNotNull(label)).filterKeys { it in stillUsed }
            write()
        }

    private fun write() {
        file.write(
            JSONObject()
                .put("version", 1)
                .put("days", JSONArray(days.values.sortedBy { it.date }.map(DayStats::toJson)))
                .put("labels", JSONObject(labels)),
        )
    }

    companion object {
        const val KEEP_DAYS = 35L
    }
}
