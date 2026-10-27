package io.github.chandrachaan.notification_batch.core

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.file.Files
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

class BatchStoreTest {
    private lateinit var dir: File
    private val now = Instant.parse("2026-10-27T08:00:00Z")
    private val clock = Clock.fixed(now, ZoneOffset.UTC)

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("batch-store").toFile()
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    private fun item(key: String, minutesAgo: Long = 0, title: String = "Title $key") =
        HeldItem(
            id = "${now.toEpochMilli() - minutesAgo * 60_000}:$key",
            key = key,
            packageName = "com.example.shop",
            appLabel = "Shop",
            title = title,
            text = "Text for $key",
            postedAt = now.toEpochMilli() - minutesAgo * 60_000,
        )

    @Test
    fun `starts empty with default settings`() {
        val store = BatchStore(dir, clock)
        assertEquals(BatchSettings(), store.settings())
        assertTrue(store.held().isEmpty())
        assertNull(store.lastDeliveryAt())
    }

    @Test
    fun `settings survive a restart`() {
        val settings = BatchSettings(batchedPackages = setOf("a", "b"), deliveryMinutes = listOf(600), paused = true)
        BatchStore(dir, clock).saveSettings(settings)
        assertEquals(settings, BatchStore(dir, clock).settings())
    }

    @Test
    fun `held items survive a restart, newest first`() {
        val store = BatchStore(dir, clock)
        store.hold(item("a", minutesAgo = 10))
        store.hold(item("b", minutesAgo = 5))
        assertEquals(listOf("b", "a"), BatchStore(dir, clock).held().map { it.key })
    }

    @Test
    fun `an update to a held notification replaces it`() {
        val store = BatchStore(dir, clock)
        assertTrue(store.hold(item("a", minutesAgo = 10, title = "1 item in your cart")))
        assertFalse(store.hold(item("a", minutesAgo = 1, title = "2 items in your cart")))
        assertEquals(listOf("2 items in your cart"), store.held().map { it.title })
    }

    @Test
    fun `taking held items moves them to delivered`() {
        val store = BatchStore(dir, clock)
        store.hold(item("a"))
        store.hold(item("b"))
        val taken = store.takeHeld()
        assertEquals(listOf("b", "a"), taken.map { it.key })
        assertTrue(store.held().isEmpty())
        assertEquals(listOf("b", "a"), store.delivered().map { it.key })
        assertEquals(now.toEpochMilli(), store.lastDeliveryAt())
        assertEquals("a", store.find(taken.last().id)?.key)
    }

    @Test
    fun `taking from an empty inbox changes nothing`() {
        val store = BatchStore(dir, clock)
        assertTrue(store.takeHeld().isEmpty())
        assertNull(store.lastDeliveryAt())
    }

    @Test
    fun `delivered items older than two days are dropped`() {
        val store = BatchStore(dir, clock)
        store.hold(item("old", minutesAgo = 49 * 60))
        store.hold(item("new", minutesAgo = 60))
        store.takeHeld()
        assertEquals(listOf("new"), store.delivered().map { it.key })
    }

    @Test
    fun `the inbox has a size limit and drops the oldest`() {
        val store = BatchStore(dir, clock)
        repeat(BatchStore.MAX_HELD + 5) { store.hold(item("k$it", minutesAgo = (BatchStore.MAX_HELD + 5 - it).toLong())) }
        assertEquals(BatchStore.MAX_HELD, store.held().size)
        assertEquals("k${BatchStore.MAX_HELD + 4}", store.held().first().key)
        assertNull(store.held().firstOrNull { it.key == "k0" })
    }

    @Test
    fun `a damaged inbox is set aside without losing the settings`() {
        val settings = BatchSettings(batchedPackages = setOf("com.example.shop"))
        BatchStore(dir, clock).apply {
            saveSettings(settings)
            hold(item("a"))
        }
        File(dir, "inbox.json").writeText("{ not json")
        val store = BatchStore(dir, clock)
        assertTrue(store.held().isEmpty())
        assertEquals(settings, store.settings())
        assertTrue(File(dir, "inbox.json.damaged").exists())
    }

    @Test
    fun `no temporary files are left behind`() {
        val store = BatchStore(dir, clock)
        store.hold(item("a"))
        store.saveSettings(BatchSettings())
        assertEquals(setOf("inbox.json", "settings.json"), dir.list()!!.toSet())
    }
}
