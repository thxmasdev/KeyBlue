package com.keyflow.keyflow.keyboard.engine

/** Abstraction over Android's InputConnection so the engine is unit-testable without Android. */
interface InputSink {
    fun commitText(text: String)
    fun setComposingText(text: String)
    fun finishComposingText()
    fun deleteBackward()
    fun performEnter()
}

enum class ShiftState { OFF, ONCE, LOCK }

interface EngineListener {
    fun onStateChanged()
    fun onRequestNextLayout()
    /** The user tapped the language key; the host decides which language comes next. */
    fun onRequestNextLanguage() {}
}

/**
 * Typing logic, independent of visuals. Holds the current page, shift state and T9 composition.
 *
 * T9 has two entry modes:
 *  - predictive (default): digits 2-9 build a digit sequence resolved against the dictionary;
 *  - multi-tap (ABC chip): classic letter-by-letter entry used for words the dictionary doesn't know.
 *    Words typed this way are learned into the personal dictionary.
 *
 * Composition only keeps the digit sequence / pending letter of the word being typed and is cleared
 * on commit. Nothing is learned in private (password) fields.
 */
class KeyboardEngine(
    layout: KeyboardLayout,
    private val sink: InputSink,
    dictionary: T9Dictionary? = null,
    private val listener: EngineListener? = null,
) {
    var dictionary: T9Dictionary? = dictionary
        private set
    val language: String get() = dictionary?.language ?: "en"

    /** Switches the T9 language. Any word in progress is committed first. */
    fun setDictionary(d: T9Dictionary?) {
        finishComposition()
        dictionary = d
        listener?.onStateChanged()
    }

    /** Secondary label of a key; on T9 digit keys it depends on the active language (ñ in Spanish). */
    fun subLabel(key: Key): String? {
        val o = key.output
        if (layout.isT9 && pageName == "main" && o != null && o.length == 1 && o[0] in '2'..'9') {
            return T9Dictionary.lettersFor(o[0], language).uppercase()
        }
        return key.sub
    }

    var layout: KeyboardLayout = layout
        private set
    var pageName: String = "main"
        private set
    var shift: ShiftState = ShiftState.OFF
        private set
    /** When true (password / sensitive field) predictive composition and learning are disabled. */
    var privateField: Boolean = false
        set(value) { if (value) finishComposition(); field = value }

    /** true while the user types letter-by-letter instead of predictively. */
    var multiTap: Boolean = false
        private set

    private var digits = StringBuilder()
    var candidates: List<String> = emptyList()
        private set
    var candidateIndex = 0
        private set
    private var lastShiftTap = 0L

    // multi-tap state
    private var mtDigit: Char? = null
    private var mtIndex = 0
    private var mtLastAt = 0L
    private var mtPending: String? = null
    private val mtWord = StringBuilder()

    // sentence tracking for auto-capitalisation after . ? !
    private var lastWasSentenceEnd = false
    private var autoCap = false

    val page: KeyPage get() = layout.pages[pageName] ?: layout.mainPage
    val isComposing: Boolean get() = digits.isNotEmpty() || mtPending != null

    /** True while the '1' key is cycling punctuation marks. */
    private val isPunct: Boolean get() = digits.length == 1 && digits[0] == '1'

    fun setLayout(newLayout: KeyboardLayout) {
        finishComposition()
        layout = newLayout
        pageName = "main"
        shift = ShiftState.OFF
        listener?.onStateChanged()
    }

    fun onStartInput(autoCapitalize: Boolean) {
        digits.clear(); candidates = emptyList(); candidateIndex = 0
        mtPending = null; mtDigit = null; mtWord.clear()
        lastWasSentenceEnd = false; autoCap = false
        pageName = "main"
        shift = if (autoCapitalize) ShiftState.ONCE else ShiftState.OFF
        listener?.onStateChanged()
    }

    fun onFinishInput() {
        // Leave any partially composed word in the field; nothing is retained by the engine.
        if (isComposing) sink.finishComposingText()
        mtPending?.let { mtWord.append(it.lowercase()) }
        learnWord()
        digits.clear(); candidates = emptyList(); candidateIndex = 0
        mtPending = null; mtDigit = null
    }

    /** Switches between predictive T9 and letter-by-letter (multi-tap) entry. */
    fun toggleMultiTap() {
        finishComposition()
        multiTap = !multiTap
        listener?.onStateChanged()
    }

    fun onKey(key: Key, nowMs: Long = System.currentTimeMillis()) {
        when (key.action) {
            KeyAction.CHAR -> onChar(key.output ?: return, nowMs)
            KeyAction.SPACE -> {
                if (mtPending != null || mtWord.isNotEmpty()) {
                    finishMultiTap(); sink.commitText(" ")
                } else if (digits.isNotEmpty()) {
                    commitCandidate(addSpace = true)
                } else {
                    if (lastWasSentenceEnd) autoCap = true
                    lastWasSentenceEnd = false
                    sink.commitText(" ")
                }
                afterCommit()
            }
            KeyAction.BACKSPACE -> onBackspace()
            KeyAction.ENTER -> { finishComposition(); lastWasSentenceEnd = false; sink.performEnter(); afterCommit() }
            KeyAction.SHIFT -> onShift(nowMs)
            KeyAction.PAGE -> { finishComposition(); pageName = key.arg ?: "main"; listener?.onStateChanged() }
            KeyAction.NEXT_LAYOUT -> { finishComposition(); listener?.onRequestNextLayout() }
            KeyAction.LANGUAGE -> { finishComposition(); listener?.onRequestNextLanguage() }
            KeyAction.T9_NEXT -> if (digits.isNotEmpty() && candidates.isNotEmpty()) {
                candidateIndex = (candidateIndex + 1) % candidates.size
                updateComposing()
            } else {
                // Nothing predictive in progress: '*' behaves as a plain character.
                finishComposition()
                sink.commitText("*"); listener?.onStateChanged()
            }
            KeyAction.NONE -> Unit
        }
    }

    /** Commit a character chosen from a long-press popup (e.g. the digit under a T9 key). */
    fun onPopupChar(text: String) {
        finishComposition()
        lastWasSentenceEnd = false
        sink.commitText(text)
        afterCommit()
    }

    fun pickCandidate(index: Int) {
        if (digits.isEmpty() || index !in candidates.indices) return
        candidateIndex = index
        commitCandidate(addSpace = true)
        afterCommit()
    }

    private fun t9Active() = layout.isT9 && pageName == "main" && !privateField && dictionary != null

    private fun onChar(text: String, now: Long) {
        if (t9Active() && text.length == 1 && text[0] in '2'..'9') {
            lastWasSentenceEnd = false
            if (multiTap) { multiTapPress(text[0], now); return }
            if (isPunct) commitCandidate(addSpace = false)
            digits.append(text)
            candidateIndex = 0
            refreshCandidates()
            updateComposing()
            return
        }
        if (t9Active() && text == "1") { onOne(); return }
        finishComposition()
        lastWasSentenceEnd = false
        val out = if (shift != ShiftState.OFF) text.uppercase() else text
        sink.commitText(out)
        afterCommit()
    }

    /** '1' cycles punctuation (. , ? ! ' - : ; @ /) like the classic phones. */
    private fun onOne() {
        if (isPunct) {
            candidateIndex = (candidateIndex + 1) % candidates.size
            updateComposing()
            return
        }
        finishComposition()
        digits.append('1')
        candidates = PUNCTUATION
        candidateIndex = 0
        updateComposing()
    }

    private fun onBackspace() {
        if (mtPending != null) {
            mtPending = null; mtDigit = null
            sink.setComposingText(""); sink.finishComposingText()
            listener?.onStateChanged()
        } else if (digits.isNotEmpty()) {
            digits.deleteCharAt(digits.length - 1)
            candidateIndex = 0
            if (digits.isEmpty()) { candidates = emptyList(); sink.setComposingText(""); sink.finishComposingText() }
            else { refreshCandidates(); updateComposing() }
            listener?.onStateChanged()
        } else {
            if (mtWord.isNotEmpty()) mtWord.deleteCharAt(mtWord.length - 1)
            lastWasSentenceEnd = false
            sink.deleteBackward()
        }
    }

    private fun onShift(now: Long) {
        shift = when (shift) {
            ShiftState.OFF -> ShiftState.ONCE
            ShiftState.ONCE -> if (now - lastShiftTap < DOUBLE_TAP_MS) ShiftState.LOCK else ShiftState.OFF
            ShiftState.LOCK -> ShiftState.OFF
        }
        lastShiftTap = now
        if (digits.isNotEmpty()) updateComposing()
        listener?.onStateChanged()
    }

    // ---- predictive T9 ----

    private fun refreshCandidates() {
        val d = digits.toString()
        val dict = dictionary ?: return
        val list = ArrayList<String>(dict.lookup(d))
        if (list.isEmpty()) {
            list.addAll(dict.lookupPrefix(d))
            // Always provide something typeable: first letter of every key.
            val fallback = d.map { T9Dictionary.lettersFor(it, language).firstOrNull() ?: it }.joinToString("")
            if (!list.contains(fallback)) list.add(fallback)
        } else if (list.size < MAX_CANDIDATES) {
            // Exact matches first, then longer completions of the same digits.
            for (w in dict.lookupPrefix(d, MAX_CANDIDATES - list.size)) if (!list.contains(w)) list.add(w)
        }
        candidates = list
    }

    private fun currentWord(): String {
        val w = candidates.getOrNull(candidateIndex) ?: digits.toString()
        return when (shift) {
            ShiftState.OFF -> w
            ShiftState.ONCE -> w.replaceFirstChar { it.uppercase() }
            ShiftState.LOCK -> w.uppercase()
        }
    }

    private fun updateComposing() {
        sink.setComposingText(currentWord())
        listener?.onStateChanged()
    }

    private fun commitCandidate(addSpace: Boolean) {
        val w = currentWord()
        val punct = isPunct
        val raw = candidates.getOrNull(candidateIndex)
        // Frequently chosen words move to the front next time (kept only on this device).
        if (!punct && !privateField && raw != null && dictionary?.lookup(digits.toString())?.contains(raw) == true) {
            dictionary?.recordUse(raw)
        }
        sink.commitText(if (addSpace) "$w " else w)
        digits.clear(); candidates = emptyList(); candidateIndex = 0
        lastWasSentenceEnd = punct && w.length == 1 && w[0] in ".?!"
        if (addSpace && lastWasSentenceEnd) { autoCap = true; lastWasSentenceEnd = false }
    }

    // ---- multi-tap ----

    private fun multiTapPress(d: Char, now: Long) {
        val letters = T9Dictionary.lettersFor(d, language)
        if (letters.isEmpty()) return
        val same = mtPending != null && mtDigit == d && now - mtLastAt < MULTITAP_MS
        if (same) {
            mtIndex = (mtIndex + 1) % letters.length
        } else {
            commitPendingLetter()
            mtDigit = d; mtIndex = 0
        }
        mtLastAt = now
        val ch = letters[mtIndex].toString()
        val shown = if (shift != ShiftState.OFF) ch.uppercase() else ch
        mtPending = shown
        sink.setComposingText(shown)
        listener?.onStateChanged()
    }

    private fun commitPendingLetter() {
        val p = mtPending ?: return
        sink.commitText(p)
        mtWord.append(p.lowercase())
        mtPending = null; mtDigit = null
        afterCommit()
    }

    private fun finishMultiTap() {
        commitPendingLetter()
        learnWord()
    }

    private fun learnWord() {
        val w = mtWord.toString()
        mtWord.clear()
        if (w.length >= 2 && !privateField) dictionary?.learn(w)
    }

    private fun finishComposition() {
        finishMultiTap()
        if (digits.isNotEmpty()) commitCandidate(addSpace = false)
    }

    private fun afterCommit() {
        if (autoCap && shift != ShiftState.LOCK) { shift = ShiftState.ONCE; autoCap = false }
        else if (shift == ShiftState.ONCE) shift = ShiftState.OFF
        autoCap = false
        listener?.onStateChanged()
    }

    companion object {
        const val DOUBLE_TAP_MS = 350L
        const val MULTITAP_MS = 900L
        const val MAX_CANDIDATES = 8
        val PUNCTUATION = listOf(".", ",", "?", "!", "'", "-", ":", ";", "@", "/", "(", ")", "\"", "&", "+", "%")
    }
}
