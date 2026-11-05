package com.keyflow.keyflow.keyboard.layouts

import android.content.Context
import com.keyflow.keyflow.keyboard.engine.PersonalDictionary
import com.keyflow.keyflow.keyboard.engine.KeyPage
import com.keyflow.keyflow.keyboard.engine.KeyboardLayout
import com.keyflow.keyflow.keyboard.engine.LayoutParser
import com.keyflow.keyflow.keyboard.engine.T9Dictionary

/** Loads layouts and the T9 dictionary from bundled assets. Cached for the process lifetime. */
class LayoutRepository(private val context: Context) {
    private val dir = "keyflow/layouts"
    private var cache: Map<String, KeyboardLayout>? = null
    private val dicts = HashMap<String, T9Dictionary>()

    @Synchronized
    fun all(): Map<String, KeyboardLayout> {
        cache?.let { return it }
        val shared: Map<String, KeyPage> = try {
            LayoutParser.parsePages(read("$dir/_symbols.json"))
        } catch (e: Exception) { emptyMap() }
        val out = LinkedHashMap<String, KeyboardLayout>()
        for (name in (context.assets.list(dir) ?: emptyArray()).sorted()) {
            if (!name.endsWith(".json") || name.startsWith("_")) continue
            try {
                val l = LayoutParser.parse(read("$dir/$name"), shared)
                out[l.id] = l
            } catch (e: Exception) { /* invalid layouts are skipped, never crash the keyboard */ }
        }
        cache = out
        return out
    }

    fun get(id: String): KeyboardLayout? = all()[id] ?: all()["qwerty"] ?: all().values.firstOrNull()

    fun rawJson(id: String): String? = try { read("$dir/$id.json") } catch (e: Exception) { null }

    @Synchronized
    fun dictionary(language: String): T9Dictionary {
        val lang = if (language in SUPPORTED_LANGUAGES) language else "en"
        dicts[lang]?.let { return it }
        val words = try {
            context.assets.open("keyflow/words_$lang.txt").bufferedReader().readLines()
        } catch (e: Exception) { emptyList() }
        val personal = PersonalDictionary(java.io.File(context.filesDir, "keyblue_user_words_$lang.txt"))
        return T9Dictionary(words, lang, personal).also { dicts[lang] = it }
    }

    companion object { val SUPPORTED_LANGUAGES = listOf("en", "es") }

    private fun read(path: String) = context.assets.open(path).bufferedReader().use { it.readText() }
}

