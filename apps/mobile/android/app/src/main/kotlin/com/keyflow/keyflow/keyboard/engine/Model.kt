package com.keyflow.keyflow.keyboard.engine

/** Actions a key can trigger. Pure logic: nothing here knows about colors or drawing. */
enum class KeyAction {
    CHAR,        // commits [Key.output]
    SHIFT,
    BACKSPACE,
    ENTER,
    SPACE,
    PAGE,        // switches to page named [Key.arg]
    NEXT_LAYOUT, // cycles to next layout (language / distribution switch)
    T9_NEXT,     // cycles T9 candidates
    LANGUAGE,    // switches the typing language (es / en)
    NONE
}

data class Key(
    val id: String,
    val label: String,
    val output: String?,
    val action: KeyAction,
    val weight: Float = 1f,
    val popups: String = "",
    val sub: String? = null,
    val arg: String? = null,
    val special: Boolean = false,
)

data class KeyRow(val keys: List<Key>)

data class KeyPage(val name: String, val rows: List<KeyRow>)

data class KeyboardLayout(
    val schema: Int,
    val id: String,
    val name: String,
    val mode: String,          // "alpha" | "t9" | "numeric"
    val languages: List<String>,
    val pages: Map<String, KeyPage>,
) {
    val mainPage: KeyPage get() = pages["main"] ?: pages.values.first()
    val isT9: Boolean get() = mode == "t9"
}

