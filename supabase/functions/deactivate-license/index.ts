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
        JSON.stringify({ error: "Faltan parámetros key o device_id" }),
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
      .select("id")
      .eq("key_hash", keyHash)
      .single();

    if (!license) {
      return new Response(
        JSON.stringify({ error: "Licencia no encontrada" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await supabaseClient
      .from("license_activations")
      .update({ deactivated_at: new Date().toISOString() })
      .eq("license_id", license.id)
      .eq("device_id", device_id);

    return new Response(
      JSON.stringify({ success: true, message: "Dispositivo desactivado exitosamente" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

