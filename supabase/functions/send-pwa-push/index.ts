import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

type PushRequest = {
  user_id?: string;
  title?: string;
  body?: string;
  url?: string;
  tag?: string;
  requireInteraction?: boolean;
  notification_id?: string;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const vapidPublicKey = Deno.env.get("PWA_VAPID_PUBLIC_KEY");
const vapidPrivateKey = Deno.env.get("PWA_VAPID_PRIVATE_KEY");
const vapidSubject = Deno.env.get("PWA_VAPID_SUBJECT") || "mailto:admin@astshara.app";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!vapidPublicKey || !vapidPrivateKey) {
    return json({ error: "PWA push is not configured: VAPID secrets are missing." }, 503);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing authorization" }, 401);

  const callerClient = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await callerClient.auth.getUser();
  if (userError || !user) return json({ error: "Unauthorized" }, 401);

  let payload: PushRequest;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const targetUserId = payload.user_id || user.id;
  const isServiceRole = user.app_metadata?.role === "service_role";
  if (!isServiceRole && targetUserId !== user.id) {
    return json({ error: "You may only send notifications to yourself." }, 403);
  }

  webpush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);

  const admin = createClient(supabaseUrl, serviceRoleKey);
  const { data: subscriptions, error: subscriptionError } = await admin
    .from("pwa_push_subscriptions")
    .select("id, endpoint, p256dh, auth")
    .eq("user_id", targetUserId);

  if (subscriptionError) return json({ error: subscriptionError.message }, 500);
  if (!subscriptions?.length) return json({ sent: 0, removed: 0 });

  // `silent: false` explicitly requests an audible notification where the
  // platform/browser supports notification sounds. iOS Home Screen PWAs do
  // not expose a developer-controlled custom sound for Web Push; the system
  // decides the actual alert sound.
  const notification = JSON.stringify({
    title: payload.title || "استشارة",
    body: payload.body || "لديك إشعار جديد",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    url: payload.url || "/",
    tag: payload.tag || "astshara-notification",
    requireInteraction: Boolean(payload.requireInteraction),
    notification_id: payload.notification_id || null,
    silent: false,
  });

  let sent = 0;
  let removed = 0;
  for (const subscription of subscriptions) {
    try {
      await webpush.sendNotification(
        {
          endpoint: subscription.endpoint,
          keys: { p256dh: subscription.p256dh, auth: subscription.auth },
        },
        notification,
      );
      sent++;
    } catch (error) {
      const statusCode = Number((error as { statusCode?: number })?.statusCode || 0);
      if (statusCode === 404 || statusCode === 410) {
        await admin.from("pwa_push_subscriptions").delete().eq("id", subscription.id);
        removed++;
      }
    }
  }

  return json({ sent, removed });
});
