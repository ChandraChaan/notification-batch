package io.github.chandrachaan.notification_batch.platform

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.SystemClock
import android.provider.ContactsContract
import android.util.Log
import io.github.chandrachaan.notification_batch.core.Sender
import io.github.chandrachaan.notification_batch.core.StarredContacts
import io.github.chandrachaan.notification_batch.core.StarredMatcher

/** Reads starred contacts, only if the user turned the option on and granted contacts access. */
class StarredContactsReader(private val context: Context) {
    @Volatile private var cached: StarredContacts? = null

    @Volatile private var cachedAt = 0L

    fun isStarred(senders: List<Sender>): Boolean {
        if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        return try {
            senders.any { isStarredContactUri(it.uri) } || StarredMatcher.matches(senders, snapshot())
        } catch (e: RuntimeException) {
            // A broken contacts provider should not stop batching. Unsure, so let it through.
            Log.w("NotificationBatch", "Could not read contacts", e)
            true
        }
    }

    private fun snapshot(): StarredContacts {
        val now = SystemClock.elapsedRealtime()
        cached?.takeIf { now - cachedAt < CACHE_MILLIS }?.let { return it }
        return StarredContacts.of(
            names =
                strings(
                    ContactsContract.Contacts.CONTENT_URI,
                    ContactsContract.Contacts.DISPLAY_NAME,
                    "${ContactsContract.Contacts.STARRED} = 1",
                ),
            phoneNumbers =
                strings(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    ContactsContract.CommonDataKinds.Phone.NUMBER,
                    "${ContactsContract.CommonDataKinds.Phone.STARRED} = 1",
                ),
            emails =
                strings(
                    ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                    ContactsContract.CommonDataKinds.Email.ADDRESS,
                    "${ContactsContract.CommonDataKinds.Email.STARRED} = 1",
                ),
        ).also {
            cached = it
            cachedAt = now
        }
    }

    /** Some apps point at the contact itself: content://com.android.contacts/... */
    private fun isStarredContactUri(uri: String?): Boolean {
        if (uri == null || !uri.startsWith("content://${ContactsContract.AUTHORITY}")) return false
        val parsed = Uri.parse(uri)
        context.contentResolver.query(parsed, arrayOf(ContactsContract.Contacts.STARRED), null, null, null)?.use {
            return it.moveToFirst() && it.getInt(0) == 1
        }
        return false
    }

    private fun strings(uri: Uri, column: String, selection: String): List<String> =
        context.contentResolver.query(uri, arrayOf(column), selection, null, null)?.use { cursor ->
            buildList { while (cursor.moveToNext()) cursor.getString(0)?.let(::add) }
        }.orEmpty()

    private companion object {
        const val CACHE_MILLIS = 5 * 60 * 1000L
    }
}
