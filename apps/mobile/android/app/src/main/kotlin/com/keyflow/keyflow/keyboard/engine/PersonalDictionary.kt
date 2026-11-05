package com.keyflow.keyflow.keyboard.engine

import java.io.File

/**
 * Words the user taught the keyboard (typed in multi-tap) and words they pick often.
 * Stored only on this device in a private file; one "word<TAB>count" per line.
 * `file == null` keeps it in memory (unit tests).
 */
class PersonalDictionary(private val file: File?) {
    private val counts = LinkedHashMap<String, Int>()

    init { load() }

    @Synchronized
    private fun load() {
        val f = file ?: return
        if (!f.exists()) return
        try {
            f.forEachLine { line ->
                val parts = line.split('\t')
                val w = parts.getOrNull(0)?.trim().orEmpty()
                if (w.isNotEmpty() && T9Dictionary.digitsFor(w) != null) {
                    counts[w] = parts.getOrNull(1)?.toIntOrNull() ?: 1
                }
            }
        } catch (_: Exception) { /* a damaged file just starts empty */ }
    }

    @Synchronized
    private fun save() {
        val f = file ?: return
        try {
            f.writeText(counts.entries.joinToString("\n") { "${it.key}\t${it.value}" })
        } catch (_: Exception) { }
    }

    @Synchronized
    fun add(word: String, weight: Int = 1) {
        val w = word.trim().lowercase()
        if (w.length < 2 || w.length > MAX_WORD || T9Dictionary.digitsFor(w) == null) return
        counts[w] = (counts[w] ?: 0) + weight
        if (counts.size > MAX_WORDS) {
            // drop the least used entry
            counts.entries.minByOrNull { it.value }?.key?.let { counts.remove(it) }
        }
        save()
    }

    @Synchronized fun contains(word: String) = counts.containsKey(word.lowercase())

    @Synchronized
    fun matching(digits: String): List<String> =
        counts.entries.filter { T9Dictionary.digitsFor(it.key) == digits }
            .sortedByDescending { it.value }.map { it.key }

    @Synchronized
    fun matchingPrefix(digits: String, limit: Int): List<String> =
        counts.entries.filter { val d = T9Dictionary.digitsFor(it.key)!!; d.length > digits.length && d.startsWith(digits) }
            .sortedByDescending { it.value }.map { it.key }.take(limit)

    @Synchronized fun words(): List<String> = counts.keys.toList()

    @Synchronized fun remove(word: String) { if (counts.remove(word.lowercase()) != null) save() }

    @Synchronized fun clear() { counts.clear(); save() }

    companion object {
        const val MAX_WORDS = 3000
        const val MAX_WORD = 32
    }
}

