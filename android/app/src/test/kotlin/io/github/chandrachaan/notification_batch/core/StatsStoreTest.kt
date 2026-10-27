package io.github.chandrachaan.notification_batch.core

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.file.Files
import java.time.LocalDate

class StatsStoreTest {
    private lateinit var dir: File
    private val today = LocalDate.parse("2026-10-28")

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("stats-store").toFile()
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    @Test
    fun `counts held notifications per app and day`() {
        val stats = StatsStore(dir)
        stats.recordHeld(today, "com.example.shop", "Shop")
        stats.recordHeld(today, "com.example.shop", "Shop")
        stats.recordHeld(today, "com.example.game", "Game")
        stats.recordHeld(today.minusDays(1), "com.example.shop", "Shop")
        val days = stats.days()
        assertEquals(listOf(today.minusDays(1), today), days.map { it.date })
        assertEquals(mapOf("com.example.shop" to 2, "com.example.game" to 1), days.last().held)
        assertEquals(mapOf("com.example.shop" to "Shop", "com.example.game" to "Game"), stats.labels())
    }

    @Test
    fun `counts what was let through by reason`() {
        val stats = StatsStore(dir)
        stats.recordLetThrough(today, LetThroughReason.VERIFICATION_CODE)
        stats.recordLetThrough(today, LetThroughReason.VERIFICATION_CODE)
        stats.recordLetThrough(today, LetThroughReason.URGENT_WORD)
        assertEquals(
            mapOf(LetThroughReason.VERIFICATION_CODE to 2, LetThroughReason.URGENT_WORD to 1),
            stats.days().single().letThrough,
        )
    }

    @Test
    fun `survives a restart`() {
        StatsStore(dir).apply {
            recordHeld(today, "com.example.shop", "Shop")
            recordLetThrough(today, LetThroughReason.CALL)
        }
        val reloaded = StatsStore(dir)
        assertEquals(mapOf("com.example.shop" to 1), reloaded.days().single().held)
        assertEquals(mapOf(LetThroughReason.CALL to 1), reloaded.days().single().letThrough)
        assertEquals("Shop", reloaded.labels()["com.example.shop"])
    }

    @Test
    fun `keeps five weeks and forgets apps that no longer appear`() {
        val stats = StatsStore(dir)
        stats.recordHeld(today.minusDays(StatsStore.KEEP_DAYS), "com.example.old", "Old")
        stats.recordHeld(today.minusDays(StatsStore.KEEP_DAYS - 1), "com.example.shop", "Shop")
        stats.recordHeld(today, "com.example.shop", "Shop")
        assertEquals(listOf(today.minusDays(StatsStore.KEEP_DAYS - 1), today), stats.days().map { it.date })
        assertEquals(setOf("com.example.shop"), stats.labels().keys)
    }

    @Test
    fun `a damaged file starts fresh and is kept aside`() {
        File(dir, "stats.json").writeText("""{"days":[{"date":"not a date"}]}""")
        val stats = StatsStore(dir)
        assertTrue(stats.days().isEmpty())
        assertTrue(File(dir, "stats.json.damaged").exists())
        stats.recordHeld(today, "com.example.shop", "Shop")
        assertEquals(1, StatsStore(dir).days().size)
    }

    @Test
    fun `unknown reasons from a newer version are skipped`() {
        File(dir, "stats.json").writeText(
            """{"days":[{"date":"2026-10-28","held":{},"letThrough":{"CALL":2,"SOMETHING_NEW":5}}],"labels":{}}""",
        )
        assertEquals(mapOf(LetThroughReason.CALL to 2), StatsStore(dir).days().single().letThrough)
    }
}
