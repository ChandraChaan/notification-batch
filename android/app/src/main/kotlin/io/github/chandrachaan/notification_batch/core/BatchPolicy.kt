package io.github.chandrachaan.notification_batch.core

/** The parts of a posted notification that the policy looks at. Built from a StatusBarNotification. */
data class NotificationFacts(
    val packageName: String,
    val category: String? = null,
    /** Ongoing, foreground-service or "no clear": the system would not let us remove it anyway. */
    val isOngoing: Boolean = false,
    val isGroupSummary: Boolean = false,
    val hasFullScreenIntent: Boolean = false,
    val isMedia: Boolean = false,
    /** Android replaced the text because it found sensitive content, such as a one-time code. */
    val contentHiddenBySystem: Boolean = false,
    val fromStarredContact: Boolean = false,
    val title: String = "",
    val text: String = "",
    /** Every other piece of visible text: big text, lines, messages, sub text, ticker. */
    val otherText: List<String> = emptyList(),
) {
    val allText: String
        get() = (listOf(title, text) + otherText).filter { it.isNotBlank() }.joinToString("\n")
}

enum class LetThroughReason {
    CALL,
    ALARM,
    FULL_SCREEN,
    ONGOING,
    MEDIA,
    TIME_SENSITIVE,
    VERIFICATION_CODE,
    URGENT_WORD,
    STARRED_CONTACT,
    NOTHING_TO_SHOW,
}

sealed interface Decision {
    /** Batching is paused or the app is not batched: leave it alone. */
    data object NotBatched : Decision

    data class LetThrough(val reason: LetThroughReason) : Decision

    /** Remove it from the shade and keep it for the next delivery. */
    data object Hold : Decision

    /** A group summary of a batched app: remove it if its children are gone, never store it. */
    data object HoldSummary : Decision
}

object BatchPolicy {
    // Categories that are about the present moment. Holding them for hours would make them useless.
    private val timeSensitiveCategories =
        setOf(
            "reminder", // Notification.CATEGORY_REMINDER
            "event", // CATEGORY_EVENT
            "navigation", // CATEGORY_NAVIGATION
            "stopwatch", // CATEGORY_STOPWATCH
            "progress", // CATEGORY_PROGRESS
            "sys", // CATEGORY_SYSTEM
            "service", // CATEGORY_SERVICE
            "err", // CATEGORY_ERROR
            "location_sharing", // CATEGORY_LOCATION_SHARING
            "missed_call", // CATEGORY_MISSED_CALL
            "car_emergency", // CATEGORY_CAR_EMERGENCY
            "car_warning", // CATEGORY_CAR_WARNING
        )

    fun decide(facts: NotificationFacts, settings: BatchSettings, ownPackage: String): Decision {
        if (settings.paused) return Decision.NotBatched
        if (facts.packageName == ownPackage) return Decision.NotBatched
        if (facts.packageName !in settings.batchedPackages) return Decision.NotBatched

        val reason = letThroughReason(facts, settings)
        return when {
            reason != null -> Decision.LetThrough(reason)
            facts.isGroupSummary -> Decision.HoldSummary
            else -> Decision.Hold
        }
    }

    private fun letThroughReason(facts: NotificationFacts, settings: BatchSettings): LetThroughReason? =
        when {
            facts.category == "call" -> LetThroughReason.CALL
            facts.category == "alarm" -> LetThroughReason.ALARM
            facts.hasFullScreenIntent -> LetThroughReason.FULL_SCREEN
            facts.isOngoing -> LetThroughReason.ONGOING
            facts.isMedia || facts.category == "transport" -> LetThroughReason.MEDIA
            facts.category in timeSensitiveCategories -> LetThroughReason.TIME_SENSITIVE
            facts.contentHiddenBySystem -> LetThroughReason.VERIFICATION_CODE
            OtpDetector.looksLikeCode(facts.allText) -> LetThroughReason.VERIFICATION_CODE
            containsUrgentWord(facts.allText, settings.urgentWords) -> LetThroughReason.URGENT_WORD
            settings.letStarredContactsThrough && facts.fromStarredContact -> LetThroughReason.STARRED_CONTACT
            // A summary has nothing of its own to show, so an empty one is fine to hold.
            !facts.isGroupSummary && facts.title.isBlank() && facts.text.isBlank() ->
                LetThroughReason.NOTHING_TO_SHOW
            else -> null
        }

    internal fun containsUrgentWord(text: String, words: List<String>): Boolean {
        if (words.isEmpty() || text.isBlank()) return false
        return words.any { word ->
            val trimmed = word.trim()
            trimmed.isNotEmpty() &&
                Regex("(?<![\\p{L}\\p{N}])${Regex.escape(trimmed)}(?![\\p{L}\\p{N}])", RegexOption.IGNORE_CASE)
                    .containsMatchIn(text)
        }
    }
}
