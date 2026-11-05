package com.keyflow.keyflow.keyboard.engine

import java.text.Normalizer

/**
 * Predictive T9 dictionary for one language. Loaded from a bundled word list ordered by frequency.
 * Fully offline. Accented letters map to the key of their base letter (á→2, é→3 …) and ñ shares key 6
 * with m/n/o, so Spanish words are typed with the same 2-9 digit keys.
 */
class T9Dictionary(words: List<String>, val language: String = "en", val personal: PersonalDictionary? = null) {
    private val map = HashMap<String, MutableList<String>>()

    init {
        for (w in words) {
            val clean = w.trim().lowercase()
            if (clean.isEmpty()) continue
            val digits = digitsFor(clean) ?: continue
            val list = map.getOrPut(digits) { ArrayList(2) }
            if (!list.contains(clean)) list.add(clean)
        }
    }

    /** Personal words first (most used on top), then the bundled list ordered by frequency. */
    fun lookup(digits: String): List<String> {
        val base = map[digits] ?: emptyList()
        val mine = personal?.matching(digits)
        if (mine.isNullOrEmpty()) return base
        return (mine + base).distinct()
    }

    /** Teach a new word (typed letter by letter). */
    fun learn(word: String) { personal?.add(word, 2) }

    /** Count a chosen dictionary word so it ranks higher next time. */
    fun recordUse(word: String) { personal?.add(word, 1) }

    /** Words that start with the given digits, used as a prefix completion when no exact word exists. */
    fun lookupPrefix(digits: String, limit: Int = 3): List<String> {
        if (digits.isEmpty()) return emptyList()
        val out = ArrayList<String>()
        personal?.matchingPrefix(digits, limit)?.let { out.addAll(it) }
        for ((k, v) in map) {
            if (k.length > digits.length && k.startsWith(digits)) {
                out.add(v.first())
                if (out.size >= limit * 8) break
            }
        }
        return out.distinct().sortedBy { it.length }.take(limit)
    }

    companion object {
        private const val GROUPS = "abc def ghi jkl mno pqrs tuv wxyz"
        private val table: Map<Char, Char> = buildMap {
            GROUPS.split(" ").forEachIndexed { i, g -> g.forEach { put(it, ('2' + i)) } }
            put('ñ', '6')
        }

        /** Digit of a (possibly accented) letter, or null when it is not a letter T9 can type. */
        fun digitFor(c: Char): Char? {
            table[c]?.let { return it }
            val base = Normalizer.normalize(c.toString(), Normalizer.Form.NFD).firstOrNull() ?: return null
            return table[base]
        }

        fun digitsFor(word: String): String? {
            val sb = StringBuilder(word.length)
            for (c in word) sb.append(digitFor(c) ?: return null)
            return sb.toString()
        }

        /** Letters shown/typed on a key; Spanish adds ñ on key 6. */
        fun lettersFor(d: Char, language: String = "en"): String {
            if (d !in '2'..'9') return ""
            val base = GROUPS.split(" ")[d - '2']
            return if (language == "es" && d == '6') "mnño" else base
        }
    }
}
