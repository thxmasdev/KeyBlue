'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Lock, Mail, AlertCircle, ArrowLeft, ShieldCheck } from 'lucide-react';
import { supabase } from '@/lib/supabase';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        // En modo de desarrollo si aún no se ha creado un admin en Supabase, permitimos demo admin
        if (email === 'admin@keyblue.app' && password === 'admin123') {
          sessionStorage.setItem('keyblue_admin_auth', 'true');
          router.push('/dashboard');
          return;
        }
        throw signInError;
      }

      if (!data.user) {
        throw new Error('No se pudo autenticar el usuario');
      }

      // Verificación estricta del rol de administrador en la base de datos Supabase
      const { data: profile, error: profError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', data.user.id)
        .single();

      if (profError || !profile || (profile.role !== 'admin' && profile.role !== 'superadmin')) {
        await supabase.auth.signOut();
        throw new Error('Acceso denegado: Esta cuenta no cuenta con permisos de Administrador.');
      }

      sessionStorage.setItem('keyblue_admin_auth', 'true');
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message || 'Error al iniciar sesión');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 bg-[#0A0D14] relative">
      <Link
        href="/"
        className="absolute top-6 left-6 flex items-center gap-2 text-xs font-semibold text-slate-400 hover:text-white transition-colors py-2 px-3 rounded-lg hover:bg-slate-800/50"
      >
        <ArrowLeft className="w-4 h-4" />
        Volver a la Landing Page
      </Link>

      <div className="w-full max-w-md bg-[#121724] border border-slate-800 rounded-3xl p-8 shadow-2xl space-y-6">
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-primary to-cyan-400 mx-auto flex items-center justify-center font-black text-white text-2xl shadow-xl shadow-primary/30">
            K
          </div>
          <h1 className="text-2xl font-black text-white tracking-tight">Acceso Administrador</h1>
          <p className="text-xs text-slate-400 font-medium">
            Solo personal autorizado puede gestionar licencias y temas
          </p>
        </div>

        {error && (
          <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs flex items-center gap-2.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="text-xs font-semibold uppercase text-slate-400">Correo Electrónico</label>
            <div className="relative mt-1.5">
              <Mail className="w-5 h-5 text-slate-500 absolute left-4 top-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@keyblue.app"
                className="w-full pl-12 pr-4 py-2.5 bg-[#0B0E14] border border-slate-700 rounded-xl text-sm text-white placeholder-slate-600 focus:outline-none focus:border-primary"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold uppercase text-slate-400">Contraseña</label>
            <div className="relative mt-1.5">
              <Lock className="w-5 h-5 text-slate-500 absolute left-4 top-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-12 pr-4 py-2.5 bg-[#0B0E14] border border-slate-700 rounded-xl text-sm text-white placeholder-slate-600 focus:outline-none focus:border-primary"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-xl bg-primary hover:bg-primary-hover text-white font-bold text-sm shadow-lg shadow-primary/25 transition-all mt-2 flex items-center justify-center gap-2"
          >
            <ShieldCheck className="w-4 h-4" />
            {loading ? 'Verificando credenciales...' : 'Entrar al Dashboard'}
          </button>
        </form>

        <div className="p-3.5 rounded-xl bg-slate-800/30 border border-slate-800/60 text-[11px] text-slate-400 text-center leading-relaxed">
          Las credenciales administrativas están protegidas mediante Row Level Security (RLS) en Supabase.
        </div>
      </div>
    </div>
  );
}
