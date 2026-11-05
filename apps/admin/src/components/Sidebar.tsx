'use client';

import Link from 'next/link';
import { useState } from 'react';
import { usePathname } from 'next/navigation';
import { KeyRound, LayoutDashboard, Palette, ShieldAlert, Users, LogOut, ArrowLeft, Menu, X } from 'lucide-react';
import { supabase } from '@/lib/supabase';

const menuItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/dashboard/licenses', label: 'Gestión de KEYS', icon: KeyRound },
  { href: '/dashboard/users', label: 'Usuarios', icon: Users },
  { href: '/dashboard/themes', label: 'Catálogo de Temas', icon: Palette },
  { href: '/dashboard/audit', label: 'Auditoría', icon: ShieldAlert },
];

export function Sidebar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  // El sidebar solo debe mostrarse en rutas del panel administrativo (/dashboard)
  if (!pathname.startsWith('/dashboard')) return null;

  const handleLogout = async () => {
    await supabase.auth.signOut();
    window.location.href = '/login';
  };

  return (
    <>
      <header className="md:hidden sticky top-0 z-40 flex items-center justify-between px-4 h-14 bg-[#0E131F] border-b border-slate-800">
        <span className="font-extrabold text-white">KeyBlue <span className="text-xs text-slate-400 font-medium">Admin</span></span>
        <button aria-label="Abrir menu" onClick={() => setOpen(!open)} className="p-2 text-slate-300">
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </header>
      {open && <div className="md:hidden fixed inset-0 z-40 bg-black/60" onClick={() => setOpen(false)} />}
      <aside className={`w-64 border-r border-slate-800 bg-[#0E131F] flex-col shrink-0 fixed md:static inset-y-0 left-0 z-50 md:z-auto md:min-h-screen ${open ? "flex" : "hidden md:flex"}`}>
      <div className="p-6 border-b border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-primary to-cyan-400 flex items-center justify-center font-black text-white text-lg shadow-lg shadow-primary/30">
            K
          </div>
          <div>
            <h1 className="font-extrabold text-white text-base tracking-wide">KeyBlue</h1>
            <p className="text-xs text-slate-400 font-medium">Panel Admin</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-4 space-y-1.5">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all ${
                isActive
                  ? 'bg-primary text-white shadow-md shadow-primary/20'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              <Icon className="w-5 h-5" />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-800 space-y-2">
        <Link
          href="/"
          className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-xs font-semibold text-slate-400 hover:text-white hover:bg-slate-800/40 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Volver a la Web
        </Link>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-xs font-semibold text-rose-400 hover:bg-rose-500/10 transition-colors"
        >
          <LogOut className="w-4 h-4" />
          Cerrar Sesión
        </button>
      </div>
    </aside>
    </>
  );
}
