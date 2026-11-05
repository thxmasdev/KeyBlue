package com.keyflow.keyflow.keyboard.views

import android.content.Context
import android.graphics.*
import android.os.Handler
import android.os.Looper
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import com.keyflow.keyflow.keyboard.engine.*
import com.keyflow.keyflow.keyboard.themes.KeyboardTheme
import kotlin.math.max
import kotlin.math.min

/**
 * Lightweight native keyboard surface drawn with Canvas. No Flutter, no network, no allocations in onDraw
 * beyond what Canvas needs. Supports multi-touch, long-press popups and backspace auto-repeat.
 */
class KeyboardView(context: Context) : View(context) {
    private class Cell(val key: Key, val rect: RectF)
    private class Pointer(val id: Int, var cell: Cell?, val downAt: Long) {
        var longFired = false
        var popupIndex = -1
    }

    var engine: KeyboardEngine? = null
    var haptics = true
    var theme: KeyboardTheme = KeyboardTheme()
        set(value) { field = value; loadBackground(); requestLayout(); invalidate() }

    private val dp = resources.displayMetrics.density
    private val sp = resources.displayMetrics.scaledDensity
    private val handler = Handler(Looper.getMainLooper())
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val tmp = RectF()
    private val pointers = HashMap<Int, Pointer>()
    private var cells: List<List<Cell>> = emptyList()
    private var cellsKey = ""
    private var bgBitmap: Bitmap? = null
    private var bgLoadedPath: String? = null
    private val candidateRects = ArrayList<RectF>()

    private val candidateBarPx get() = if (engine?.layout?.isT9 == true) 40 * dp else 0f

    override fun onMeasure(w: Int, h: Int) {
        val rows = engine?.page?.rows?.size ?: 4
        val rowH = theme.keyHeightDp * dp
        val gap = theme.gapDp * dp
        val total = candidateBarPx + rows * (rowH + gap) + gap
        setMeasuredDimension(MeasureSpec.getSize(w), total.toInt())
    }

    override fun onSizeChanged(w: Int, h: Int, ow: Int, oh: Int) { cellsKey = ""; loadBackground() }

    fun refresh() {
        cellsKey = ""
        requestLayout()
        invalidate()
    }

    private fun ensureCells() {
        val e = engine ?: return
        val sig = "${e.layout.id}/${e.pageName}/$width/${theme.keyHeightDp}/${theme.gapDp}/${theme.overrides.hashCode()}"
        if (sig == cellsKey) return
        cellsKey = sig
        val gap = theme.gapDp * dp
        val rowH = theme.keyHeightDp * dp
        var y = candidateBarPx + gap
        cells = e.page.rows.map { row ->
            val totalW = row.keys.sumOf { (theme.overrides[it.id]?.widthScale ?: 1f).times(it.weight).toDouble() }.toFloat()
            val avail = width - gap * (row.keys.size + 1)
            var x = gap
            val out = row.keys.map { k ->
                val w = avail * ((theme.overrides[k.id]?.widthScale ?: 1f) * k.weight) / totalW
                Cell(k, RectF(x, y, x + w, y + rowH)).also { x += w + gap }
            }
            y += rowH + gap
            out
        }
    }

    override fun onDraw(canvas: Canvas) {
        val e = engine ?: return
        ensureCells()
        canvas.drawColor(theme.background)
        bgBitmap?.let { bmp ->
            paint.alpha = (theme.bgImageAlpha * 255).toInt()
            canvas.drawBitmap(bmp, null, RectF(0f, 0f, width.toFloat(), height.toFloat()), paint)
            paint.alpha = 255
            if (theme.bgDim > 0f) canvas.drawColor(Color.argb((theme.bgDim * 255).toInt(), 0, 0, 0))
        }
        if (candidateBarPx > 0f) drawCandidates(canvas, e)
        val radius = theme.radiusDp * dp
        val pressedCells = pointers.values.mapNotNull { it.cell }.toSet()
        for (row in cells) for (c in row) {
            val k = c.key
            val ov = theme.overrides[k.id]
            val isAccent = k.action == KeyAction.ENTER
            var bg = ov?.bg ?: if (isAccent) theme.accent else if (k.special) theme.special else theme.key
            var fg = ov?.fg ?: if (isAccent) theme.accentText else if (k.special) theme.specialText else theme.keyText
            if (k.action == KeyAction.SHIFT && e.shift != ShiftState.OFF) { bg = theme.accent; fg = theme.accentText }
            if (c in pressedCells) bg = lighten(bg)
            paint.style = Paint.Style.FILL
            paint.color = bg
            paint.alpha = (theme.keyAlpha * Color.alpha(bg)).toInt()
            if (theme.shadow) paint.setShadowLayer(3 * dp, 0f, 1.5f * dp, Color.argb(90, 0, 0, 0)) else paint.clearShadowLayer()
            canvas.drawRoundRect(c.rect, radius, radius, paint)
            paint.clearShadowLayer()
            if (theme.borderWidthDp > 0f) {
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = theme.borderWidthDp * dp
                paint.color = theme.borderColor
                canvas.drawRoundRect(c.rect, radius, radius, paint)
            }
            drawLabel(canvas, c, e, fg)
        }
        paint.alpha = 255
        drawPopups(canvas, e)
    }

    private fun drawLabel(canvas: Canvas, c: Cell, e: KeyboardEngine, fg: Int) {
        val k = c.key
        var label = k.label
        if (k.action == KeyAction.SHIFT) label = if (e.shift == ShiftState.LOCK) "⇪" else "⇧"
        else if (k.action == KeyAction.LANGUAGE) label = "🌐 " + e.language.uppercase()
        else if (k.action == KeyAction.CHAR && !e.layout.isT9 && e.shift != ShiftState.OFF) label = label.uppercase()
        if (k.action == KeyAction.SPACE && k.label.isBlank()) label = ""
        textPaint.color = fg
        textPaint.typeface = if (theme.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        val big = k.special && k.action != KeyAction.SPACE
        textPaint.textSize = theme.fontSizeSp * sp * (if (label.length > 2 && big) 0.7f else 1f)
        val subText = e.subLabel(k)
        val hasSub = subText != null
        val cy = c.rect.centerY() - (textPaint.ascent() + textPaint.descent()) / 2 + if (hasSub) -6 * dp else 0f
        canvas.drawText(label, c.rect.centerX(), cy, textPaint)
        if (hasSub) {
            textPaint.textSize = theme.fontSizeSp * sp * 0.5f
            textPaint.alpha = 170
            canvas.drawText(subText!!, c.rect.centerX(), c.rect.bottom - 8 * dp, textPaint)
            textPaint.alpha = 255
        }
    }

    private val modeChipW get() = 64 * dp

    private fun drawCandidates(canvas: Canvas, e: KeyboardEngine) {
        candidateRects.clear()
        val bar = candidateBarPx
        textPaint.typeface = Typeface.DEFAULT
        textPaint.textSize = 16 * sp
        val listW = width - modeChipW
        val list = e.candidates.take(5)
        if (list.isNotEmpty()) {
            val w = listW / list.size
            list.forEachIndexed { i, word ->
                val r = RectF(i * w, 0f, (i + 1) * w, bar)
                candidateRects.add(r)
                textPaint.color = if (i == e.candidateIndex) theme.accent else theme.keyText
                textPaint.isFakeBoldText = i == e.candidateIndex
                canvas.drawText(word, r.centerX(), r.centerY() - (textPaint.ascent() + textPaint.descent()) / 2, textPaint)
            }
        } else {
            textPaint.color = theme.keyText
            textPaint.alpha = 110
            textPaint.textSize = 13 * sp
            val hint = if (e.multiTap) "Modo letras: toca varias veces cada tecla" else "Escribe con las teclas 2-9"
            canvas.drawText(hint, listW / 2, bar / 2 - (textPaint.ascent() + textPaint.descent()) / 2, textPaint)
            textPaint.alpha = 255
        }
        textPaint.isFakeBoldText = false
        // Mode chip: T9 (predictive) / ABC (letter by letter)
        val chip = RectF(width - modeChipW + 6 * dp, 6 * dp, width - 6 * dp, bar - 6 * dp)
        paint.style = Paint.Style.FILL
        paint.color = if (e.multiTap) theme.accent else theme.special
        canvas.drawRoundRect(chip, 10 * dp, 10 * dp, paint)
        textPaint.color = if (e.multiTap) theme.accentText else theme.specialText
        textPaint.textSize = 13 * sp
        textPaint.isFakeBoldText = true
        canvas.drawText(if (e.multiTap) "ABC" else "T9", chip.centerX(), chip.centerY() - (textPaint.ascent() + textPaint.descent()) / 2, textPaint)
        textPaint.isFakeBoldText = false
    }

    private fun drawPopups(canvas: Canvas, e: KeyboardEngine) {
        for (p in pointers.values) {
            val c = p.cell ?: continue
            if (!p.longFired || c.key.popups.length < 2) continue
            val chars = c.key.popups.toList()
            val cw = max(c.rect.width(), 40 * dp)
            val total = cw * chars.size
            val left = (c.rect.centerX() - total / 2).coerceIn(0f, max(0f, width - total))
            val top = c.rect.top - c.rect.height() - 6 * dp
            tmp.set(left, top, left + total, top + c.rect.height())
            paint.color = theme.special; canvas.drawRoundRect(tmp, 12 * dp, 12 * dp, paint)
            chars.forEachIndexed { i, ch ->
                val cell = RectF(left + i * cw, top, left + (i + 1) * cw, top + c.rect.height())
                if (i == p.popupIndex) { paint.color = theme.accent; canvas.drawRoundRect(cell, 12 * dp, 12 * dp, paint) }
                textPaint.color = if (i == p.popupIndex) theme.accentText else theme.specialText
                textPaint.textSize = theme.fontSizeSp * sp
                val s = if (e.shift != ShiftState.OFF) ch.toString().uppercase() else ch.toString()
                canvas.drawText(s, cell.centerX(), cell.centerY() - (textPaint.ascent() + textPaint.descent()) / 2, textPaint)
            }
        }
    }

    // ---- touch ----

    private fun cellAt(x: Float, y: Float): Cell? {
        if (cells.isEmpty()) return null
        val row = cells.firstOrNull { y <= it[0].rect.bottom + theme.gapDp * dp / 2 } ?: cells.last()
        if (y < cells[0][0].rect.top - theme.gapDp * dp) return null
        return row.minByOrNull { c ->
            if (x < c.rect.left) c.rect.left - x else if (x > c.rect.right) x - c.rect.right else 0f
        }
    }

    override fun onTouchEvent(ev: MotionEvent): Boolean {
        val e = engine ?: return false
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                val i = ev.actionIndex
                val x = ev.getX(i); val y = ev.getY(i)
                if (y < candidateBarPx) { handleCandidateTap(x, e); return true }
                val p = Pointer(ev.getPointerId(i), cellAt(x, y), ev.eventTime)
                pointers[p.id] = p
                p.cell?.let { onPress(it, p, e) }
                invalidate()
            }
            MotionEvent.ACTION_MOVE -> {
                for (i in 0 until ev.pointerCount) {
                    val p = pointers[ev.getPointerId(i)] ?: continue
                    val x = ev.getX(i); val y = ev.getY(i)
                    if (p.longFired && p.cell != null && p.cell!!.key.popups.length > 1) {
                        updatePopupIndex(p, x)
                    } else {
                        val nc = cellAt(x, y)
                        if (nc !== p.cell) { cancelRepeat(); p.cell = nc; invalidate() }
                    }
                }
                invalidate()
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                val i = ev.actionIndex
                val p = pointers.remove(ev.getPointerId(i))
                cancelRepeat()
                if (p != null) onRelease(p, e)
                invalidate()
            }
            MotionEvent.ACTION_CANCEL -> { pointers.clear(); cancelRepeat(); invalidate() }
        }
        return true
    }

    private fun handleCandidateTap(x: Float, e: KeyboardEngine) {
        if (x >= width - modeChipW) { e.toggleMultiTap(); tick(); return }
        val idx = candidateRects.indexOfFirst { x >= it.left && x <= it.right }
        if (idx >= 0) { e.pickCandidate(idx); tick() }
    }

    private var repeatRunnable: Runnable? = null
    private var longRunnable: Runnable? = null

    private fun onPress(c: Cell, p: Pointer, e: KeyboardEngine) {
        tick()
        when (c.key.action) {
            KeyAction.BACKSPACE -> {
                e.onKey(c.key); p.longFired = true
                repeatRunnable = object : Runnable {
                    override fun run() { e.onKey(c.key); handler.postDelayed(this, 45) }
                }.also { handler.postDelayed(it, 400) }
            }
            else -> if (c.key.popups.isNotEmpty()) {
                longRunnable = Runnable {
                    if (pointers[p.id] === p && p.cell === c) {
                        p.longFired = true
                        if (c.key.popups.length == 1) {
                            // single alternative (e.g. digit on T9 key): commit immediately
                            e.onPopupChar(c.key.popups); p.cell = null; tick()
                        } else { p.popupIndex = 0; tick() }
                        invalidate()
                    }
                }.also { handler.postDelayed(it, 380) }
            }
        }
    }

    private fun updatePopupIndex(p: Pointer, x: Float) {
        val c = p.cell ?: return
        val n = c.key.popups.length
        val cw = max(c.rect.width(), 40 * dp)
        val left = (c.rect.centerX() - cw * n / 2).coerceIn(0f, max(0f, width - cw * n))
        p.popupIndex = ((x - left) / cw).toInt().coerceIn(0, n - 1)
    }

    private fun onRelease(p: Pointer, e: KeyboardEngine) {
        longRunnable?.let { handler.removeCallbacks(it) }
        val c = p.cell ?: return
        if (c.key.action == KeyAction.BACKSPACE) return // handled on press
        if (p.longFired) {
            if (p.popupIndex >= 0 && c.key.popups.length > 1) {
                val ch = c.key.popups[p.popupIndex].toString()
                e.onPopupChar(if (e.shift != ShiftState.OFF) ch.uppercase() else ch)
            }
            return
        }
        e.onKey(c.key)
    }

    private fun cancelRepeat() {
        repeatRunnable?.let { handler.removeCallbacks(it) }; repeatRunnable = null
        longRunnable?.let { handler.removeCallbacks(it) }
    }

    private fun tick() { if (haptics) performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP) }

    private fun lighten(c: Int): Int {
        val hsv = FloatArray(3); Color.colorToHSV(c, hsv)
        hsv[2] = if (hsv[2] > 0.5f) hsv[2] - 0.15f else min(1f, hsv[2] + 0.2f)
        return Color.HSVToColor(Color.alpha(c), hsv)
    }

    // ---- background image: decoded downsampled, off the main thread, released on detach ----

    private fun loadBackground() {
        val path = theme.bgImagePath
        if (path == null) { bgBitmap = null; bgLoadedPath = null; return }
        if (path == bgLoadedPath && bgBitmap != null) return
        if (width == 0) return
        bgLoadedPath = path
        val targetW = width
        Thread {
            try {
                val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, o)
                var s = 1
                while (o.outWidth / (s * 2) >= targetW) s *= 2
                val bmp = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = s; inPreferredConfig = Bitmap.Config.RGB_565 })
                post { bgBitmap = bmp; invalidate() }
            } catch (t: Throwable) { post { bgBitmap = null } }
        }.start()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        cancelRepeat()
        bgBitmap = null; bgLoadedPath = null
    }
}

