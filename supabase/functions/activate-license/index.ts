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

    const { key, device_id, device_name } = await req.json();

    if (!key || !device_id) {
      return new Response(
        JSON.stringify({ error: "Faltan parámetros requeridos: key o device_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Calculamos el hash criptográfico SHA-256 de la KEY introducida
    const cleanKey = key.trim().toUpperCase();
    const encoder = new TextEncoder();
    const data = encoder.encode(cleanKey);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const keyHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // Buscamos la licencia por su hash seguro
    const { data: license, error: licError } = await supabaseClient
      .from("licenses")
      .select("*")
      .eq("key_hash", keyHash)
      .single();

    if (licError || !license) {
      return new Response(
        JSON.stringify({ error: "Clave de licencia inválida o inexistente" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (license.status === "revoked" || license.status === "suspended") {
      return new Response(
        JSON.stringify({ error: `La licencia se encuentra en estado: ${license.status}` }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (license.expires_at && new Date(license.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ error: "La licencia ha expirado" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Comprobamos la cantidad de activaciones actuales
    const { data: activations, error: actError } = await supabaseClient
      .from("license_activations")
      .select("id, device_id")
      .eq("license_id", license.id)
      .is("deactivated_at", null);

    const currentCount = activations?.length ?? 0;
    const isAlreadyOnThisDevice = activations?.some((a) => a.device_id === device_id);

    if (!isAlreadyOnThisDevice && currentCount >= license.max_devices) {
      return new Response(
        JSON.stringify({
          error: `Límite máximo de dispositivos alcanzado (${currentCount}/${license.max_devices}). Desactiva un dispositivo previo para continuar.`,
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Registramos o actualizamos la activación para este dispositivo
    const now = new Date().toISOString();
    if (!isAlreadyOnThisDevice) {
      await supabaseClient.from("license_activations").insert({
        license_id: license.id,
        device_id: device_id,
        device_name: device_name ?? "Android Device",
        activated_at: now,
        last_validated_at: now,
      });

      // Actualizamos estado de la licencia a 'active' si estaba 'available'
      if (license.status === "available") {
        await supabaseClient
          .from("licenses")
          .update({ status: "active" })
          .eq("id", license.id);
      }
    } else {
      await supabaseClient
        .from("license_activations")
        .update({ last_validated_at: now })
        .eq("license_id", license.id)
        .eq("device_id", device_id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        license_type: license.license_type,
        expires_at: license.expires_at,
        activated_at: now,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Error interno del servidor", details: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

