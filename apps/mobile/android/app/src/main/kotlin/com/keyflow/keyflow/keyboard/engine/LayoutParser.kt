package com.keyflow.keyflow.keyboard.engine

import org.json.JSONArray
import org.json.JSONObject

/**
 * Parses the versioned JSON layout format (schema 1).
 *
 * Row tokens are either a string or an object:
 *  - "q"            -> character key
 *  - "@shift" "@back" "@enter" "@space" "@next" "@t9next" "@page:symbols" -> action keys
 *  - {"k":"a","p":"àáâ","w":1.5,"l":"label","s":"ABC"} -> full form
 * Unknown schema versions are rejected so that downloaded layouts can be validated.
 */
object LayoutParser {
    const val SUPPORTED_SCHEMA = 1
    private const val MAX_ROWS = 8
    private const val MAX_KEYS_PER_ROW = 14

    class InvalidLayoutException(message: String) : Exception(message)

    fun parse(json: String, sharedPages: Map<String, KeyPage> = emptyMap()): KeyboardLayout {
        val root = try { JSONObject(json) } catch (e: Exception) { throw InvalidLayoutException("Malformed JSON") }
        val schema = root.optInt("schema", -1)
        if (schema != SUPPORTED_SCHEMA) throw InvalidLayoutException("Unsupported schema $schema")
        val id = root.optString("id").also { if (it.isBlank()) throw InvalidLayoutException("Missing id") }
        val pagesJson = root.optJSONObject("pages") ?: throw InvalidLayoutException("Missing pages")
        val pages = LinkedHashMap<String, KeyPage>()
        for (name in pagesJson.keys()) {
            pages[name] = KeyPage(name, parseRows(pagesJson.getJSONArray(name)))
        }
        if (!pages.containsKey("main")) throw InvalidLayoutException("Missing main page")
        if (root.optBoolean("sharedSymbols", false)) {
            for ((n, p) in sharedPages) pages.putIfAbsent(n, p)
        }
        val langs = root.optJSONArray("languages")?.let { a -> (0 until a.length()).map { a.getString(it) } } ?: listOf("en")
        return KeyboardLayout(schema, id, root.optString("name", id), root.optString("mode", "alpha"), langs, pages)
    }

    fun parsePages(json: String): Map<String, KeyPage> {
        val pagesJson = JSONObject(json).getJSONObject("pages")
        return pagesJson.keys().asSequence().associateWith { KeyPage(it, parseRows(pagesJson.getJSONArray(it))) }
    }

    private fun parseRows(rows: JSONArray): List<KeyRow> {
        if (rows.length() == 0 || rows.length() > MAX_ROWS) throw InvalidLayoutException("Invalid row count")
        return (0 until rows.length()).map { r ->
            val row = rows.getJSONArray(r)
            if (row.length() == 0 || row.length() > MAX_KEYS_PER_ROW) throw InvalidLayoutException("Invalid key count")
            KeyRow((0 until row.length()).map { parseKey(row.get(it)) })
        }
    }

    private fun parseKey(token: Any): Key {
        val obj = if (token is JSONObject) token else JSONObject().put("k", token.toString())
        val k = obj.getString("k")
        val weight = obj.optDouble("w", 1.0).toFloat().coerceIn(0.3f, 8f)
        val popups = obj.optString("p", "")
        val sub = if (obj.has("s")) obj.getString("s") else null
        if (!k.startsWith("@") || k == "@") {
            return Key(
                id = k, label = obj.optString("l", k), output = k, action = KeyAction.CHAR,
                weight = weight, popups = popups, sub = sub,
            )
        }
        val name = k.substring(1)
        val (action, defLabel, arg) = when {
            name == "shift" -> Triple(KeyAction.SHIFT, "⇧", null)
            name == "back" -> Triple(KeyAction.BACKSPACE, "⌫", null)
            name == "enter" -> Triple(KeyAction.ENTER, "⏎", null)
            name == "space" -> Triple(KeyAction.SPACE, " ", null)
            name == "next" -> Triple(KeyAction.NEXT_LAYOUT, "🌐", null)
            name == "t9next" -> Triple(KeyAction.T9_NEXT, "↻", null)
            name.startsWith("page:") -> Triple(KeyAction.PAGE, name.substring(5), name.substring(5))
            else -> throw InvalidLayoutException("Unknown action $k")
        }
        return Key(
            id = "@$name", label = obj.optString("l", defLabel), output = if (action == KeyAction.SPACE) " " else null,
            action = action, weight = weight, popups = popups, sub = sub, arg = arg, special = true,
        )
    }
}

