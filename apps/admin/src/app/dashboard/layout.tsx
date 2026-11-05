'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { supabase } from '@/lib/supabase';

/**
 * Protege todo /dashboard: exige una sesión real de Supabase y un perfil con rol admin/superadmin.
 * (La seguridad real la imponen las políticas RLS de la base; esto evita mostrar el panel a terceros.)
 */
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [allowed, setAllowed] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function verify() {
      const { data } = await supabase.auth.getSession();
      const user = data.session?.user;
      if (!user) {
        router.replace('/login');
        return;
      }
      const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
      if (!profile || (profile.role !== 'admin' && profile.role !== 'superadmin')) {
        await supabase.auth.signOut();
        router.replace('/login');
        return;
      }
      if (!cancelled) setAllowed(true);
    }

    verify();
    const { data: sub } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') router.replace('/login');
    });
    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, [router]);

  if (!allowed) {
    return (
      <div className="min-h-screen flex items-center justify-center text-slate-400 text-sm gap-2">
        <Loader2 className="w-4 h-4 animate-spin" />
        Verificando acceso…
      </div>
    );
  }

  return <>{children}</>;
}

