'use client';

import { useState } from 'react';
import { ShieldAlert, Search } from 'lucide-react';
import { AuditLog } from '@/lib/supabase';

export default function AuditPage() {
  const [logs] = useState<AuditLog[]>([
    {
      id: '1',
      admin_id: 'admin.keyblue@keyblue.app',
      action: 'GENERATE_KEY',
      target_id: 'lic_8829',
      metadata: { license_type: 'permanent', max_devices: 1, key_prefix: 'KEYF-A9F2' },
      created_at: '2026-11-03 11:15:30 UTC',
    },
    {
      id: '2',
      admin_id: 'admin.keyblue@keyblue.app',
      action: 'REVOKE_KEY',
      target_id: 'lic_7714',
      metadata: { reason: 'Uso no autorizado detectado' },
      created_at: '2026-11-03 09:40:12 UTC',
    },
    {
      id: '3',
      admin_id: 'admin.keyblue@keyblue.app',
      action: 'THEME_UPDATE',
      target_id: 'gaming_rgb',
      metadata: { is_premium: true, published: true },
      created_at: '2026-11-02 18:20:00 UTC',
    },
  ]);

  const [search, setSearch] = useState('');

  const filtered = logs.filter(
    (l) =>
      l.action.toLowerCase().includes(search.toLowerCase()) ||
      l.admin_id.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-8 space-y-8 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight">Registro de Auditoría</h1>
        <p className="text-sm text-slate-400 mt-1">
          Historial inmutable de todas las acciones administrativas realizadas en KeyBlue
        </p>
      </div>

      <div className="relative">
        <Search className="w-5 h-5 text-slate-400 absolute left-4 top-3.5" />
        <input
          type="text"
          placeholder="Filtrar por acción o administrador..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-12 pr-4 py-3 bg-[#121724] border border-slate-800 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-primary"
        />
      </div>

      <div className="rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg overflow-hidden">
        <table className="w-full text-left text-sm text-slate-300">
          <thead className="text-xs uppercase bg-slate-800/50 text-slate-400">
            <tr>
              <th className="px-6 py-4">Fecha / Hora</th>
              <th className="px-6 py-4">Administrador</th>
              <th className="px-6 py-4">Acción</th>
              <th className="px-6 py-4">Detalles (Metadatos)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filtered.map((log) => (
              <tr key={log.id} className="hover:bg-slate-800/20 transition-colors">
                <td className="px-6 py-4 text-xs font-mono text-slate-400">{log.created_at}</td>
                <td className="px-6 py-4 font-medium text-white">{log.admin_id}</td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-bold bg-primary/10 text-primary border border-primary/20">
                    {log.action}
                  </span>
                </td>
                <td className="px-6 py-4 font-mono text-xs text-slate-400">
                  {JSON.stringify(log.metadata)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

