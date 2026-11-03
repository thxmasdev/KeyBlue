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

    fun load(): Config {
        val raw = prefs.getString(KEY, null) ?: DEFAULT
        val o = try { JSONObject(raw) } catch (e: Exception) { JSONObject(DEFAULT) }
        val cycleArr = o.optJSONArray("layouts")
        val cycle = if (cycleArr != null) (0 until cycleArr.length()).map { cycleArr.getString(it) } else listOf("qwerty")
        return Config(
            layoutId = o.optString("layoutId", "qwerty"),
            cycle = cycle.ifEmpty { listOf("qwerty") },
            theme = KeyboardTheme.parse(o.optJSONObject("theme")),
            haptics = o.optBoolean("haptics", true),
            language = o.optString("language", "es"),
            raw = raw,
        )
    }

    companion object {
        private const val KEY = "config_json"
        const val DEFAULT = """{"schema":1,"layoutId":"qwerty","layouts":["qwerty","t9","numeric"],"haptics":true}"""
    }
}

