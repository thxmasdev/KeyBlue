package com.keyflow.keyflow.keyboard

import com.keyflow.keyflow.keyboard.engine.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.io.File

class FakeSink : InputSink {
    val text = StringBuilder()
    var composing = ""
    var enters = 0
    override fun commitText(text: String) { this.text.append(composing.let { "" }).append(text); composing = "" }
    override fun setComposingText(text: String) { composing = text }
    override fun finishComposingText() { text.append(composing); composing = "" }
    override fun deleteBackward() { if (text.isNotEmpty()) text.deleteCharAt(text.length - 1) }
    override fun performEnter() { enters++ }
    fun shown() = text.toString() + composing
}

class KeyboardEngineTest {
    private val dir = File("src/main/assets/keyflow")
    private lateinit var shared: Map<String, KeyPage>
    private lateinit var dict: T9Dictionary

    private fun layout(id: String) = LayoutParser.parse(File(dir, "layouts/$id.json").readText(), shared)
    private fun key(l: KeyboardLayout, id: String, page: String = "main") =
        l.pages.getValue(page).rows.flatMap { it.keys }.first { it.id == id }

    @Before fun setup() {
        shared = LayoutParser.parsePages(File(dir, "layouts/_symbols.json").readText())
        dict = T9Dictionary(File(dir, "words_en.txt").readLines())
    }

    @Test fun allBundledLayoutsParse() {
        for (f in File(dir, "layouts").listFiles()!!.filter { !it.name.startsWith("_") }) {
            val l = LayoutParser.parse(f.readText(), shared)
            assertTrue(l.pages.containsKey("main"))
        }
    }

    @Test fun rejectsUnknownSchemaAndActions() {
        assertThrows(LayoutParser.InvalidLayoutException::class.java) { LayoutParser.parse("""{"schema":99,"id":"x","pages":{}}""") }
        assertThrows(LayoutParser.InvalidLayoutException::class.java) {
            LayoutParser.parse("""{"schema":1,"id":"x","pages":{"main":[["@exec"]]}}""")
        }
    }

    @Test fun qwertyTypesAndDeletes() {
        val s = FakeSink(); val l = layout("qwerty"); val e = KeyboardEngine(l, s)
        "hi".forEach { e.onKey(key(l, it.toString())) }
        assertEquals("hi", s.shown())
        e.onKey(key(l, "@back")); assertEquals("h", s.shown())
        e.onKey(key(l, "@space")); assertEquals("h ", s.shown())
        e.onKey(key(l, "@enter")); assertEquals(1, s.enters)
    }

    @Test fun shiftOnceThenLockThenOff() {
        val s = FakeSink(); val l = layout("qwerty"); val e = KeyboardEngine(l, s)
        val shift = key(l, "@shift")
        e.onKey(shift, 1000); assertEquals(ShiftState.ONCE, e.shift)
        e.onKey(key(l, "a")); e.onKey(key(l, "b"))
        assertEquals("Ab", s.shown()); assertEquals(ShiftState.OFF, e.shift)
        e.onKey(shift, 5000); e.onKey(shift, 5100); assertEquals(ShiftState.LOCK, e.shift)
        e.onKey(key(l, "c")); e.onKey(key(l, "d")); assertEquals("AbCD", s.shown())
        e.onKey(shift, 9000); assertEquals(ShiftState.OFF, e.shift)
    }

    @Test fun symbolPageSwitch() {
        val s = FakeSink(); val l = layout("qwerty"); val e = KeyboardEngine(l, s)
        e.onKey(key(l, "@page:symbols")); assertEquals("symbols", e.pageName)
        e.onKey(key(l, "@", "symbols")); assertEquals("@", s.shown())
        e.onKey(key(l, "@page:main", "symbols")); assertEquals("main", e.pageName)
    }

    @Test fun t9PredictsWordsAndCycles() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        listOf("4", "6", "6", "3").forEach { e.onKey(key(l, it)) } // good / home / gone / hood
        assertEquals("good", s.shown())
        e.onKey(key(l, "@t9next")); assertEquals("home", s.shown())
        e.onKey(key(l, "@space"))
        assertEquals("home ", s.shown()); assertFalse(e.isComposing)
    }

    @Test fun t9BackspaceEditsDigitsNotText() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        listOf("4", "6").forEach { e.onKey(key(l, it)) }
        e.onKey(key(l, "@back")); assertTrue(e.isComposing)
        e.onKey(key(l, "@back")); assertFalse(e.isComposing); assertEquals("", s.shown())
    }

    @Test fun t9UnknownWordFallsBackToLetters() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        listOf("9", "9", "9", "9").forEach { e.onKey(key(l, it)) }
        assertEquals("wwww", s.shown())
    }

    @Test fun privateFieldDisablesPrediction() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        e.privateField = true
        e.onKey(key(l, "4")); e.onKey(key(l, "6"))
        assertEquals("46", s.shown()); assertFalse(e.isComposing)
    }

    @Test fun numericLayoutTypesDigits() {
        val s = FakeSink(); val l = layout("numeric"); val e = KeyboardEngine(l, s)
        "2024".forEach { e.onKey(key(l, it.toString())) }
        assertEquals("2024", s.shown())
    }

    @Test fun switchImeNotifiesListener() {
        var requested = 0
        val l = layout("qwerty")
        val e = KeyboardEngine(l, FakeSink(), null, object : EngineListener {
            override fun onStateChanged() {}
            override fun onRequestNextLayout() {}
            override fun onRequestSwitchIme(showPicker: Boolean) { requested++ }
        })
        e.onKey(key(l, "@ime")); assertEquals(1, requested)
    }

    @Test fun spanishT9TypesAccentedWordsAndEnye() {
        val es = T9Dictionary(File(dir, "words_es.txt").readLines(), "es")
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, es)
        "4652".forEach { e.onKey(key(l, it.toString())) }       // hola
        assertEquals("hola", s.shown())
        e.onKey(key(l, "@space"))
        "3782".forEach { e.onKey(key(l, it.toString())) }       // esta / está share digits (á shares key 2)
        assertEquals("hola esta", s.shown())
        e.onKey(key(l, "@t9next"))
        assertEquals("hola está", s.shown())
        e.onKey(key(l, "@space"))
        "626262".forEach { e.onKey(key(l, it.toString())) }     // mañana (ñ shares key 6)
        assertTrue(s.shown().endsWith("mañana"))
    }

    @Test fun t9SubLabelsFollowLanguage() {
        val l = layout("t9")
        val es = KeyboardEngine(l, FakeSink(), T9Dictionary(listOf("hola"), "es"))
        val en = KeyboardEngine(l, FakeSink(), T9Dictionary(listOf("hello"), "en"))
        assertEquals("MNÑO", es.subLabel(key(l, "6")))
        assertEquals("MNO", en.subLabel(key(l, "6")))
        es.setDictionary(T9Dictionary(listOf("hello"), "en"))
        assertEquals("MNO", es.subLabel(key(l, "6")))
    }

    @Test fun accentedLettersMapToBaseKey() {
        assertEquals("2", T9Dictionary.digitsFor("á")?.take(1))
        assertEquals("6", T9Dictionary.digitFor('ñ').toString())
        assertEquals("8", T9Dictionary.digitFor('ú').toString())
        assertNull(T9Dictionary.digitsFor("a b"))
    }

    @Test fun pickCandidateCommitsWithSpace() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        listOf("4", "6", "6", "3").forEach { e.onKey(key(l, it)) }
        e.pickCandidate(1)
        assertEquals(e.candidates.size, 0)
        assertTrue(s.shown().endsWith(" "))
    }

    @Test fun keyOneCyclesPunctuation() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        e.onKey(key(l, "1"))
        assertEquals(".", s.shown())
        e.onKey(key(l, "1"))
        assertEquals(",", s.shown())
        e.onKey(key(l, "@space"))
        assertEquals(", ", s.shown())
    }

    @Test fun longPressOnDigitOutputsNumber() {
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, dict)
        e.onPopupChar("5")
        assertEquals("5", s.shown())
    }

    @Test fun multiTapAllowsLetterByLetterAndLearnsWord() {
        val personal = PersonalDictionary(null)
        val testDict = T9Dictionary(listOf("hola"), "es", personal)
        val s = FakeSink(); val l = layout("t9"); val e = KeyboardEngine(l, s, testDict)
        e.toggleMultiTap()
        assertTrue(e.multiTap)
        // Escribir "sol": 7(pqrS) 4 veces = s; 6(mnñO) 4 veces = o; 5(jkL) 3 veces = l
        val now = 1000L
        e.onKey(key(l, "7"), now)
        e.onKey(key(l, "7"), now + 100)
        e.onKey(key(l, "7"), now + 200)
        e.onKey(key(l, "7"), now + 300) // s
        e.onKey(key(l, "6"), now + 1500)
        e.onKey(key(l, "6"), now + 1600)
        e.onKey(key(l, "6"), now + 1700)
        e.onKey(key(l, "6"), now + 1800) // o
        e.onKey(key(l, "5"), now + 3000)
        e.onKey(key(l, "5"), now + 3100)
        e.onKey(key(l, "5"), now + 3200) // l
        e.onKey(key(l, "@space"), now + 4000)
        assertEquals("sol ", s.shown())
        // Verifica que la palabra fue aprendida en el diccionario personal
        assertTrue(personal.contains("sol"))
    }

    @Test fun languageKeyNotifiesListener() {
        var requested = 0
        val l = layout("t9")
        val e = KeyboardEngine(l, FakeSink(), dict, object : EngineListener {
            override fun onStateChanged() {}
            override fun onRequestNextLayout() {}
            override fun onRequestNextLanguage() { requested++ }
        })
        e.onKey(key(l, "@lang")); assertEquals(1, requested)
    }
}

