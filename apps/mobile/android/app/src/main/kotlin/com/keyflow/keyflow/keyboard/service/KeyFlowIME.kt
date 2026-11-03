package com.keyflow.keyflow.keyboard.service

import android.inputmethodservice.InputMethodService
import android.text.InputType
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import com.keyflow.keyflow.keyboard.bridge.ConfigStore
import com.keyflow.keyflow.keyboard.engine.*
import com.keyflow.keyflow.keyboard.layouts.LayoutRepository
import com.keyflow.keyflow.keyboard.views.KeyboardView

/**
 * The real Android keyboard. Pure native: no FlutterEngine, no network, no logging of typed content.
 */
class KeyFlowIME : InputMethodService(), EngineListener {
    private lateinit var repo: LayoutRepository
    private lateinit var store: ConfigStore
    private var view: KeyboardView? = null
    private var engine: KeyboardEngine? = null
    private var config: ConfigStore.Config? = null
    private var currentIndexInCycle = 0
    private var overrideLayoutId: String? = null

    private val sink = object : InputSink {
        override fun commitText(text: String) { currentInputConnection?.commitText(text, 1) }
        override fun setComposingText(text: String) { currentInputConnection?.setComposingText(text, 1) }
        override fun finishComposingText() { currentInputConnection?.finishComposingText() }
        override fun deleteBackward() {
            val ic = currentInputConnection ?: return
            val selected = ic.getSelectedText(0)
            if (!selected.isNullOrEmpty()) ic.commitText("", 1)
            else if (!ic.deleteSurroundingTextInCodePoints(1, 0)) sendKey(KeyEvent.KEYCODE_DEL)
        }
        override fun performEnter() { handleEnter() }
    }

    override fun onCreate() {
        super.onCreate()
        repo = LayoutRepository(this)
        store = ConfigStore(this)
    }

    override fun onCreateInputView(): View {
        val v = KeyboardView(this)
        view = v
        applyConfig(force = true)
        return v
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        overrideLayoutId = null
        applyConfig(force = false)
        val e = engine ?: return
        val cls = info.inputType and InputType.TYPE_MASK_CLASS
        val variation = info.inputType and InputType.TYPE_MASK_VARIATION
        val password = cls == InputType.TYPE_CLASS_TEXT && (
            variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
            ) || cls == InputType.TYPE_CLASS_NUMBER && variation == InputType.TYPE_NUMBER_VARIATION_PASSWORD
        e.privateField = password || (info.imeOptions and EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING) != 0
        // Numeric fields get the numeric layout regardless of the user's choice.
        if (cls == InputType.TYPE_CLASS_NUMBER || cls == InputType.TYPE_CLASS_PHONE || cls == InputType.TYPE_CLASS_DATETIME) {
            repo.all()["numeric"]?.let { overrideLayoutId = "numeric"; e.setLayout(it) }
        }
        val caps = cls == InputType.TYPE_CLASS_TEXT && (info.inputType and InputType.TYPE_TEXT_FLAG_CAP_SENTENCES) != 0 &&
            currentInputConnection?.getCursorCapsMode(info.inputType) != 0
        e.onStartInput(caps)
        view?.refresh()
    }

    override fun onFinishInput() {
        engine?.onFinishInput()
        super.onFinishInput()
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        engine?.onFinishInput()
        super.onFinishInputView(finishingInput)
    }

    override fun onDestroy() {
        view = null; engine = null
        super.onDestroy()
    }

    private fun applyConfig(force: Boolean) {
        val newCfg = store.load()
        if (!force && newCfg.raw == config?.raw && engine != null) return
        config = newCfg
        val layout = repo.get(newCfg.layoutId) ?: return
        currentIndexInCycle = newCfg.cycle.indexOf(layout.id).coerceAtLeast(0)
        val existing = engine
        val dict = repo.dictionary(newCfg.language)
        if (existing == null) {
            engine = KeyboardEngine(layout, sink, dict, this)
        } else {
            if (existing.language != dict.language) existing.setDictionary(dict)
            if (existing.layout.id != layout.id) existing.setLayout(layout)
        }
        view?.let { v ->
            v.engine = engine
            v.haptics = newCfg.haptics
            v.theme = newCfg.theme
            v.refresh()
        }
    }

    private fun handleEnter() {
        val ic = currentInputConnection ?: return
        val info = currentInputEditorInfo
        val multiLine = info != null && (info.inputType and InputType.TYPE_TEXT_FLAG_MULTI_LINE) != 0
        val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
        val noEnterAction = info != null && (info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) != 0
        val hasAction = action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED
        if (hasAction && !noEnterAction && !multiLine) { ic.performEditorAction(action); return }
        sendKey(KeyEvent.KEYCODE_ENTER)
    }

    private fun sendKey(code: Int) {
        val ic = currentInputConnection ?: return
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, code))
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, code))
    }

    // ---- EngineListener ----
    override fun onStateChanged() { view?.invalidate() }

    override fun onRequestNextLayout() {
        val cfg = config ?: return
        val cycle = cfg.cycle.filter { repo.all().containsKey(it) }
        if (cycle.isEmpty()) return
        val currentId = engine?.layout?.id
        val next = cycle[((cycle.indexOf(currentId)) + 1) % cycle.size]
        repo.all()[next]?.let { engine?.setLayout(it) }
        view?.refresh()
    }
}
