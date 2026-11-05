import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Generador criptográfico de bloques alfanuméricos seguros
function generateBlock(length = 4): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin I, O, 0, 1 para evitar confusiones
  const randomBytes = new Uint8Array(length);
  crypto.getRandomValues(randomBytes);
  return Array.from(randomBytes).map((b) => chars[b % chars.length]).join("");
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Verificamos token del administrador
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Sesión inválida" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Comprobamos rol de administrador en base de datos
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!profile || (profile.role !== "admin" && profile.role !== "superadmin")) {
      return new Response(JSON.stringify({ error: "Permiso denegado: Se requiere rol de Administrador" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { action, payload } = await req.json();

    if (action === "generate_key") {
      const { license_type, max_devices = 1, custom_days } = payload ?? {};
      const prefix = generateBlock(4);
      const b2 = generateBlock(4);
      const b3 = generateBlock(4);
      const plainKey = `KEYF-${prefix}-${b2}-${b3}`;

      // Calcular hash SHA-256
      const encoder = new TextEncoder();
      const hashBuffer = await crypto.subtle.digest("SHA-256", encoder.encode(plainKey));
      const keyHash = Array.from(new Uint8Array(hashBuffer))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");

      let expiresAt: string | null = null;
      const now = new Date();
      if (license_type === "30_days") {
        expiresAt = new Date(now.getTime() + 30 * 86400000).toISOString();
      } else if (license_type === "90_days") {
        expiresAt = new Date(now.getTime() + 90 * 86400000).toISOString();
      } else if (license_type === "annual") {
        expiresAt = new Date(now.getTime() + 365 * 86400000).toISOString();
      } else if (license_type === "custom" && custom_days) {
        expiresAt = new Date(now.getTime() + Number(custom_days) * 86400000).toISOString();
      }

      const { data: created, error: insertErr } = await supabaseClient
        .from("licenses")
        .insert({
          key_hash: keyHash,
          key_prefix: `KEYF-${prefix}`,
          license_type: license_type ?? "permanent",
          status: "available",
          expires_at: expiresAt,
          max_devices: max_devices,
          created_by: user.id,
        })
        .select()
        .single();

      if (insertErr) throw insertErr;

      // Registro de auditoría
      await supabaseClient.from("admin_audit_logs").insert({
        admin_id: user.id,
        action: "GENERATE_KEY",
        target_id: created.id,
        metadata: { license_type, max_devices, key_prefix: `KEYF-${prefix}` },
      });

      return new Response(
        JSON.stringify({
          success: true,
          key: plainKey, // Se muestra una única vez al crearse
          license: created,
        }),
        { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "revoke_key") {
      const { license_id, reason } = payload ?? {};
      const { data: updated, error: revErr } = await supabaseClient
        .from("licenses")
        .update({ status: "revoked", revoked_at: new Date().toISOString() })
        .eq("id", license_id)
        .select()
        .single();

      if (revErr) throw revErr;

      await supabaseClient.from("admin_audit_logs").insert({
        admin_id: user.id,
        action: "REVOKE_KEY",
        target_id: license_id,
        metadata: { reason },
      });

      return new Response(
        JSON.stringify({ success: true, license: updated }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: `Acción '${action}' no implementada` }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

