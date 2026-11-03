package com.keyflow.keyflow.keyboard.themes

import android.graphics.Color
import org.json.JSONObject

data class KeyOverride(val bg: Int?, val fg: Int?, val widthScale: Float?)

/** Visual theme. Pure data: parsed from versioned JSON, no code is ever executed from it. */
data class KeyboardTheme(
    val id: String = "midnight",
    val background: Int = Color.parseColor("#12161C"),
    val key: Int = Color.parseColor("#262D37"),
    val keyText: Int = Color.WHITE,
    val special: Int = Color.parseColor("#37414F"),
    val specialText: Int = Color.WHITE,
    val accent: Int = Color.parseColor("#3D7BFF"),
    val accentText: Int = Color.WHITE,
    val radiusDp: Float = 10f,
    val gapDp: Float = 4f,
    val keyHeightDp: Float = 52f,
    val fontSizeSp: Float = 20f,
    val bold: Boolean = false,
    val borderWidthDp: Float = 0f,
    val borderColor: Int = Color.TRANSPARENT,
    val shadow: Boolean = false,
    val keyAlpha: Float = 1f,
    val overrides: Map<String, KeyOverride> = emptyMap(),
    val bgImagePath: String? = null,
    val bgImageAlpha: Float = 1f,
    val bgDim: Float = 0f,
) {
    companion object {
        fun parse(obj: JSONObject?): KeyboardTheme {
            if (obj == null) return KeyboardTheme()
            val d = KeyboardTheme()
            fun c(name: String, def: Int): Int = try { Color.parseColor(obj.optString(name, "")) } catch (e: Exception) { def }
            fun f(name: String, def: Float, lo: Float, hi: Float) = obj.optDouble(name, def.toDouble()).toFloat().coerceIn(lo, hi)
            val overrides = HashMap<String, KeyOverride>()
            obj.optJSONObject("overrides")?.let { o ->
                for (k in o.keys()) {
                    val v = o.optJSONObject(k) ?: continue
                    fun oc(n: String): Int? = if (v.has(n)) try { Color.parseColor(v.getString(n)) } catch (e: Exception) { null } else null
                    overrides[k] = KeyOverride(oc("bg"), oc("fg"), if (v.has("w")) v.getDouble("w").toFloat().coerceIn(0.5f, 3f) else null)
                }
            }
            return KeyboardTheme(
                id = obj.optString("id", d.id),
                background = c("background", d.background), key = c("key", d.key), keyText = c("keyText", d.keyText),
                special = c("special", d.special), specialText = c("specialText", d.specialText),
                accent = c("accent", d.accent), accentText = c("accentText", d.accentText),
                radiusDp = f("radius", d.radiusDp, 0f, 40f), gapDp = f("gap", d.gapDp, 0f, 16f),
                keyHeightDp = f("keyHeight", d.keyHeightDp, 36f, 80f), fontSizeSp = f("fontSize", d.fontSizeSp, 10f, 36f),
                bold = obj.optBoolean("bold", false), borderWidthDp = f("borderWidth", 0f, 0f, 6f),
                borderColor = c("borderColor", d.borderColor), shadow = obj.optBoolean("shadow", false),
                keyAlpha = f("keyAlpha", 1f, 0f, 1f), overrides = overrides,
                bgImagePath = obj.optString("bgImage", "").ifBlank { null },
                bgImageAlpha = f("bgImageAlpha", 1f, 0f, 1f), bgDim = f("bgDim", 0f, 0f, 0.9f),
            )
        }
    }
}

