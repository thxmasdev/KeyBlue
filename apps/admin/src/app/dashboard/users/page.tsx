'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Users, Search } from 'lucide-react';

export default function UsersPage() {
  const [users, setUsers] = useState<{ id: string; email: string; role: string; created_at: string }[]>([]);

  useEffect(() => {
    supabase
      .from('profiles')
      .select('id,email,role,created_at')
      .order('created_at', { ascending: false })
      .limit(500)
      .then(({ data }) => setUsers(data ?? []));
  }, []);

  const [search, setSearch] = useState('');

  const filtered = users.filter((u) => u.email.toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="p-4 sm:p-8 space-y-8 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight">Gestión de Usuarios</h1>
        <p className="text-sm text-slate-400 mt-1">
          Supervisión de usuarios registrados, licencias asignadas y dispositivos activos
        </p>
      </div>

      <div className="relative">
        <Search className="w-5 h-5 text-slate-400 absolute left-4 top-3.5" />
        <input
          type="text"
          placeholder="Buscar por correo electrónico..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-12 pr-4 py-3 bg-[#121724] border border-slate-800 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-primary"
        />
      </div>

      <div className="rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg overflow-x-auto">
        <table className="min-w-[640px] w-full text-left text-sm text-slate-300">
          <thead className="text-xs uppercase bg-slate-800/50 text-slate-400">
            <tr>
              <th className="px-6 py-4">Usuario</th>
              <th className="px-6 py-4">Rol</th>
              <th className="px-6 py-4">Fecha Registro</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filtered.map((u) => (
              <tr key={u.id} className="hover:bg-slate-800/20 transition-colors">
                <td className="px-6 py-4 font-medium text-white flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center font-bold text-xs text-primary">
                    {u.email[0].toUpperCase()}
                  </div>
                  {u.email}
                </td>
                <td className="px-6 py-4">
                  <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-slate-800 text-slate-300 uppercase">
                    {u.role}
                  </span>
                </td>
                <td className="px-6 py-4 text-slate-400">{new Date(u.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

