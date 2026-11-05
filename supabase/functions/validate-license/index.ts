import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { key, device_id } = await req.json();

    if (!key || !device_id) {
      return new Response(
        JSON.stringify({ valid: false, reason: "Parámetros incompletos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const cleanKey = key.trim().toUpperCase();
    const encoder = new TextEncoder();
    const data = encoder.encode(cleanKey);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const keyHash = Array.from(new Uint8Array(hashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    const { data: license } = await supabaseClient
      .from("licenses")
      .select("id, status, expires_at, license_type")
      .eq("key_hash", keyHash)
      .single();

    if (!license) {
      return new Response(
        JSON.stringify({ valid: false, reason: "Licencia inexistente" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (license.status === "revoked" || license.status === "suspended") {
      return new Response(
        JSON.stringify({ valid: false, reason: `Licencia ${license.status}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (license.expires_at && new Date(license.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ valid: false, reason: "Licencia expirada" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Actualizamos fecha de última validación
    await supabaseClient
      .from("license_activations")
      .update({ last_validated_at: new Date().toISOString() })
      .eq("license_id", license.id)
      .eq("device_id", device_id);

    return new Response(
      JSON.stringify({
        valid: true,
        license_type: license.license_type,
        expires_at: license.expires_at,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ valid: false, error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

