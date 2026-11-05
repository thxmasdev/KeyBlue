package com.keyflow.keyflow.keyboard.bridge

import android.content.Context
import com.keyflow.keyflow.keyboard.themes.KeyboardTheme
import org.json.JSONObject

/**
 * Local, versioned configuration shared between Flutter (writer) and the keyboard service (reader).
 * Stored in private SharedPreferences. The keyboard never touches the network.
 *
 * {"schema":1,"layoutId":"qwerty","layouts":["qwerty","t9"],"theme":{...},"haptics":true}
 */
class ConfigStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("keyflow_config", Context.MODE_PRIVATE)

    data class Config(
        val layoutId: String, val cycle: List<String>, val theme: KeyboardTheme,
        val haptics: Boolean, val language: String, val raw: String,
    )

    fun saveRaw(json: String) {
        JSONObject(json) // validate before persisting
        prefs.edit().putString(KEY, json).apply()
    }

    fun rawOrNull(): String? = prefs.getString(KEY, null)

    /** Persists the language chosen with the keyboard's language key. */
    fun saveLanguage(lang: String) {
        val o = try { JSONObject(prefs.getString(KEY, null) ?: DEFAULT) } catch (e: Exception) { JSONObject(DEFAULT) }
        prefs.edit().putString(KEY, o.put("language", lang).toString()).apply()
    }

    fun load(): Config {
        val raw = prefs.getString(KEY, null) ?: DEFAULT
        val o = try { JSONObject(raw) } catch (e: Exception) { JSONObject(DEFAULT) }
        val cycleArr = o.optJSONArray("layouts")
        val cycle = if (cycleArr != null) (0 until cycleArr.length()).map { cycleArr.getString(it) } else listOf("t9")
        return Config(
            layoutId = o.optString("layoutId", "t9"),
            cycle = cycle.ifEmpty { listOf("t9") },
            theme = KeyboardTheme.parse(o.optJSONObject("theme")),
            haptics = o.optBoolean("haptics", true),
            language = o.optString("language", "es"),
            raw = raw,
        )
    }

    companion object {
        private const val KEY = "config_json"
        const val DEFAULT = """{"schema":1,"layoutId":"t9","layouts":["t9","numeric"],"language":"es","haptics":true}"""
    }
}

