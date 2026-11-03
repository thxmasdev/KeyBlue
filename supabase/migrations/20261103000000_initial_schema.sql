-- ==============================================================================
-- KEYFLOW DATABASE SCHEMA (PostgreSQL / Supabase)
-- Migración inicial: perfiles, licencias, activaciones, temas, auditoría y RLS
-- ==============================================================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. TABLA: profiles (asociada a auth.users de Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'superadmin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Trigger para crear profile automáticamente cuando un usuario se registra en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (new.id, new.email, 'user');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. TABLA: licenses (Almacena hashes de keys, nunca en texto plano)
CREATE TABLE IF NOT EXISTS public.licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_hash TEXT NOT NULL UNIQUE,
    key_prefix TEXT NOT NULL, -- Ej: 'KEYF-A1B2' para búsqueda administrativa sin revelar la clave
    license_type TEXT NOT NULL CHECK (license_type IN ('permanent', '30_days', '90_days', 'annual', 'custom')),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'active', 'expired', 'revoked', 'suspended')),
    expires_at TIMESTAMPTZ,
    max_devices INTEGER NOT NULL DEFAULT 1 CHECK (max_devices > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    revoked_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_licenses_hash ON public.licenses(key_hash);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON public.licenses(status);

-- 4. TABLA: license_activations (Dispositivos asociados a cada clave)
CREATE TABLE IF NOT EXISTS public.license_activations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_id UUID NOT NULL REFERENCES public.licenses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    device_name TEXT,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    last_validated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    deactivated_at TIMESTAMPTZ,
    UNIQUE (license_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_activations_license ON public.license_activations(license_id);
CREATE INDEX IF NOT EXISTS idx_activations_device ON public.license_activations(device_id);

-- 5. TABLA: themes (Catálogo oficial y personalizaciones)
CREATE TABLE IF NOT EXISTS public.themes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'minimal' CHECK (category IN ('minimal', 'dark', 'colorful', 'gaming', 'photo')),
    is_premium BOOLEAN NOT NULL DEFAULT false,
    preview_url TEXT,
    configuration JSONB NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_themes_category ON public.themes(category);
CREATE INDEX IF NOT EXISTS idx_themes_published ON public.themes(is_published);

-- 6. TABLA: app_config (Configuraciones dinámicas de la app)
CREATE TABLE IF NOT EXISTS public.app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key TEXT UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. TABLA: admin_audit_logs (Registro inmutable de auditoría)
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    target_id TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_audit_admin ON public.admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON public.admin_audit_logs(created_at DESC);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.license_activations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Funciones auxiliares de seguridad
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Los usuarios pueden leer y editar su propio perfil. Admins ven todos.
CREATE POLICY "Users can read own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Licenses: Totalmente bloqueada para accesos cliente públicos.
-- Solo accesible por administradores autenticados o Edge Functions con Service Role.
CREATE POLICY "Admins can view all licenses"
    ON public.licenses FOR SELECT
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Admins can insert and modify licenses"
    ON public.licenses FOR ALL
    TO authenticated
    USING (public.is_admin());

-- License Activations: Usuarios pueden ver las activaciones de sus propios dispositivos.
CREATE POLICY "Users can see own activations"
    ON public.license_activations FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- Themes: Lectura pública de temas publicados. Edición solo por admins.
CREATE POLICY "Public can view published themes"
    ON public.themes FOR SELECT
    USING (is_published = true OR public.is_admin());

CREATE POLICY "Admins can manage themes"
    ON public.themes FOR ALL
    TO authenticated
    USING (public.is_admin());

-- App Config: Lectura pública, escritura solo administradores.
CREATE POLICY "Public read app config"
    ON public.app_config FOR SELECT
    USING (true);

CREATE POLICY "Admins manage app config"
    ON public.app_config FOR ALL
    TO authenticated
    USING (public.is_admin());

-- Audit logs: Solo administradores pueden leer. Inserción solo por el sistema / admins.
CREATE POLICY "Admins view audit logs"
    ON public.admin_audit_logs FOR SELECT
    TO authenticated
    USING (public.is_admin());

