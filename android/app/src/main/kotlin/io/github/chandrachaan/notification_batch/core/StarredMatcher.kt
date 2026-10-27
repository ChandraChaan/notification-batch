package io.github.chandrachaan.notification_batch.core

/** Someone a message notification says it is from. */
data class Sender(val name: String? = null, val uri: String? = null)

/** The starred contacts on the phone, reduced to what a notification can be matched against. */
data class StarredContacts(
    val names: Set<String> = emptySet(),
    val phoneNumbers: Set<String> = emptySet(),
    val emails: Set<String> = emptySet(),
) {
    companion object {
        fun of(names: Iterable<String>, phoneNumbers: Iterable<String>, emails: Iterable<String>) =
            StarredContacts(
                names = names.mapNotNull(StarredMatcher::normalizeName).toSet(),
                phoneNumbers = phoneNumbers.mapNotNull(StarredMatcher::normalizePhone).toSet(),
                emails = emails.mapNotNull(StarredMatcher::normalizeEmail).toSet(),
            )
    }
}

object StarredMatcher {
    /** Numbers are compared on their last digits so "+91 98765 43210" matches "098765 43210". */
    private const val PHONE_DIGITS = 9

    fun matches(senders: List<Sender>, starred: StarredContacts): Boolean =
        senders.any { sender ->
            val uri = sender.uri.orEmpty()
            when {
                uri.startsWith("tel:", ignoreCase = true) ->
                    normalizePhone(uri.substring(4))?.let { it in starred.phoneNumbers } == true
                uri.startsWith("mailto:", ignoreCase = true) ->
                    normalizeEmail(uri.substring(7))?.let { it in starred.emails } == true
                else -> false
            } || normalizeName(sender.name)?.let { it in starred.names } == true
        }

    fun normalizeName(name: String?): String? =
        name?.trim()?.replace(Regex("\\s+"), " ")?.lowercase()?.takeIf { it.isNotEmpty() }

    fun normalizePhone(number: String?): String? {
        val digits = number?.filter(Char::isDigit).orEmpty()
        return if (digits.length < 7) null else digits.takeLast(PHONE_DIGITS)
    }

    fun normalizeEmail(email: String?): String? =
        email?.trim()?.lowercase()?.takeIf { it.contains('@') }
}
