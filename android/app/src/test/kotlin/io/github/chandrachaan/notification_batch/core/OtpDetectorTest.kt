package io.github.chandrachaan.notification_batch.core

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OtpDetectorTest {
    private val codes =
        listOf(
            "123456 is your verification code",
            "Your OTP is 4821. Do not share it with anyone.",
            "G-482913 is your Google verification code.",
            "Use 908 112 to sign in to your account",
            "Your login code: 908-112",
            "Your Uber code: 4821",
            "Bank: 77104321 is the one-time password for your transaction",
            "Two-factor authentication code 552901",
            "Your PIN for delivery is 4410",
            "Enter 6710 to verify your phone number",
            "Tu código de verificación es 381920",
            "आपका ओटीपी 552901 है",
            "Confirmation code\n482913",
            "Your delivery code is 2208",
            "Your security code is ٤٨٢١٩٣",
        )

    private val notCodes =
        listOf(
            "Flash sale! 50% off everything until midnight",
            "Use promo code 4821 for 20% off your next order",
            "Your order #402-1234567-1234567 has shipped",
            "Meeting moved to 10:30",
            "You have 3 new followers",
            "Call me at +1 555 123 4567 about the code review",
            "Shipping update: arriving 2026-10-27",
            "Your package will arrive tomorrow",
            "Your code review has 12 new comments",
            "Pay ₹4999 to complete your order",
            "Use code SAVE5000 at checkout",
            "Pinned: 4821 people liked this",
            "Score: 12345 points! Code red event starts now, shop the deals",
        )

    @Test
    fun `finds one-time codes`() {
        for (text in codes) assertTrue("Expected a code in: $text", OtpDetector.looksLikeCode(text))
    }

    @Test
    fun `ignores promotions, order numbers, dates, phone numbers and prices`() {
        for (text in notCodes) assertFalse("Expected no code in: $text", OtpDetector.looksLikeCode(text))
    }

    @Test
    fun `needs both a code and a word about it`() {
        assertFalse(OtpDetector.looksLikeCode("482913"))
        assertFalse(OtpDetector.looksLikeCode("Your verification is complete"))
    }

    @Test
    fun `numbers longer than eight digits are not codes`() {
        assertFalse(OtpDetector.looksLikeCode("Verification ref 123456789012"))
    }

    @Test
    fun `a strong word wins over a promotion word`() {
        assertTrue(OtpDetector.looksLikeCode("Your OTP is 4821. Shop the sale today!"))
    }
}
