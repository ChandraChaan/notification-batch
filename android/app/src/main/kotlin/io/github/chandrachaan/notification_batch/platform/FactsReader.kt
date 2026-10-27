package io.github.chandrachaan.notification_batch.platform

import android.app.Notification
import android.app.Person
import android.content.res.Resources
import android.os.Build
import android.os.Bundle
import android.os.Parcelable
import android.service.notification.StatusBarNotification
import io.github.chandrachaan.notification_batch.core.NotificationFacts
import io.github.chandrachaan.notification_batch.core.Sender

/** Reads the text and flags of a posted notification into plain values the policy understands. */
object FactsReader {
    private const val MAX_TEXT = 1000

    fun read(sbn: StatusBarNotification, isStarred: (List<Sender>) -> Boolean): NotificationFacts {
        val notification = sbn.notification
        val extras = notification.extras
        val title =
            extras.text(Notification.EXTRA_CONVERSATION_TITLE)
                ?: extras.text(Notification.EXTRA_TITLE_BIG)
                ?: extras.text(Notification.EXTRA_TITLE)
        val messages = messages(extras)
        val text =
            extras.text(Notification.EXTRA_BIG_TEXT)
                ?: extras.text(Notification.EXTRA_TEXT)
                ?: messages.lastOrNull()?.second
        val other =
            buildList {
                extras.text(Notification.EXTRA_TITLE)?.let(::add)
                extras.text(Notification.EXTRA_TEXT)?.let(::add)
                extras.text(Notification.EXTRA_SUB_TEXT)?.let(::add)
                extras.text(Notification.EXTRA_SUMMARY_TEXT)?.let(::add)
                extras.text(Notification.EXTRA_INFO_TEXT)?.let(::add)
                extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach { add(it.toString()) }
                messages.forEach { (_, body) -> add(body) }
                notification.tickerText?.let { add(it.toString()) }
            }.map { it.take(MAX_TEXT) }

        val flags = notification.flags
        val isMessage =
            notification.category == Notification.CATEGORY_MESSAGE || messages.isNotEmpty()
        return NotificationFacts(
            packageName = sbn.packageName,
            category = notification.category,
            isOngoing =
                sbn.isOngoing ||
                    flags and (Notification.FLAG_FOREGROUND_SERVICE or Notification.FLAG_NO_CLEAR) != 0,
            isGroupSummary = flags and Notification.FLAG_GROUP_SUMMARY != 0,
            hasFullScreenIntent = notification.fullScreenIntent != null,
            isMedia = extras.containsKey(Notification.EXTRA_MEDIA_SESSION),
            contentHiddenBySystem = isRedacted(text) || isRedacted(title),
            fromStarredContact = isMessage && isStarred(senders(extras, title)),
            title = title.orEmpty().take(MAX_TEXT),
            text = text.orEmpty().take(MAX_TEXT),
            otherText = other,
        )
    }

    /** Pairs of sender name and message text from a MessagingStyle notification. */
    private fun messages(extras: Bundle): List<Pair<String?, String>> =
        parcelableArray(extras, Notification.EXTRA_MESSAGES)
            .filterIsInstance<Bundle>()
            .mapNotNull { message ->
                val body = message.getCharSequence("text")?.toString() ?: return@mapNotNull null
                message.getCharSequence("sender")?.toString() to body
            }

    private fun senders(extras: Bundle, title: String?): List<Sender> =
        buildList {
            parcelableList(extras, Notification.EXTRA_PEOPLE_LIST).filterIsInstance<Person>().forEach {
                add(Sender(it.name?.toString(), it.uri))
            }
            parcelableArray(extras, Notification.EXTRA_MESSAGES).filterIsInstance<Bundle>().forEach { message ->
                val person = parcelable(message, "sender_person") as? Person
                add(Sender(person?.name?.toString() ?: message.getCharSequence("sender")?.toString(), person?.uri))
            }
            // Most chat apps put the sender's name in the title of a one-to-one chat.
            title?.let { add(Sender(name = it)) }
        }

    // Android 15 and later can hide one-time codes from notification listeners and show this text
    // instead. If that happens the system has already decided it is sensitive, so let it through.
    private val redactedTexts: Set<String> by lazy {
        val names = listOf("redacted_notification_message", "redacted_otp_notification_text")
        val system = Resources.getSystem()
        val fromSystem =
            names.mapNotNull { name ->
                val id = system.getIdentifier(name, "string", "android")
                if (id == 0) null else runCatching { system.getString(id) }.getOrNull()
            }
        (fromSystem + "Sensitive notification content hidden").map { it.lowercase() }.toSet()
    }

    private fun isRedacted(text: String?): Boolean = text != null && text.trim().lowercase() in redactedTexts

    private fun Bundle.text(key: String): String? = getCharSequence(key)?.toString()?.takeIf { it.isNotBlank() }

    // Extras come from other apps, so a malformed value must never crash the listener.
    @Suppress("DEPRECATION")
    private fun parcelableArray(bundle: Bundle, key: String): List<Parcelable> =
        runCatching { bundle.getParcelableArray(key)?.toList() }.getOrNull().orEmpty()

    @Suppress("DEPRECATION")
    private fun parcelableList(bundle: Bundle, key: String): List<Parcelable> =
        runCatching { bundle.getParcelableArrayList<Parcelable>(key)?.toList() }.getOrNull().orEmpty()

    @Suppress("DEPRECATION")
    private fun parcelable(bundle: Bundle, key: String): Parcelable? =
        runCatching {
            if (Build.VERSION.SDK_INT >= 33) bundle.getParcelable(key, Parcelable::class.java) else bundle.getParcelable(key)
        }.getOrNull()
}
