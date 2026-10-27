package io.github.chandrachaan.notification_batch.core

import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Turns "deliver at 09:00, 13:00 and 19:00" into instants in the phone's time zone.
 *
 * A time that does not exist on a given day (it falls in a daylight-saving gap) moves forward by
 * the length of the gap, as java.time does. A time that happens twice uses the first occurrence.
 */
object DeliverySchedule {
    /** The first delivery strictly after [instant], or null when there are no delivery times. */
    fun nextAfter(instant: Instant, minutes: List<Int>, zone: ZoneId): Instant? {
        val slots = slots(minutes) ?: return null
        val today = instant.atZone(zone).toLocalDate()
        for (dayOffset in 0L..2L) {
            val date = today.plusDays(dayOffset)
            for (minute in slots) {
                val candidate = slotInstant(date, minute, zone)
                if (candidate.isAfter(instant)) return candidate
            }
        }
        return null
    }

    /** The latest delivery at or before [instant], or null when there are no delivery times. */
    fun latestAtOrBefore(instant: Instant, minutes: List<Int>, zone: ZoneId): Instant? {
        val slots = slots(minutes)?.reversed() ?: return null
        val today = instant.atZone(zone).toLocalDate()
        for (dayOffset in 0L..2L) {
            val date = today.minusDays(dayOffset)
            for (minute in slots) {
                val candidate = slotInstant(date, minute, zone)
                if (!candidate.isAfter(instant)) return candidate
            }
        }
        return null
    }

    /**
     * True when a delivery time has passed since [oldestHeld] was held: the alarm was missed
     * (phone off, process killed, alarm deferred) and the batch is late.
     */
    fun isOverdue(oldestHeld: Instant, now: Instant, minutes: List<Int>, zone: ZoneId): Boolean {
        val latest = latestAtOrBefore(now, minutes, zone) ?: return false
        return latest.isAfter(oldestHeld)
    }

    private fun slots(minutes: List<Int>): List<Int>? =
        minutes.filter { it in 0 until BatchSettings.MINUTES_PER_DAY }.distinct().sorted().ifEmpty { null }

    private fun slotInstant(date: LocalDate, minute: Int, zone: ZoneId): Instant =
        ZonedDateTime.of(date, LocalTime.of(minute / 60, minute % 60), zone).toInstant()
}
