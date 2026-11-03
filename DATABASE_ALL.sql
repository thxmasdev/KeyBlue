-- ==============================================================================
-- KEYBLUE - BASE DE DATOS COMPLETA (DATABASE_ALL.sql)
-- Para ejecutar directamente en el SQL Editor de Supabase
-- Incluye: Extensiones, Tablas, Triggers, Índices, Políticas RLS y Datos Iniciales
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONES
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 2. TABLAS PRINCIPALES
-- ------------------------------------------------------------------------------

-- Tabla: profiles (Vinculada a auth.users de Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'superadmin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Tabla: licenses (Almacena hashes de keys criptográficas, nunca en texto plano)
CREATE TABLE IF NOT EXISTS public.licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_hash TEXT NOT NULL UNIQUE,
    key_prefix TEXT NOT NULL, -- Ej: 'KEYF-A9F2' para búsquedas administrativas seguras
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
CREATE INDEX IF NOT EXISTS idx_licenses_prefix ON public.licenses(key_prefix);

-- Tabla: license_activations (Dispositivos asociados a cada clave)
CREATE TABLE IF NOT EXISTS public.license_activations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_id UUID NOT NULL REFERENCES public.licenses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    device_id TEXT NOT NULL,
    device_name TEXT,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    last_validated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    deactivated_at TIMESTAMPTZ,
    UNIQUE (license_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_activations_license ON public.license_activations(license_id);
CREATE INDEX IF NOT EXISTS idx_activations_device ON public.license_activations(device_id);

-- Tabla: themes (Catálogo oficial y personalizaciones)
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

-- Tabla: app_config (Configuraciones dinámicas de la app)
CREATE TABLE IF NOT EXISTS public.app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key TEXT UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Tabla: admin_audit_logs (Registro inmutable de auditoría)
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

-- ------------------------------------------------------------------------------
-- 3. TRIGGERS Y FUNCIONES AUTOMÁTICAS
-- ------------------------------------------------------------------------------

-- Trigger para crear profile automáticamente al registrar un nuevo usuario en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (new.id, new.email, 'user')
    ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Función para verificar si el usuario autenticado actual es Administrador
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 4. SEGURIDAD A NIVEL DE FILA (ROW LEVEL SECURITY - RLS)
-- ------------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.license_activations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Limpieza de políticas previas si existen
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all licenses" ON public.licenses;
DROP POLICY IF EXISTS "Admins can insert and modify licenses" ON public.licenses;
DROP POLICY IF EXISTS "Users can see own activations" ON public.license_activations;
DROP POLICY IF EXISTS "Public can view published themes" ON public.themes;
DROP POLICY IF EXISTS "Admins can manage themes" ON public.themes;
DROP POLICY IF EXISTS "Public read app config" ON public.app_config;
DROP POLICY IF EXISTS "Admins manage app config" ON public.app_config;
DROP POLICY IF EXISTS "Admins view audit logs" ON public.admin_audit_logs;

-- Políticas de Profiles
CREATE POLICY "Users can read own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Políticas de Licenses (Protección estricta: sólo admins o Edge Functions)
CREATE POLICY "Admins can view all licenses"
    ON public.licenses FOR SELECT
    TO authenticated
    USING (public.is_admin());

CREATE POLICY "Admins can insert and modify licenses"
    ON public.licenses FOR ALL
    TO authenticated
    USING (public.is_admin());

-- Políticas de Activaciones
CREATE POLICY "Users can see own activations"
    ON public.license_activations FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- Políticas de Temas (Lectura pública de publicados, edición sólo admins)
CREATE POLICY "Public can view published themes"
    ON public.themes FOR SELECT
    USING (is_published = true OR public.is_admin());

CREATE POLICY "Admins can manage themes"
    ON public.themes FOR ALL
    TO authenticated
    USING (public.is_admin());

-- Políticas de App Config
CREATE POLICY "Public read app config"
    ON public.app_config FOR SELECT
    USING (true);

CREATE POLICY "Admins manage app config"
    ON public.app_config FOR ALL
    TO authenticated
    USING (public.is_admin());

-- Políticas de Auditoría
CREATE POLICY "Admins view audit logs"
    ON public.admin_audit_logs FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- ------------------------------------------------------------------------------
-- 5. DATOS DE SEMILLA (SEED DATA: 15 TEMAS OFICIALES Y CONFIGURACIONES)
-- ------------------------------------------------------------------------------

INSERT INTO public.themes (id, name, description, category, is_premium, configuration, version, is_published)
VALUES
('midnight', 'Midnight Black', 'Elegante y equilibrado en tonos azul medianoche profundo.', 'dark', false, 
 '{"background": "#12161c", "key": "#262d37", "keyText": "#ffffff", "special": "#37414f", "specialText": "#ffffff", "accent": "#3d7bff", "accentText": "#ffffff", "radius": 10, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('amoled_black', 'AMOLED Pure Black', 'Negro puro (#000000) para pantallas OLED con mínimo consumo de batería.', 'dark', false,
 '{"background": "#000000", "key": "#121212", "keyText": "#f0f0f0", "special": "#1f1f1f", "specialText": "#e0e0e0", "accent": "#4a80ff", "accentText": "#ffffff", "radius": 8, "gap": 3, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('minimal_white', 'Minimal White', 'Limpio, espacioso y pulcro sobre blanco puro y sombras sutiles.', 'minimal', false,
 '{"background": "#f8f9fa", "key": "#ffffff", "keyText": "#202124", "special": "#e8eaed", "specialText": "#3c4043", "accent": "#1a73e8", "accentText": "#ffffff", "radius": 12, "gap": 5, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('cyber_neon', 'Cyber Neon', 'Contraste ultra vibrante con acentos cyan eléctrico y magenta neón.', 'gaming', true,
 '{"background": "#0a0e1a", "key": "#141e33", "keyText": "#00f5ff", "special": "#23153a", "specialText": "#ff007f", "accent": "#00f5ff", "accentText": "#0a0e1a", "radius": 12, "gap": 5, "keyHeight": 52, "fontSize": 20, "bold": true}'::jsonb, 1, true),

('cyberpunk', 'Cyberpunk 2077', 'Amarillo industrial urbano, tipografía potente y fondo oscuro grafito.', 'gaming', true,
 '{"background": "#111111", "key": "#222222", "keyText": "#fff000", "special": "#2e2e00", "specialText": "#fff000", "accent": "#fff000", "accentText": "#111111", "radius": 4, "gap": 4, "keyHeight": 52, "fontSize": 20, "bold": true}'::jsonb, 1, true),

('glass_ui', 'Glass UI Frost', 'Estética translúcida moderna y minimalista inspirada en vidrio esmerilado.', 'minimal', true,
 '{"background": "#181c28", "key": "#2b3347", "keyText": "#e2e8f0", "special": "#3e4a66", "specialText": "#94a3b8", "accent": "#38bdf8", "accentText": "#0f172a", "radius": 16, "gap": 4, "keyHeight": 54, "fontSize": 20}'::jsonb, 1, true),

('ocean_blue', 'Ocean Blue', 'Tonos azul mar y aguamarina relajantes de alta legibilidad.', 'colorful', false,
 '{"background": "#0f1e36", "key": "#1d3557", "keyText": "#f1faee", "special": "#457b9d", "specialText": "#f1faee", "accent": "#a8dadc", "accentText": "#1d3557", "radius": 10, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('forest_green', 'Forest Green', 'Verde esmeralda y musgo nórdico, sereno y natural.', 'minimal', false,
 '{"background": "#13221a", "key": "#1e382b", "keyText": "#e8f5e9", "special": "#2d533f", "specialText": "#c8e6c9", "accent": "#4caf50", "accentText": "#ffffff", "radius": 10, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('sunset', 'Sunset Glow', 'Cálido atardecer degradado en tonos coral, mandarina y violeta oscuro.', 'colorful', true,
 '{"background": "#231226", "key": "#3e1c3f", "keyText": "#ffd1ba", "special": "#5a2552", "specialText": "#ff9e7d", "accent": "#ff6b6b", "accentText": "#ffffff", "radius": 14, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('lavender', 'Lavender Mist', 'Lavanda suave pastel y púrpura suave de estética estética y limpia.', 'minimal', false,
 '{"background": "#f3eef9", "key": "#ffffff", "keyText": "#4a3e5e", "special": "#e5d9f2", "specialText": "#594576", "accent": "#8b5cf6", "accentText": "#ffffff", "radius": 14, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('material_dark', 'Material Dark', 'Estilo Material Design 3 con tonos gris grafito y acentos Google Blue.', 'dark', false,
 '{"background": "#1b1b1f", "key": "#2b2b30", "keyText": "#e4e1e6", "special": "#3e3e45", "specialText": "#c8c5ca", "accent": "#a8c7fa", "accentText": "#042f66", "radius": 18, "gap": 5, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('material_light', 'Material Light', 'Material Design 3 claro con esquinas redondeadas y contraste accesible.', 'minimal', false,
 '{"background": "#f0f0f4", "key": "#ffffff", "keyText": "#1b1b1f", "special": "#e2e2e6", "specialText": "#45464f", "accent": "#0b57d0", "accentText": "#ffffff", "radius": 18, "gap": 5, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('gaming_rgb', 'Gaming RGB Pulse', 'Diseño para streamers y gamers con acentos verde lima fluorescente.', 'gaming', true,
 '{"background": "#0d0d11", "key": "#181822", "keyText": "#39ff14", "special": "#261d3a", "specialText": "#ff0055", "accent": "#39ff14", "accentText": "#000000", "radius": 6, "gap": 4, "keyHeight": 54, "fontSize": 20, "bold": true}'::jsonb, 1, true),

('crimson_red', 'Crimson Red', 'Rojo carmesí profundo con toques oscuros de carbón y alta energía.', 'colorful', true,
 '{"background": "#1a0a0c", "key": "#2d1216", "keyText": "#ffe5e8", "special": "#4a1a21", "specialText": "#ff8595", "accent": "#e63946", "accentText": "#ffffff", "radius": 10, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('luxury_gold', 'Luxury Gold', 'Negro satinado con detalles en oro cepillado y acabado premium.', 'minimal', true,
 '{"background": "#141414", "key": "#222220", "keyText": "#e5c158", "special": "#333026", "specialText": "#ffe082", "accent": "#d4af37", "accentText": "#141414", "radius": 8, "gap": 4, "keyHeight": 52, "fontSize": 20, "bold": true}'::jsonb, 1, true)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, 
    description = EXCLUDED.description, 
    configuration = EXCLUDED.configuration,
    is_premium = EXCLUDED.is_premium;

-- Configuraciones de la aplicación
INSERT INTO public.app_config (config_key, config_value)
VALUES 
('general', '{"min_app_version": "0.1.0", "maintenance": false, "terms_url": "https://keyblue.app/terms"}'::jsonb),
('licensing', '{"free_profile_limit": 3, "offline_grace_period_days": 14, "allow_device_transfer": true}'::jsonb)
ON CONFLICT (config_key) DO UPDATE SET config_value = EXCLUDED.config_value;

