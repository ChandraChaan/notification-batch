package io.github.chandrachaan.notification_batch.core

import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.IOException

/**
 * A small JSON file that is replaced atomically: every write goes to a temporary file first and
 * is then renamed over the old one, so a crash mid-write leaves the previous version intact.
 */
class JsonFile(private val file: File) {
    /** Null if the file doesn't exist. A damaged file is set aside and also reads as null. */
    fun read(): JSONObject? {
        if (!file.exists()) return null
        return try {
            JSONObject(file.readText())
        } catch (e: JSONException) {
            setAside(e)
            null
        } catch (e: IOException) {
            setAside(e)
            null
        }
    }

    fun write(json: JSONObject) {
        file.parentFile?.mkdirs()
        val temp = File(file.parentFile, "${file.name}.tmp")
        temp.writeText(json.toString())
        if (!temp.renameTo(file)) {
            file.delete()
            if (!temp.renameTo(file)) throw IOException("Could not replace ${file.name}")
        }
    }

    /** A damaged file is renamed, not deleted, so it can still be looked at. */
    fun setAside(cause: Exception) {
        System.err.println("Notification Batch: ${file.name} could not be read (${cause.javaClass.simpleName})")
        file.renameTo(File(file.parentFile, "${file.name}.damaged"))
    }
}
