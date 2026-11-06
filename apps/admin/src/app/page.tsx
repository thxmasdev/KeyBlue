'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  Download,
  Shield,
  Zap,
  Sliders,
  Sparkles,
  Smartphone,
  Lock,
  CheckCircle2,
  ChevronRight,
  ArrowRight,
  Laptop,
  Layers,
  Palette,
  Terminal,
} from 'lucide-react';

const themesPreview = [
  {
    id: 'midnight',
    name: 'Midnight Black',
    bg: '#12161C',
    keyBg: '#262D37',
    text: '#FFFFFF',
    accent: '#3D7BFF',
    accentText: '#FFFFFF',
    category: 'Oscuro',
  },
  {
    id: 'cyber_neon',
    name: 'Cyber Neon',
    bg: '#0A0E1A',
    keyBg: '#141E33',
    text: '#00F5FF',
    accent: '#00F5FF',
    accentText: '#0A0E1A',
    category: 'Gaming PRO',
  },
  {
    id: 'cyberpunk',
    name: 'Cyberpunk 2077',
    bg: '#111111',
    keyBg: '#222222',
    text: '#FFF000',
    accent: '#FFF000',
    accentText: '#111111',
    category: 'Gaming PRO',
  },
  {
    id: 'sunset',
    name: 'Sunset Glow',
    bg: '#231226',
    keyBg: '#3E1C3F',
    text: '#FFD1BA',
    accent: '#FF6B6B',
    accentText: '#FFFFFF',
    category: 'Colorido PRO',
  },
  {
    id: 'amoled_black',
    name: 'AMOLED Pure',
    bg: '#000000',
    keyBg: '#121212',
    text: '#F0F0F0',
    accent: '#4A80FF',
    accentText: '#FFFFFF',
    category: 'OLED Batería',
  },
];

const GITHUB_REPO_URL = 'https://github.com/thxmasdev/KeyBlue';
const GITHUB_LATEST_RELEASE_URL = 'https://github.com/thxmasdev/KeyBlue/releases/latest';
const CURRENT_APP_VERSION = 'v0.1.3';

// Simulación de diccionario T9 interactivo para la landing web
const T9_LETTERS: Record<string, string> = {
  '2': 'abc', '3': 'def', '4': 'ghi', '5': 'jkl', '6': 'mnño', '7': 'pqrs', '8': 'tuv', '9': 'wxyz',
};
const T9_DIGIT_MAP: Record<string, string> = {};
Object.entries(T9_LETTERS).forEach(([d, ls]) => {
  ls.split('').forEach((char) => { T9_DIGIT_MAP[char] = d; });
});
const T9_ACCENT_NORM: Record<string, string> = {
  á: 'a', é: 'e', í: 'i', ó: 'o', ú: 'u', ü: 'u',
};

const T9_DICTIONARY = [
  'hola', 'esta', 'está', 'que', 'qué', 'como', 'cómo', 'para', 'con', 'una', 'los', 'las', 'por', 'pero', 'muy',
  'bien', 'gracias', 'buenos', 'dias', 'días', 'tardes', 'noches', 'amigo', 'casa', 'mañana', 'hoy', 'ayer',
  'teclado', 'rápido', 'rapido', 'nuevo', 'nada', 'todo', 'vamos', 'quiero', 'tiempo', 'mundo', 'amor', 'vida',
  'good', 'home', 'gone', 'hood', 'hello', 'the', 'and', 'you', 'are', 'how', 'thanks', 'keyboard', 'fast',
];

function getT9Digits(word: string): string {
  return word
    .toLowerCase()
    .split('')
    .map((c) => T9_DIGIT_MAP[T9_ACCENT_NORM[c] ?? c] ?? '')
    .join('');
}

const T9_INDEX: Record<string, string[]> = {};
T9_DICTIONARY.forEach((w) => {
  const d = getT9Digits(w);
  if (!T9_INDEX[d]) T9_INDEX[d] = [];
  if (!T9_INDEX[d].includes(w)) T9_INDEX[d].push(w);
});

function t9Candidates(seq: string): string[] {
  if (!seq) return [];
  const exact = T9_INDEX[seq] ?? [];
  if (exact.length > 0) return exact;
  const prefix = Object.keys(T9_INDEX)
    .filter((k) => k.startsWith(seq))
    .flatMap((k) => T9_INDEX[k])
    .slice(0, 4);
  const fallback = seq
    .split('')
    .map((d) => T9_LETTERS[d]?.[0] ?? d)
    .join('');
  return prefix.length > 0 ? prefix : [fallback];
}

export default function LandingPage() {
  const [activeTheme, setActiveTheme] = useState(themesPreview[0]);
  const [activeMode, setActiveMode] = useState<'qwerty' | 't9'>('qwerty');
  const [typedText, setTypedText] = useState('¡Escribe aquí para probar KeyBlue en vivo! ');
  const [t9Seq, setT9Seq] = useState('');
  const [t9Idx, setT9Idx] = useState(0);
  const t9Cands = t9Candidates(t9Seq);
  const t9Word = t9Cands.length ? t9Cands[t9Idx % t9Cands.length] : '';
  const t9Commit = (suffix = '') => {
    if (t9Seq) setTypedText((p) => p + t9Word + suffix);
    else if (suffix) setTypedText((p) => p + suffix);
    setT9Seq('');
    setT9Idx(0);
  };
  const t9Press = (k: string) => {
    if (/^[2-9]$/.test(k)) {
      setT9Seq((s) => s + k);
      setT9Idx(0);
    } else if (k === '*') {
      if (t9Cands.length) setT9Idx((i) => (i + 1) % t9Cands.length);
    } else if (k === '0' || k === 'space' || k === 'enter') t9Commit(' ');
    else if (k === '1') t9Commit('.');
    else if (k === 'back') {
      if (t9Seq) {
        setT9Seq((s) => s.slice(0, -1));
        setT9Idx(0);
      } else setTypedText((p) => p.slice(0, -1));
    }
  };

  return (
    <div className="min-h-screen bg-[#07090E] text-slate-100 selection:bg-primary selection:text-white relative overflow-hidden">
      {/* Luces difusas de fondo */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[900px] h-[450px] bg-gradient-to-b from-primary/20 via-cyan-500/10 to-transparent blur-[140px] pointer-events-none -z-10" />
      <div className="absolute top-[800px] right-0 w-[500px] h-[500px] bg-purple-600/10 blur-[150px] pointer-events-none -z-10" />

      {/* NAVBAR */}
      <header className="sticky top-0 z-40 backdrop-blur-xl bg-[#07090E]/80 border-b border-slate-800/80">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src="/keyblue_logo.png" alt="KeyBlue Logo" className="w-10 h-10 rounded-2xl object-cover shadow-lg shadow-primary/30 border border-slate-700/60" />
            <div>
              <span className="font-black text-xl tracking-tight text-white">KeyBlue</span>
              <span className="text-[10px] font-bold uppercase tracking-widest text-cyan-400 ml-2 px-2 py-0.5 rounded-full bg-cyan-400/10 border border-cyan-400/20">
                Android IME
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm font-semibold text-slate-400">
            <a href="#features" className="hover:text-white transition-colors">
              Características
            </a>
            <a href="#teclados" className="hover:text-white transition-colors">
              Distribuciones
            </a>
            <a href="#temas" className="hover:text-white transition-colors">
              15 Temas
            </a>
            <a href="#seguridad" className="hover:text-white transition-colors">
              Privacidad
            </a>
            <a href="#planes" className="hover:text-white transition-colors">
              Licencias PRO
            </a>
          </nav>

          <div className="flex items-center gap-3">
            <Link
              href="/login"
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold text-slate-300 hover:text-white bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all shadow-sm"
            >
              <Lock className="w-3.5 h-3.5 text-primary" />
              Panel Admin
            </Link>
            <a
              href={GITHUB_LATEST_RELEASE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold bg-primary hover:bg-primary-hover text-white shadow-md shadow-primary/25 transition-all"
            >
              <Download className="w-3.5 h-3.5" />
              Descargar APK ({CURRENT_APP_VERSION})
            </a>
          </div>
        </div>
      </header>

      {/* HERO SECTION */}
      <section className="pt-20 pb-28 px-6 max-w-7xl mx-auto text-center space-y-8">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-slate-900/90 border border-slate-800 text-xs font-semibold text-slate-300 shadow-xl backdrop-blur-md">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>MOTOR NATIVO ANDROID 100% OFFLINE</span>
          <span className="text-slate-600">|</span>
          <a
            href={GITHUB_LATEST_RELEASE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-cyan-400 hover:underline flex items-center gap-1"
          >
            {CURRENT_APP_VERSION} Disponible
            <ChevronRight className="w-3 h-3" />
          </a>
        </div>

        <div className="max-w-4xl mx-auto space-y-4">
          <h1 className="text-4xl sm:text-6xl md:text-7xl font-black text-white tracking-tight leading-[1.08]">
            Tu teclado Android. <br />
            <span className="bg-gradient-to-r from-primary via-cyan-400 to-indigo-300 bg-clip-text text-transparent">
              Rediseñado al nivel del metal.
            </span>
          </h1>
          <p className="text-base sm:text-xl text-slate-400 max-w-2xl mx-auto font-normal leading-relaxed pt-2">
            La velocidad y ligereza de un motor nativo en Kotlin con dibujo 2D directo, combinada con
            la personalización más avanzada: QWERTY, T9 en español con predicción, 15 temas de autor y cero telemetría.
          </p>
        </div>

        <div className="flex flex-wrap items-center justify-center gap-4 pt-4">
          <a
            href="#mockup"
            className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-gradient-to-r from-primary to-indigo-600 hover:opacity-95 text-white font-extrabold text-sm shadow-xl shadow-primary/30 transition-all hover:scale-[1.02]"
          >
            <Smartphone className="w-5 h-5" />
            Probar Teclado Interactivo
          </a>
          <a
            href="#features"
            className="flex items-center gap-2 px-7 py-4 rounded-2xl bg-slate-900/80 hover:bg-slate-800/80 border border-slate-800 text-slate-300 font-bold text-sm transition-all"
          >
            Ver Especificaciones
            <ChevronRight className="w-4 h-4 text-slate-500" />
          </a>
        </div>

        {/* SHOWCASE INTERACTIVO (SMARTPHONE MOCKUP CON TECLADO VIVO) */}
        <div id="mockup" className="pt-12 max-w-4xl mx-auto">
          <div className="p-4 sm:p-7 rounded-[40px] bg-gradient-to-b from-slate-800/60 to-slate-950/80 border border-slate-800/90 shadow-2xl backdrop-blur-2xl">
            {/* Barra superior de controles del showcase */}
            <div className="flex flex-wrap items-center justify-between gap-4 pb-6 border-b border-slate-800/60">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                  Cambiar Tema en Vivo:
                </span>
                <div className="flex items-center gap-1.5 bg-slate-950 p-1 rounded-xl border border-slate-800">
                  {themesPreview.map((t) => (
                    <button
                      key={t.id}
                      onClick={() => setActiveTheme(t)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                        activeTheme.id === t.id
                          ? 'bg-slate-800 text-white shadow-sm'
                          : 'text-slate-400 hover:text-white'
                      }`}
                    >
                      {t.name}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">Modo:</span>
                <div className="flex items-center gap-1 bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs font-bold">
                  <button
                    onClick={() => setActiveMode('qwerty')}
                    className={`px-3 py-1 rounded-lg transition-all ${
                      activeMode === 'qwerty' ? 'bg-primary text-white' : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    QWERTY
                  </button>
                  <button
                    onClick={() => setActiveMode('t9')}
                    className={`px-3 py-1 rounded-lg transition-all ${
                      activeMode === 't9' ? 'bg-primary text-white' : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    T9 Clásico
                  </button>
                </div>
              </div>
            </div>

            {/* Pantalla del teléfono */}
            <div className="mt-6 rounded-3xl bg-[#090D16] border border-slate-800 p-6 sm:p-8 space-y-6 text-left shadow-inner">
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs text-slate-500">
                  <span>Aplicación de Notas (Android)</span>
                  <span className="text-emerald-400 font-mono flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                    KeyBlue IME Conectado
                  </span>
                </div>
                <input
                  type="text"
                  value={typedText}
                  onChange={(e) => setTypedText(e.target.value)}
                  className="w-full px-4 py-3 bg-[#111624] border border-slate-700/80 rounded-xl text-base text-white font-medium focus:outline-none focus:border-primary"
                />
              </div>

              {/* RENDERIZADO VISUAL DEL TECLADO CON EL TEMA ACTIVO */}
              <div
                style={{ backgroundColor: activeTheme.bg }}
                className="p-3 sm:p-5 rounded-2xl transition-all duration-300 shadow-2xl border border-white/5 space-y-2"
              >
                {activeMode === 'qwerty' ? (
                  <>
                    {/* Fila 1 */}
                    <div className="grid grid-cols-10 gap-1.5">
                      {'qwertyuiop'.split('').map((char) => (
                        <button
                          key={char}
                          onClick={() => setTypedText((prev) => prev + char)}
                          style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                          className="h-12 rounded-lg font-bold text-base flex items-center justify-center hover:opacity-85 active:scale-95 transition-all shadow-sm"
                        >
                          {char}
                        </button>
                      ))}
                    </div>

                    {/* Fila 2 */}
                    <div className="grid grid-cols-10 gap-1.5 px-3">
                      {'asdfghjklñ'.split('').map((char) => (
                        <button
                          key={char}
                          onClick={() => setTypedText((prev) => prev + char)}
                          style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                          className="h-12 rounded-lg font-bold text-base flex items-center justify-center hover:opacity-85 active:scale-95 transition-all shadow-sm"
                        >
                          {char}
                        </button>
                      ))}
                    </div>

                    {/* Fila 3 */}
                    <div className="flex gap-1.5">
                      <button
                        style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                        className="w-14 h-12 rounded-lg font-bold text-sm flex items-center justify-center"
                      >
                        ⇧
                      </button>
                      <div className="flex-1 grid grid-cols-7 gap-1.5">
                        {'zxcvbnm'.split('').map((char) => (
                          <button
                            key={char}
                            onClick={() => setTypedText((prev) => prev + char)}
                            style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                            className="h-12 rounded-lg font-bold text-base flex items-center justify-center hover:opacity-85 active:scale-95 transition-all shadow-sm"
                          >
                            {char}
                          </button>
                        ))}
                      </div>
                      <button
                        onClick={() => setTypedText((prev) => prev.slice(0, -1))}
                        style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                        className="w-14 h-12 rounded-lg font-bold text-base flex items-center justify-center hover:opacity-85 active:scale-95 transition-all shadow-sm"
                      >
                        ⌫
                      </button>
                    </div>

                    {/* Fila 4 */}
                    <div className="flex gap-1.5">
                      <button
                        style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                        className="px-4 h-12 rounded-lg text-xs font-bold"
                      >
                        ?123
                      </button>
                      <button
                        style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                        className="w-12 h-12 rounded-lg text-base"
                      >
                        ⌨
                      </button>
                      <button
                        onClick={() => setTypedText((prev) => prev + ' ')}
                        style={{ backgroundColor: activeTheme.keyBg, color: activeTheme.text }}
                        className="flex-1 h-12 rounded-lg text-xs font-semibold uppercase tracking-wider"
                      >
                        KeyBlue Space
                      </button>
                      <button
                        style={{
                          backgroundColor: activeTheme.accent,
                          color: activeTheme.accentText,
                        }}
                        className="px-6 h-12 rounded-lg font-bold text-base shadow-md"
                      >
                        ⏎
                      </button>
                    </div>
                  </>
                ) : (
                  /* Teclado T9 Clásico */
                  <div className="grid grid-cols-4 gap-2 max-w-md mx-auto">
                    {[
                      { num: '1', sub: '.,?!' },
                      { num: '2', sub: 'ABC' },
                      { num: '3', sub: 'DEF' },
                      { num: '⌫', sub: 'Borrar', action: 'back' },
                      { num: '4', sub: 'GHI' },
                      { num: '5', sub: 'JKL' },
                      { num: '6', sub: 'MNÑO' },
                      { num: '⇧', sub: 'Shift', action: 'shift' },
                      { num: '7', sub: 'PQRS' },
                      { num: '8', sub: 'TUV' },
                      { num: '9', sub: 'WXYZ' },
                      { num: '⏎', sub: 'Enter', action: 'enter', isAccent: true },
                      { num: '123', sub: 'Símbolos' },
                      { num: '0', sub: 'Espacio', action: 'space' },
                      { num: '*', sub: 'T9 Next' },
                      { num: '⌨', sub: 'Teclado', action: 'ime' },
                    ].map((k) => (
                      <button
                        key={k.num}
                        onClick={() => {
                          if (k.action === 'back') setTypedText((p) => p.slice(0, -1));
                          else if (k.action === 'space') setTypedText((p) => p + ' ');
                          else setTypedText((p) => p + k.num);
                        }}
                        style={{
                          backgroundColor: k.isAccent ? activeTheme.accent : activeTheme.keyBg,
                          color: k.isAccent ? activeTheme.accentText : activeTheme.text,
                        }}
                        className="h-16 rounded-xl flex flex-col items-center justify-center hover:opacity-85 active:scale-95 transition-all shadow-sm"
                      >
                        <span className="font-extrabold text-lg leading-none">{k.num}</span>
                        <span className="text-[10px] font-semibold opacity-70 mt-1">{k.sub}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CARACTERÍSTICAS PRINCIPALES */}
      <section id="features" className="py-24 px-6 max-w-7xl mx-auto border-t border-slate-800/80">
        <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
          <h2 className="text-xs font-bold text-cyan-400 uppercase tracking-widest">
            Ingeniería sin concesiones
          </h2>
          <p className="text-3xl sm:text-5xl font-black text-white tracking-tight">
            Diseñado para escribir más rápido y con total tranquilidad.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="p-8 rounded-3xl bg-[#0E131F] border border-slate-800 hover:border-slate-700 transition-all space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-400">
              <Zap className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Motor Nativo Canvas 2D</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              No cargamos un motor Flutter pesado en cada tipeo. KeyBlue usa un servicio nativo en Kotlin
              con dibujo acelerado por hardware para una apertura menor a 50ms y cero lag táctil.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-[#0E131F] border border-slate-800 hover:border-slate-700 transition-all space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center text-primary">
              <Shield className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Privacidad Inviolable</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Cero keylogging. Cero peticiones de red mientras escribes. Al detectar campos de contraseñas,
              la composición predictiva se apaga inmediatamente para salvaguardar tu seguridad.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-[#0E131F] border border-slate-800 hover:border-slate-700 transition-all space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400">
              <Sliders className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Personalización Tecla a Tecla</h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Modifica no solo colores generales, sino el fondo, texto y tamaño de teclas individuales tocándolas
              en el editor en tiempo real. Guarda tus diseños en perfiles ilimitados.
            </p>
          </div>
        </div>
      </section>

      {/* SECCIÓN PLANES / COMPARATIVA */}
      <section id="planes" className="py-24 px-6 max-w-7xl mx-auto border-t border-slate-800/80">
        <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
          <h2 className="text-xs font-bold text-primary uppercase tracking-widest">Modelo de Licencias</h2>
          <p className="text-3xl sm:text-5xl font-black text-white tracking-tight">
            Transparente y sin suscripciones forzadas.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {/* FREE */}
          <div className="p-8 rounded-3xl bg-[#0E131F] border border-slate-800 flex flex-col justify-between space-y-6">
            <div className="space-y-4">
              <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">Plan Base</span>
              <h3 className="text-3xl font-extrabold text-white">Gratuito / Free</h3>
              <p className="text-sm text-slate-400">Funciones esenciales para el uso diario sin costo.</p>
              <ul className="space-y-3 pt-4 text-sm text-slate-300">
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  Distribuciones QWERTY, T9 y Numérico
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  Temas base esenciales (Midnight, AMOLED, Minimal)
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  Hasta 3 perfiles guardados
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  Privacidad estricta 100% offline
                </li>
              </ul>
            </div>
            <a
              href={GITHUB_LATEST_RELEASE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full py-3.5 rounded-xl bg-slate-800 hover:bg-slate-700 font-bold text-sm text-white transition-all text-center flex items-center justify-center gap-2"
            >
              <Download className="w-4 h-4 text-primary" />
              Descargar APK {CURRENT_APP_VERSION}
            </a>
          </div>

          {/* PRO */}
          <div className="p-8 rounded-3xl bg-gradient-to-b from-[#161D2F] to-[#0E131F] border-2 border-primary shadow-2xl shadow-primary/20 flex flex-col justify-between space-y-6 relative">
            <div className="absolute -top-3 right-8 px-3 py-1 rounded-full bg-primary text-white font-extrabold text-[11px] uppercase tracking-wider">
              Recomendado
            </div>
            <div className="space-y-4">
              <span className="text-xs font-bold text-cyan-400 uppercase tracking-widest">Activación por KEY</span>
              <h3 className="text-3xl font-extrabold text-white">KeyBlue PRO</h3>
              <p className="text-sm text-slate-400">Acceso total a todas las funciones avanzadas.</p>
              <ul className="space-y-3 pt-4 text-sm text-slate-300">
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-cyan-400 shrink-0" />
                  Todos los 15 temas premium desbloqueados
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-cyan-400 shrink-0" />
                  Personalización individual por tecla sin límites
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-cyan-400 shrink-0" />
                  Perfiles de teclado ilimitados con exportación
                </li>
                <li className="flex items-center gap-3">
                  <CheckCircle2 className="w-4 h-4 text-cyan-400 shrink-0" />
                  Validación offline segura con firma criptográfica
                </li>
              </ul>
            </div>
            <Link
              href="/login"
              className="w-full py-3.5 rounded-xl bg-primary hover:bg-primary-hover font-bold text-sm text-white transition-all text-center block shadow-lg shadow-primary/30"
            >
              Obtener Clave de Acceso
            </Link>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="py-12 px-6 border-t border-slate-900 bg-[#05070B] text-slate-500 text-xs">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <img src="/keyblue_logo.png" alt="KeyBlue Logo" className="w-7 h-7 rounded-xl object-cover" />
            <span className="font-bold text-white text-sm">KeyBlue Android IME</span>
          </div>

          <div className="flex items-center gap-6">
            <Link href="/login" className="hover:text-white transition-colors flex items-center gap-1">
              <Lock className="w-3.5 h-3.5 text-primary" />
              Acceso Administradores
            </Link>
            <a
              href={GITHUB_REPO_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-white transition-colors"
            >
              GitHub & Releases
            </a>
            <span>© 2026 KeyBlue. Todos los derechos reservados.</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
