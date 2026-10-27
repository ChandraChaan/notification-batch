package io.github.chandrachaan.notification_batch.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

class DeliveryScheduleTest {
    private val nineOneSeven = listOf(9 * 60, 13 * 60, 19 * 60)
    private val kolkata = ZoneId.of("Asia/Kolkata")
    private val newYork = ZoneId.of("America/New_York")

    private fun at(text: String, zone: ZoneId): Instant = LocalDateTime.parse(text).atZone(zone).toInstant()

    private fun local(instant: Instant?, zone: ZoneId): String? =
        instant?.let { ZonedDateTime.ofInstant(it, zone).toLocalDateTime().toString() }

    @Test
    fun `next delivery later the same day`() {
        val next = DeliverySchedule.nextAfter(at("2026-10-27T10:15", kolkata), nineOneSeven, kolkata)
        assertEquals("2026-10-27T13:00", local(next, kolkata))
    }

    @Test
    fun `exactly at a delivery time, the next one is the following slot`() {
        val next = DeliverySchedule.nextAfter(at("2026-10-27T13:00", kolkata), nineOneSeven, kolkata)
        assertEquals("2026-10-27T19:00", local(next, kolkata))
    }

    @Test
    fun `after the last delivery it rolls over to tomorrow`() {
        val next = DeliverySchedule.nextAfter(at("2026-10-27T21:30", kolkata), nineOneSeven, kolkata)
        assertEquals("2026-10-28T09:00", local(next, kolkata))
    }

    @Test
    fun `rolls over the end of a month and a year`() {
        assertEquals(
            "2026-11-01T09:00",
            local(DeliverySchedule.nextAfter(at("2026-10-31T23:59", kolkata), nineOneSeven, kolkata), kolkata),
        )
        assertEquals(
            "2027-01-01T09:00",
            local(DeliverySchedule.nextAfter(at("2026-12-31T20:00", kolkata), nineOneSeven, kolkata), kolkata),
        )
    }

    @Test
    fun `a midnight delivery counts as the start of the next day`() {
        val next = DeliverySchedule.nextAfter(at("2026-10-27T23:59:59", kolkata), listOf(0), kolkata)
        assertEquals("2026-10-28T00:00", local(next, kolkata))
    }

    @Test
    fun `times are unsorted and duplicated in the input`() {
        val next = DeliverySchedule.nextAfter(at("2026-10-27T08:00", kolkata), listOf(1140, 540, 540, 780), kolkata)
        assertEquals("2026-10-27T09:00", local(next, kolkata))
    }

    @Test
    fun `no delivery times means no next delivery`() {
        assertNull(DeliverySchedule.nextAfter(Instant.EPOCH, emptyList(), kolkata))
        assertNull(DeliverySchedule.nextAfter(Instant.EPOCH, listOf(-1, 1440), kolkata))
    }

    @Test
    fun `the same instant gives a different local delivery in another time zone`() {
        val instant = Instant.parse("2026-10-27T06:00:00Z") // 11:30 in Kolkata, 02:00 in New York
        assertEquals("2026-10-27T13:00", local(DeliverySchedule.nextAfter(instant, nineOneSeven, kolkata), kolkata))
        assertEquals("2026-10-27T09:00", local(DeliverySchedule.nextAfter(instant, nineOneSeven, newYork), newYork))
    }

    @Test
    fun `daylight saving starts - a time in the gap moves forward`() {
        // On 2026-03-08 New York clocks jump from 02:00 to 03:00, so 02:30 does not exist.
        val next = DeliverySchedule.nextAfter(at("2026-03-08T01:00", newYork), listOf(150), newYork)
        assertEquals("2026-03-08T03:30", local(next, newYork))
        assertEquals(Instant.parse("2026-03-08T07:30:00Z"), next)
    }

    @Test
    fun `daylight saving ends - a repeated time is delivered once`() {
        // On 2026-11-01 New York clocks go back from 02:00 to 01:00, so 01:30 happens twice.
        val first = DeliverySchedule.nextAfter(at("2026-11-01T00:00", newYork), listOf(90), newYork)
        assertEquals(Instant.parse("2026-11-01T05:30:00Z"), first)
        val second = DeliverySchedule.nextAfter(first!!, listOf(90), newYork)
        assertEquals("2026-11-02T01:30", local(second, newYork))
    }

    @Test
    fun `delivery times keep their wall clock time across a daylight saving change`() {
        val before = DeliverySchedule.nextAfter(at("2026-10-31T10:00", newYork), nineOneSeven, newYork)!!
        val after = DeliverySchedule.nextAfter(at("2026-11-02T10:00", newYork), nineOneSeven, newYork)!!
        assertEquals("2026-10-31T13:00", local(before, newYork))
        assertEquals("2026-11-02T13:00", local(after, newYork))
        // 13:00 is 17:00 UTC before the change and 18:00 UTC after it.
        assertEquals(Instant.parse("2026-10-31T17:00:00Z"), before)
        assertEquals(Instant.parse("2026-11-02T18:00:00Z"), after)
    }

    @Test
    fun `quarter hour offsets work`() {
        val chatham = ZoneId.of("Pacific/Chatham") // UTC+13:45 in October
        val next = DeliverySchedule.nextAfter(Instant.parse("2026-10-27T00:00:00Z"), nineOneSeven, chatham)
        assertEquals("2026-10-27T19:00", local(next, chatham))
    }

    @Test
    fun `latest delivery at or before now`() {
        val latest = DeliverySchedule.latestAtOrBefore(at("2026-10-27T13:00", kolkata), nineOneSeven, kolkata)
        assertEquals("2026-10-27T13:00", local(latest, kolkata))
        val early = DeliverySchedule.latestAtOrBefore(at("2026-10-27T08:59", kolkata), nineOneSeven, kolkata)
        assertEquals("2026-10-26T19:00", local(early, kolkata))
    }

    @Test
    fun `a batch is overdue once a delivery time has passed since it was held`() {
        val held = at("2026-10-27T12:30", kolkata)
        assertFalse(DeliverySchedule.isOverdue(held, at("2026-10-27T12:59", kolkata), nineOneSeven, kolkata))
        assertTrue(DeliverySchedule.isOverdue(held, at("2026-10-27T13:00", kolkata), nineOneSeven, kolkata))
        assertTrue(DeliverySchedule.isOverdue(held, at("2026-10-29T08:00", kolkata), nineOneSeven, kolkata))
    }

    @Test
    fun `a batch held after midnight is not overdue from yesterday's evening delivery`() {
        val held = at("2026-10-28T00:10", kolkata)
        assertFalse(DeliverySchedule.isOverdue(held, at("2026-10-28T08:00", kolkata), nineOneSeven, kolkata))
    }
}
