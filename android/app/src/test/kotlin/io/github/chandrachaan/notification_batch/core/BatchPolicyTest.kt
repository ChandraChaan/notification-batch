package io.github.chandrachaan.notification_batch.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BatchPolicyTest {
    private val own = "io.github.chandrachaan.notification_batch"
    private val shop = "com.example.shop"
    private val settings = BatchSettings(batchedPackages = setOf(shop))

    private fun facts(
        title: String = "Your cart misses you",
        text: String = "Items in your cart are selling fast",
        category: String? = null,
    ) = NotificationFacts(packageName = shop, title = title, text = text, category = category)

    private fun decide(facts: NotificationFacts, settings: BatchSettings = this.settings) =
        BatchPolicy.decide(facts, settings, own)

    @Test
    fun `holds an ordinary notification from a batched app`() {
        assertEquals(Decision.Hold, decide(facts()))
    }

    @Test
    fun `leaves apps that are not batched alone`() {
        assertEquals(Decision.NotBatched, decide(facts().copy(packageName = "com.whatsapp")))
    }

    @Test
    fun `does nothing while paused`() {
        assertEquals(Decision.NotBatched, decide(facts(), settings.copy(paused = true)))
    }

    @Test
    fun `never holds its own notifications`() {
        val ownFacts = facts().copy(packageName = own)
        assertEquals(Decision.NotBatched, decide(ownFacts, settings.copy(batchedPackages = setOf(own))))
    }

    @Test
    fun `lets calls and alarms through`() {
        assertEquals(Decision.LetThrough(LetThroughReason.CALL), decide(facts(category = "call")))
        assertEquals(Decision.LetThrough(LetThroughReason.ALARM), decide(facts(category = "alarm")))
    }

    @Test
    fun `lets full screen, ongoing and media notifications through`() {
        assertEquals(
            Decision.LetThrough(LetThroughReason.FULL_SCREEN),
            decide(facts().copy(hasFullScreenIntent = true)),
        )
        assertEquals(Decision.LetThrough(LetThroughReason.ONGOING), decide(facts().copy(isOngoing = true)))
        assertEquals(Decision.LetThrough(LetThroughReason.MEDIA), decide(facts().copy(isMedia = true)))
        assertEquals(Decision.LetThrough(LetThroughReason.MEDIA), decide(facts(category = "transport")))
    }

    @Test
    fun `lets time sensitive categories through`() {
        for (category in listOf("reminder", "event", "navigation", "progress", "missed_call", "err")) {
            assertEquals(
                "category $category",
                Decision.LetThrough(LetThroughReason.TIME_SENSITIVE),
                decide(facts(category = category)),
            )
        }
    }

    @Test
    fun `holds promotions, social and recommendation categories`() {
        for (category in listOf("promo", "social", "recommendation", "email", "msg", null)) {
            assertEquals("category $category", Decision.Hold, decide(facts(category = category)))
        }
    }

    @Test
    fun `lets one-time codes through, even from a batched app`() {
        val otp = facts(title = "Shop", text = "482913 is your verification code")
        assertEquals(Decision.LetThrough(LetThroughReason.VERIFICATION_CODE), decide(otp))
    }

    @Test
    fun `finds a code anywhere in the notification text`() {
        val otp = facts().copy(otherText = listOf("Your login code: 908-112"))
        assertEquals(Decision.LetThrough(LetThroughReason.VERIFICATION_CODE), decide(otp))
    }

    @Test
    fun `lets through text that Android hid as sensitive`() {
        val hidden = facts(text = "Sensitive notification content hidden").copy(contentHiddenBySystem = true)
        assertEquals(Decision.LetThrough(LetThroughReason.VERIFICATION_CODE), decide(hidden))
    }

    @Test
    fun `lets urgent words through as whole words, ignoring case`() {
        val urgent = settings.copy(urgentWords = listOf("Delivered", "gate change"))
        assertEquals(
            Decision.LetThrough(LetThroughReason.URGENT_WORD),
            decide(facts(text = "Your parcel was delivered to the front door"), urgent),
        )
        assertEquals(
            Decision.LetThrough(LetThroughReason.URGENT_WORD),
            decide(facts(title = "Flight AI 101", text = "GATE CHANGE: now B12"), urgent),
        )
        assertEquals(Decision.Hold, decide(facts(text = "Undelivered items are back in stock"), urgent))
    }

    @Test
    fun `urgent words with symbols are matched literally`() {
        assertTrue(BatchPolicy.containsUrgentWord("Ticket C++ build failed", listOf("c++")))
        assertFalse(BatchPolicy.containsUrgentWord("Ticket C build failed", listOf("c++")))
        assertFalse(BatchPolicy.containsUrgentWord("anything", listOf(" ")))
    }

    @Test
    fun `starred contacts only count when the option is on`() {
        val fromStarred = facts(category = "msg").copy(fromStarredContact = true)
        assertEquals(Decision.Hold, decide(fromStarred))
        assertEquals(
            Decision.LetThrough(LetThroughReason.STARRED_CONTACT),
            decide(fromStarred, settings.copy(letStarredContactsThrough = true)),
        )
    }

    @Test
    fun `when there is nothing to show, it is let through`() {
        assertEquals(Decision.LetThrough(LetThroughReason.NOTHING_TO_SHOW), decide(facts(title = " ", text = "")))
    }

    @Test
    fun `group summaries are removed but not stored`() {
        val summary = facts(title = "", text = "").copy(isGroupSummary = true)
        assertEquals(Decision.HoldSummary, decide(summary))
    }

    @Test
    fun `a group summary that carries a code is let through`() {
        val summary = facts(text = "Your OTP is 4821").copy(isGroupSummary = true)
        assertEquals(Decision.LetThrough(LetThroughReason.VERIFICATION_CODE), decide(summary))
    }
}
