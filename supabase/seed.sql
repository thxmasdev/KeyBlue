-- ==============================================================================
-- KEYFLOW SEED DATA (Desarrollo inicial)
-- ==============================================================================

-- 1. Insertar Temas Oficiales en la base de datos
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

('ocean_blue', 'Ocean Blue', 'Tonos azul mar y aguamarina relajantes de alta legibilidad.', 'colorful', false,
 '{"background": "#0f1e36", "key": "#1d3557", "keyText": "#f1faee", "special": "#457b9d", "specialText": "#f1faee", "accent": "#a8dadc", "accentText": "#1d3557", "radius": 10, "gap": 4, "keyHeight": 52, "fontSize": 20}'::jsonb, 1, true),

('gaming_rgb', 'Gaming RGB Pulse', 'Diseño para streamers y gamers con acentos verde lima fluorescente.', 'gaming', true,
 '{"background": "#0d0d11", "key": "#181822", "keyText": "#39ff14", "special": "#261d3a", "specialText": "#ff0055", "accent": "#39ff14", "accentText": "#000000", "radius": 6, "gap": 4, "keyHeight": 54, "fontSize": 20, "bold": true}'::jsonb, 1, true)
ON CONFLICT (id) DO NOTHING;

-- 2. Insertar configuración base de la aplicación
INSERT INTO public.app_config (config_key, config_value)
VALUES 
('general', '{"min_app_version": "0.1.0", "maintenance": false, "terms_url": "https://keyflow.app/terms"}'::jsonb),
('licensing', '{"free_profile_limit": 3, "offline_grace_period_days": 14, "allow_device_transfer": true}'::jsonb)
ON CONFLICT (config_key) DO NOTHING;

