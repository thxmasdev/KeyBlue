'use client';

import { useState } from 'react';
import { Palette, Check, Sparkles } from 'lucide-react';

export default function ThemesAdminPage() {
  const [themes, setThemes] = useState([
    { id: 'midnight', name: 'Midnight Black', category: 'dark', is_premium: false, is_published: true },
    { id: 'amoled_black', name: 'AMOLED Pure Black', category: 'dark', is_premium: false, is_published: true },
    { id: 'cyber_neon', name: 'Cyber Neon', category: 'gaming', is_premium: true, is_published: true },
    { id: 'cyberpunk', name: 'Cyberpunk 2077', category: 'gaming', is_premium: true, is_published: true },
    { id: 'minimal_white', name: 'Minimal White', category: 'minimal', is_premium: false, is_published: true },
    { id: 'glass_ui', name: 'Glass UI Frost', category: 'minimal', is_premium: true, is_published: true },
    { id: 'ocean_blue', name: 'Ocean Blue', category: 'colorful', is_premium: false, is_published: true },
    { id: 'sunset', name: 'Sunset Glow', category: 'colorful', is_premium: true, is_published: true },
    { id: 'gaming_rgb', name: 'Gaming RGB Pulse', category: 'gaming', is_premium: true, is_published: true },
    { id: 'luxury_gold', name: 'Luxury Gold', category: 'minimal', is_premium: true, is_published: true },
  ]);

  const togglePublished = (id: string) => {
    setThemes(
      themes.map((t: any) => (t.id === id ? { ...t, is_published: !t.is_published } : t))
    );
  };

  const togglePremium = (id: string) => {
    setThemes(
      themes.map((t: any) => (t.id === id ? { ...t, is_premium: !t.is_premium } : t))
    );
  };

  return (
    <div className="p-4 sm:p-8 space-y-8 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight">Catálogo de Temas</h1>
        <p className="text-sm text-slate-400 mt-1">
          Publicación, categorización y control de exclusividad PRO de los temas de KeyBlue
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {themes.map((theme: any) => (
          <div
            key={theme.id}
            className="p-5 rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg space-y-4"
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-bold text-white text-base">{theme.name}</h3>
                <p className="text-xs text-slate-400 uppercase font-semibold mt-0.5">{theme.category}</p>
              </div>
              {theme.is_premium && (
                <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20">
                  <Sparkles className="w-3 h-3" />
                  PRO
                </span>
              )}
            </div>

            <div className="pt-2 border-t border-slate-800/60 flex items-center justify-between text-sm">
              <span className="text-slate-400 text-xs font-semibold">Exclusivo PRO</span>
              <button
                onClick={() => togglePremium(theme.id)}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                  theme.is_premium ? 'bg-amber-500/20 text-amber-300' : 'bg-slate-800 text-slate-400'
                }`}
              >
                {theme.is_premium ? 'Sí (Exclusivo)' : 'No (Gratuito)'}
              </button>
            </div>

            <div className="flex items-center justify-between text-sm">
              <span className="text-slate-400 text-xs font-semibold">Publicado en App</span>
              <button
                onClick={() => togglePublished(theme.id)}
                className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                  theme.is_published ? 'bg-emerald-500/20 text-emerald-300' : 'bg-rose-500/20 text-rose-300'
                }`}
              >
                {theme.is_published ? 'Publicado' : 'Oculto'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

