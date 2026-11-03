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
}

/**
 * Typing logic, independent of visuals. Holds the current page, shift state and T9 composition.
 * Never stores typed text: composition only keeps the digit sequence of the word being typed,
 * and it is cleared on commit / finish.
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
    /** When true (password / sensitive field) predictive composition is disabled. */
    var privateField: Boolean = false
        set(value) { if (value) finishComposition(); field = value }

    private var digits = StringBuilder()
    var candidates: List<String> = emptyList()
        private set
    var candidateIndex = 0
        private set
    private var lastShiftTap = 0L

    val page: KeyPage get() = layout.pages[pageName] ?: layout.mainPage
    val isComposing: Boolean get() = digits.isNotEmpty()

    fun setLayout(newLayout: KeyboardLayout) {
        finishComposition()
        layout = newLayout
        pageName = "main"
        shift = ShiftState.OFF
        listener?.onStateChanged()
    }

    fun onStartInput(autoCapitalize: Boolean) {
        digits.clear(); candidates = emptyList(); candidateIndex = 0
        pageName = "main"
        shift = if (autoCapitalize) ShiftState.ONCE else ShiftState.OFF
        listener?.onStateChanged()
    }

    fun onFinishInput() {
        // Leave any partially composed word in the field; nothing is retained by the engine.
        if (isComposing) sink.finishComposingText()
        digits.clear(); candidates = emptyList(); candidateIndex = 0
    }

    fun onKey(key: Key, nowMs: Long = System.currentTimeMillis()) {
        when (key.action) {
            KeyAction.CHAR -> onChar(key.output ?: return)
            KeyAction.SPACE -> {
                if (isComposing) commitCandidate(addSpace = true) else sink.commitText(" ")
                afterCommit()
            }
            KeyAction.BACKSPACE -> onBackspace()
            KeyAction.ENTER -> { finishComposition(); sink.performEnter(); afterCommit() }
            KeyAction.SHIFT -> onShift(nowMs)
            KeyAction.PAGE -> { finishComposition(); pageName = key.arg ?: "main"; listener?.onStateChanged() }
            KeyAction.NEXT_LAYOUT -> { finishComposition(); listener?.onRequestNextLayout() }
            KeyAction.T9_NEXT -> if (isComposing && candidates.isNotEmpty()) {
                candidateIndex = (candidateIndex + 1) % candidates.size
                updateComposing()
            } else {
                // Nothing composing: '*' behaves as a plain character.
                sink.commitText("*"); listener?.onStateChanged()
            }
            KeyAction.NONE -> Unit
        }
    }

    /** Commit a character chosen from a long-press popup. */
    fun onPopupChar(text: String) {
        finishComposition()
        sink.commitText(text)
        afterCommit()
    }

    fun pickCandidate(index: Int) {
        if (!isComposing || index !in candidates.indices) return
        candidateIndex = index
        commitCandidate(addSpace = true)
        afterCommit()
    }

    private fun t9Active() = layout.isT9 && pageName == "main" && !privateField && dictionary != null

    private fun onChar(text: String) {
        if (t9Active() && text.length == 1 && text[0] in '2'..'9') {
            digits.append(text)
            candidateIndex = 0
            refreshCandidates()
            updateComposing()
            return
        }
        if (t9Active() && text == "1") {
            // '1' on T9 commits current word and inserts punctuation.
            if (isComposing) commitCandidate(addSpace = false)
            sink.commitText(".")
            afterCommit(); return
        }
        finishComposition()
        val out = if (shift != ShiftState.OFF) text.uppercase() else text
        sink.commitText(out)
        afterCommit()
    }

    private fun onBackspace() {
        if (isComposing) {
            digits.deleteCharAt(digits.length - 1)
            candidateIndex = 0
            if (digits.isEmpty()) { candidates = emptyList(); sink.setComposingText(""); sink.finishComposingText() }
            else { refreshCandidates(); updateComposing() }
            listener?.onStateChanged()
        } else {
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
        if (isComposing) updateComposing()
        listener?.onStateChanged()
    }

    private fun refreshCandidates() {
        val d = digits.toString()
        val dict = dictionary ?: return
        val list = ArrayList<String>(dict.lookup(d))
        if (list.isEmpty()) {
            list.addAll(dict.lookupPrefix(d))
            // Always provide something typeable: first letter of every key.
            val fallback = d.map { T9Dictionary.lettersFor(it, language).firstOrNull() ?: it }.joinToString("")
            if (!list.contains(fallback)) list.add(fallback)
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
        sink.commitText(if (addSpace) "$w " else w)
        digits.clear(); candidates = emptyList(); candidateIndex = 0
    }

    private fun finishComposition() {
        if (isComposing) commitCandidate(addSpace = false)
    }

    private fun afterCommit() {
        if (shift == ShiftState.ONCE) shift = ShiftState.OFF
        listener?.onStateChanged()
    }

    companion object { const val DOUBLE_TAP_MS = 350L }
}

