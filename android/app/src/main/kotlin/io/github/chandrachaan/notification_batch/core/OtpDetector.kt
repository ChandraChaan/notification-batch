package io.github.chandrachaan.notification_batch.core

/**
 * Spots notifications that carry a one-time code, so they are never held back.
 *
 * The rule is deliberately simple and leans towards letting things through: a short number that
 * looks like a code (4 to 8 digits, `123 456`, `123-456` or `G-123456`) together with a word that
 * talks about verification. The plain word "code" counts too, unless the text reads like a promotion
 * ("promo code", "20% off"). A false positive costs one extra ping; a false negative could cost a
 * login, so when in doubt the answer is yes.
 */
object OtpDetector {
    private const val NOT_ALNUM = "[\\p{L}\\p{N}]"

    // A code is not glued to letters or digits, not part of a price ("₹4999", "$1299"), a decimal,
    // a date ("2026-10-27") or a longer number written in groups ("+1 555 123 4567").
    private val code =
        Regex(
            "(?<!$NOT_ALNUM|[₹\$€£¥.,]|\\p{Nd}[ .,-])" +
                "(?:[A-Za-z]-)?(?:\\p{Nd}{4,8}|\\p{Nd}{3}[ -]\\p{Nd}{3})" +
                "(?!$NOT_ALNUM|[-.,:/ ]\\p{Nd})",
        )

    private val strongWords =
        words(
            "otp", "one-time", "one time", "onetime", "verif\\p{L}*", "passcode", "pass code",
            "2fa", "two-factor", "two factor", "2-step", "2 step", "two-step", "two step",
            "security code", "login", "log-in", "log in", "sign-in", "sign in", "signin",
            "authenticat\\p{L}*", "auth code", "access code", "confirmation code", "pin",
            // A few common non-English forms.
            "código", "codigo", "kode", "otp कोड", "ओटीपी", "सत्यापन",
        )

    private val weakWords = words("code", "codes", "कोड")

    private val promoWords =
        words(
            "promo\\p{L}*", "coupon\\p{L}*", "discount\\p{L}*", "offers?", "off", "cashback", "voucher\\p{L}*",
            "sale", "deals?", "referral", "refer", "rewards?", "checkout", "save", "shop\\p{L}*",
        )

    fun looksLikeCode(text: String): Boolean {
        if (!code.containsMatchIn(text)) return false
        if (strongWords.containsMatchIn(text)) return true
        return weakWords.containsMatchIn(text) && !promoWords.containsMatchIn(text)
    }

    private fun words(vararg patterns: String): Regex =
        Regex(
            "(?<!$NOT_ALNUM)(?:${patterns.joinToString("|")})(?!$NOT_ALNUM)",
            RegexOption.IGNORE_CASE,
        )
}
