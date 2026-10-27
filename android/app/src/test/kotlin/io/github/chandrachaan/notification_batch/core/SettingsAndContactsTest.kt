package io.github.chandrachaan.notification_batch.core

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class SettingsAndContactsTest {
    @Test
    fun `reads the settings file written by the Flutter side`() {
        // spec/settings.json is shared with the Dart tests so both sides agree on the format.
        val json = JSONObject(File("../../spec/settings.json").readText())
        val settings = BatchSettings.fromJson(json)
        assertEquals(setOf("com.example.games", "com.example.shop"), settings.batchedPackages)
        assertEquals(listOf(540, 780, 1140), settings.deliveryMinutes)
        assertEquals(listOf("flight", "delivered"), settings.urgentWords)
        assertTrue(settings.letStarredContactsThrough)
        assertTrue(settings.setupDone)
        assertFalse(settings.paused)
        assertEquals(settings, BatchSettings.fromJson(settings.toJson()))
    }

    @Test
    fun `bad delivery times are cleaned up and never left empty`() {
        val json = JSONObject().put("deliveryMinutes", org.json.JSONArray(listOf(780, 780, -5, 2000, 540)))
        assertEquals(listOf(540, 780), BatchSettings.fromJson(json).deliveryMinutes)
        assertEquals(BatchSettings.DEFAULT_DELIVERY_MINUTES, BatchSettings.fromJson(JSONObject()).deliveryMinutes)
    }

    @Test
    fun `urgent words are trimmed and deduplicated ignoring case`() {
        assertEquals(listOf("Flight", "bank"), BatchSettings.normalizeWords(listOf(" Flight ", "flight", "", "bank")))
    }

    @Test
    fun `matches starred contacts by phone number, email and name`() {
        val starred =
            StarredContacts.of(
                names = listOf("Asha  Rao"),
                phoneNumbers = listOf("+91 98765 43210"),
                emails = listOf("Ravi@Example.com"),
            )
        assertTrue(StarredMatcher.matches(listOf(Sender(uri = "tel:09876543210")), starred))
        assertTrue(StarredMatcher.matches(listOf(Sender(uri = "mailto:ravi@example.com")), starred))
        assertTrue(StarredMatcher.matches(listOf(Sender(name = "asha rao")), starred))
        assertFalse(StarredMatcher.matches(listOf(Sender(name = "Asha")), starred))
        assertFalse(StarredMatcher.matches(listOf(Sender(uri = "tel:123")), starred))
        assertFalse(StarredMatcher.matches(emptyList(), starred))
    }
}
