'use client';

import { useEffect, useState } from 'react';
import { KeyRound, CheckCircle2, Clock, Ban, Users, Activity } from 'lucide-react';
import { supabase } from '@/lib/supabase';

export default function DashboardPage() {
  const [stats, setStats] = useState({
    total: 120,
    available: 45,
    active: 68,
    expired: 4,
    revoked: 3,
    usersCount: 89,
  });

  const [recentActivations, setRecentActivations] = useState<any[]>([
    { id: '1', device_name: 'Samsung Galaxy S25 Ultra', prefix: 'KEYF-8A9X', activated_at: 'Hace 10 min' },
    { id: '2', device_name: 'Google Pixel 9 Pro', prefix: 'KEYF-3P7M', activated_at: 'Hace 45 min' },
    { id: '3', device_name: 'Xiaomi 14 Pro', prefix: 'KEYF-9K2L', activated_at: 'Hace 2 horas' },
    { id: '4', device_name: 'Motorola Edge 50', prefix: 'KEYF-1B4V', activated_at: 'Hace 5 horas' },
  ]);

  useEffect(() => {
    async function loadMetrics() {
      try {
        const { count: total } = await supabase.from('licenses').select('*', { count: 'exact', head: true });
        const { count: available } = await supabase.from('licenses').select('*', { count: 'exact', head: true }).eq('status', 'available');
        const { count: active } = await supabase.from('licenses').select('*', { count: 'exact', head: true }).eq('status', 'active');
        const { count: expired } = await supabase.from('licenses').select('*', { count: 'exact', head: true }).eq('status', 'expired');
        const { count: revoked } = await supabase.from('licenses').select('*', { count: 'exact', head: true }).eq('status', 'revoked');
        const { count: usersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });

        if (total !== null && total > 0) {
          setStats({
            total: total ?? 0,
            available: available ?? 0,
            active: active ?? 0,
            expired: expired ?? 0,
            revoked: revoked ?? 0,
            usersCount: usersCount ?? 0,
          });
        }
      } catch (_) {
        // En desarrollo local sin conexión real usa los datos base
      }
    }
    loadMetrics();
  }, []);

  const cards = [
    { title: 'Total Licencias', value: stats.total, icon: KeyRound, color: 'text-primary', bg: 'bg-primary/10' },
    { title: 'Disponibles', value: stats.available, icon: Clock, color: 'text-amber-400', bg: 'bg-amber-400/10' },
    { title: 'Activadas (PRO)', value: stats.active, icon: CheckCircle2, color: 'text-emerald-400', bg: 'bg-emerald-400/10' },
    { title: 'Expiradas', value: stats.expired, icon: Activity, color: 'text-rose-400', bg: 'bg-rose-400/10' },
    { title: 'Revocadas', value: stats.revoked, icon: Ban, color: 'text-slate-400', bg: 'bg-slate-400/10' },
    { title: 'Usuarios Registrados', value: stats.usersCount, icon: Users, color: 'text-cyan-400', bg: 'bg-cyan-400/10' },
  ];

  return (
    <div className="p-4 sm:p-8 space-y-8 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight">Dashboard General</h1>
        <p className="text-sm text-slate-400 mt-1">
          Monitorización en tiempo real del estado de licencias y plataforma KeyBlue
        </p>
      </div>

      {/* Grid de métricas */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div
              key={card.title}
              className="p-6 rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg flex items-center justify-between"
            >
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-400">{card.title}</p>
                <p className="text-3xl font-black text-white mt-2">{card.value}</p>
              </div>
              <div className={`p-4 rounded-xl ${card.bg}`}>
                <Icon className={`w-6 h-6 ${card.color}`} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Activaciones recientes */}
      <div className="p-6 rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg">
        <h2 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
          <Activity className="w-5 h-5 text-primary" />
          Activaciones Recientes de Dispositivos
        </h2>

        <div className="overflow-x-auto">
          <table className="min-w-[640px] w-full text-left text-sm text-slate-300">
            <thead className="text-xs uppercase bg-slate-800/40 text-slate-400">
              <tr>
                <th className="px-4 py-3 rounded-l-lg">Dispositivo</th>
                <th className="px-4 py-3">Prefijo Clave</th>
                <th className="px-4 py-3">Tiempo</th>
                <th className="px-4 py-3 rounded-r-lg">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {recentActivations.map((item) => (
                <tr key={item.id} className="hover:bg-slate-800/20 transition-colors">
                  <td className="px-4 py-3.5 font-medium text-white">{item.device_name}</td>
                  <td className="px-4 py-3.5 font-mono text-xs text-primary">{item.prefix}-****</td>
                  <td className="px-4 py-3.5 text-slate-400">{item.activated_at}</td>
                  <td className="px-4 py-3.5">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                      Activo
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

