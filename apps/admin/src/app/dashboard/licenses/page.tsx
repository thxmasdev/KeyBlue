'use client';

import { useState } from 'react';
import { KeyRound, Plus, Copy, Check, ShieldAlert, Search, Filter } from 'lucide-react';
import { License } from '@/lib/supabase';

// Generador de clave segura en frontend para pruebas administrativas inmediatas
function generateSecureKey(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const block = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `KEYF-${block()}-${block()}-${block()}`;
}

export default function LicensesPage() {
  const [licenses, setLicenses] = useState<License[]>([
    {
      id: '1',
      key_prefix: 'KEYF-A9F2',
      license_type: 'permanent',
      status: 'active',
      expires_at: null,
      max_devices: 1,
      created_at: '2026-11-01T12:00:00Z',
      revoked_at: null,
    },
    {
      id: '2',
      key_prefix: 'KEYF-7K4M',
      license_type: 'annual',
      status: 'available',
      expires_at: '2027-11-03T12:00:00Z',
      max_devices: 2,
      created_at: '2026-11-02T15:30:00Z',
      revoked_at: null,
    },
    {
      id: '3',
      key_prefix: 'KEYF-3N8P',
      license_type: '30_days',
      status: 'active',
      expires_at: '2026-12-03T12:00:00Z',
      max_devices: 1,
      created_at: '2026-11-03T09:00:00Z',
      revoked_at: null,
    },
  ]);

  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [search, setSearch] = useState<string>('');
  const [showModal, setShowModal] = useState<boolean>(false);
  const [generatedKey, setGeneratedKey] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean>(false);

  // Formulario de generación
  const [newType, setNewType] = useState<string>('permanent');
  const [newMaxDevices, setNewMaxDevices] = useState<number>(1);

  const handleGenerate = () => {
    const key = generateSecureKey();
    const prefix = key.substring(0, 9); // ej: KEYF-A9F2
    const now = new Date();
    let expires: string | null = null;

    if (newType === '30_days') {
      expires = new Date(now.getTime() + 30 * 86400000).toISOString();
    } else if (newType === '90_days') {
      expires = new Date(now.getTime() + 90 * 86400000).toISOString();
    } else if (newType === 'annual') {
      expires = new Date(now.getTime() + 365 * 86400000).toISOString();
    }

    const newLic: License = {
      id: `lic_${Date.now()}`,
      key_prefix: prefix,
      license_type: newType as any,
      status: 'available',
      expires_at: expires,
      max_devices: newMaxDevices,
      created_at: now.toISOString(),
      revoked_at: null,
    };

    setLicenses([newLic, ...licenses]);
    setGeneratedKey(key);
    setCopied(false);
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleRevoke = (id: string) => {
    if (confirm('¿Estás seguro de revocar esta clave? Los dispositivos perderán acceso PRO.')) {
      setLicenses(
        licenses.map((l) =>
          l.id === id ? { ...l, status: 'revoked', revoked_at: new Date().toISOString() } : l
        )
      );
    }
  };

  const filtered = licenses.filter((l) => {
    const matchesStatus = filterStatus === 'all' || l.status === filterStatus;
    const matchesSearch = l.key_prefix.toLowerCase().includes(search.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  return (
    <div className="p-8 space-y-8 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tight">Gestión de Licencias (KEYS)</h1>
          <p className="text-sm text-slate-400 mt-1">
            Generación criptográfica, control de duración y revocación de accesos PRO
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-5 py-3 rounded-xl bg-primary hover:bg-primary-hover text-white text-sm font-bold shadow-lg shadow-primary/25 transition-all"
        >
          <Plus className="w-5 h-5" />
          Generar Nueva KEY
        </button>
      </div>

      {/* Filtros y búsqueda */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="w-5 h-5 text-slate-400 absolute left-4 top-3.5" />
          <input
            type="text"
            placeholder="Buscar por prefijo (ej: KEYF-A9F2)..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-12 pr-4 py-3 bg-[#121724] border border-slate-800 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-primary"
          />
        </div>
        <div className="flex items-center gap-2">
          <Filter className="w-4 h-4 text-slate-400" />
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-3 bg-[#121724] border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-primary"
          >
            <option value="all">Todos los estados</option>
            <option value="available">Disponibles</option>
            <option value="active">Activas</option>
            <option value="expired">Expiradas</option>
            <option value="revoked">Revocadas</option>
          </select>
        </div>
      </div>

      {/* Tabla de Licencias */}
      <div className="rounded-2xl bg-[#121724] border border-slate-800/80 shadow-lg overflow-hidden">
        <table className="w-full text-left text-sm text-slate-300">
          <thead className="text-xs uppercase bg-slate-800/50 text-slate-400">
            <tr>
              <th className="px-6 py-4">Prefijo KEY</th>
              <th className="px-6 py-4">Tipo</th>
              <th className="px-6 py-4">Dispositivos</th>
              <th className="px-6 py-4">Estado</th>
              <th className="px-6 py-4">Vencimiento</th>
              <th className="px-6 py-4 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filtered.map((item) => (
              <tr key={item.id} className="hover:bg-slate-800/20 transition-colors">
                <td className="px-6 py-4 font-mono font-bold text-primary">{item.key_prefix}-****-****</td>
                <td className="px-6 py-4 capitalize">{item.license_type.replace('_', ' ')}</td>
                <td className="px-6 py-4">{item.max_devices} dispositivo(s)</td>
                <td className="px-6 py-4">
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                      item.status === 'active'
                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                        : item.status === 'available'
                        ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                        : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                    }`}
                  >
                    {item.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-slate-400">
                  {item.expires_at ? new Date(item.expires_at).toLocaleDateString() : 'Permanente'}
                </td>
                <td className="px-6 py-4 text-right">
                  {item.status !== 'revoked' ? (
                    <button
                      onClick={() => handleRevoke(item.id)}
                      className="px-3 py-1.5 rounded-lg text-xs font-bold text-rose-400 hover:bg-rose-500/10 transition-colors"
                    >
                      Revocar
                    </button>
                  ) : (
                    <span className="text-xs text-slate-500 italic">Revocada</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal para Generar KEY */}
      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-[#121724] border border-slate-800 rounded-2xl p-6 shadow-2xl space-y-5">
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <KeyRound className="w-5 h-5 text-primary" />
              Generar Clave de Licencia
            </h2>

            {!generatedKey ? (
              <div className="space-y-4">
                <div>
                  <label className="text-xs font-semibold uppercase text-slate-400">Tipo de Licencia</label>
                  <select
                    value={newType}
                    onChange={(e) => setNewType(e.target.value)}
                    className="mt-1.5 w-full px-4 py-2.5 bg-[#0B0E14] border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-primary"
                  >
                    <option value="permanent">Permanente (De por vida)</option>
                    <option value="30_days">PRO 30 Días</option>
                    <option value="90_days">PRO 90 Días</option>
                    <option value="annual">PRO Anual (365 días)</option>
                  </select>
                </div>

                <div>
                  <label className="text-xs font-semibold uppercase text-slate-400">Límite de Dispositivos</label>
                  <input
                    type="number"
                    min={1}
                    max={5}
                    value={newMaxDevices}
                    onChange={(e) => setNewMaxDevices(Number(e.target.value))}
                    className="mt-1.5 w-full px-4 py-2.5 bg-[#0B0E14] border border-slate-700 rounded-xl text-sm text-white focus:outline-none focus:border-primary"
                  />
                </div>

                <div className="flex justify-end gap-3 pt-3">
                  <button
                    onClick={() => setShowModal(false)}
                    className="px-4 py-2 text-sm font-semibold text-slate-400 hover:text-white"
                  >
                    Cancelar
                  </button>
                  <button
                    onClick={handleGenerate}
                    className="px-5 py-2.5 rounded-xl bg-primary hover:bg-primary-hover text-white text-sm font-bold shadow-md shadow-primary/20"
                  >
                    Crear Clave
                  </button>
                </div>
              </div>
            ) : (
              <div className="space-y-5 text-center">
                <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-medium">
                  ¡Clave generada exitosamente! Cópiala ahora, no volverá a mostrarse en texto plano.
                </div>

                <div className="p-4 rounded-xl bg-[#0B0E14] border border-slate-700 font-mono text-xl font-bold tracking-widest text-primary selection:bg-primary selection:text-white">
                  {generatedKey}
                </div>

                <button
                  onClick={() => copyToClipboard(generatedKey)}
                  className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-primary hover:bg-primary-hover text-white font-bold text-sm shadow-lg shadow-primary/25 transition-all"
                >
                  {copied ? <Check className="w-5 h-5 text-white" /> : <Copy className="w-5 h-5" />}
                  {copied ? '¡Copiada al portapapeles!' : 'Copiar Clave'}
                </button>

                <button
                  onClick={() => {
                    setGeneratedKey(null);
                    setShowModal(false);
                  }}
                  className="w-full py-2.5 text-xs text-slate-400 hover:text-white font-semibold"
                >
                  Cerrar
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

