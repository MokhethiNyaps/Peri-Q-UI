import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@6";

type PushEvent = "new_order" | "status_update";

type OrderRow = {
  id: string;
  user_id: string;
  order_number: number;
  customer_name: string;
  order_type: string;
  total_price: number;
  status: string;
  payment_status: string;
  created_at: string;
};

type PushTokenRow = {
  id: string;
  fcm_token: string;
  platform: "android" | "ios";
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse({ error: "Authentication required." }, 401);
    }

    const supabaseUrl = requireEnvironment("SUPABASE_URL");
    const anonKey = requireEnvironment("SUPABASE_ANON_KEY");
    const serviceRoleKey = requireEnvironment("SUPABASE_SERVICE_ROLE_KEY");
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    // The payment webhook calls with the service key once a payment is
    // verified, so new orders alert the restaurant whichever client paid.
    const isServer = await sameSecret(
      authorization.slice("Bearer ".length).trim(),
      serviceRoleKey,
    );
    let user: { id: string } | null = null;
    if (!isServer) {
      const { data, error: userError } = await userClient.auth.getUser();
      if (userError || !data.user) {
        return jsonResponse({ error: "Invalid session." }, 401);
      }
      user = data.user;
    }

    const payload = (await request.json()) as {
      event?: PushEvent;
      order_id?: string;
    };
    if (
      !["new_order", "status_update"].includes(payload.event ?? "") ||
      !isUuid(payload.order_id)
    ) {
      return jsonResponse({ error: "Invalid notification request." }, 400);
    }

    const { data: order, error: orderError } = await serviceClient
      .from("orders")
      .select(
        "id,user_id,order_number,customer_name,order_type,total_price,status,payment_status,created_at",
      )
      .eq("id", payload.order_id!)
      .maybeSingle<OrderRow>();
    if (orderError) {
      throw orderError;
    }
    if (!order) {
      return jsonResponse({ error: "Order not found." }, 404);
    }

    const event = payload.event!;
    if (isServer) {
      if (
        event !== "new_order" || order.status !== "pending" ||
        order.payment_status !== "paid"
      ) {
        return jsonResponse({ error: "Not allowed." }, 403);
      }
    } else {
      const { data: profile, error: profileError } = await serviceClient
        .from("profiles")
        .select("role")
        .eq("id", user!.id)
        .maybeSingle<{ role: string }>();
      if (profileError) {
        throw profileError;
      }
      if (event === "new_order") {
        if (order.user_id !== user!.id || order.status !== "pending") {
          return jsonResponse({ error: "Not allowed." }, 403);
        }
      } else if (profile?.role !== "admin") {
        return jsonResponse({ error: "Administrator access required." }, 403);
      }
    }

    const eventKey = event === "new_order"
      ? "new_order"
      : `status:${order.status}`;
    let { data: dispatch, error: dispatchError } = await serviceClient
      .from("push_notification_dispatches")
      .upsert(
        { order_id: order.id, event_key: eventKey },
        {
          onConflict: "order_id,event_key",
          ignoreDuplicates: true,
        },
      )
      .select("id,sent_at")
      .maybeSingle<{ id: string; sent_at: string | null }>();
    if (dispatchError) {
      throw dispatchError;
    }
    if (!dispatch) {
      const { data: existingDispatch, error: existingDispatchError } =
        await serviceClient
          .from("push_notification_dispatches")
          .select("id,sent_at")
          .eq("order_id", order.id)
          .eq("event_key", eventKey)
          .single<{ id: string; sent_at: string | null }>();
      if (existingDispatchError) {
        throw existingDispatchError;
      }
      if (existingDispatch.sent_at) {
        return jsonResponse({ delivered: 0, duplicate: true });
      }
      dispatch = existingDispatch;
    }

    const targetQuery = serviceClient
      .from("push_tokens")
      .select("id,fcm_token,platform");
    const { data: tokens, error: tokenError } = event === "new_order"
      ? await targetQuery.eq("role", "admin")
      : await targetQuery.eq("role", "client").eq("user_id", order.user_id);
    if (tokenError) {
      throw tokenError;
    }

    const message = buildMessage(event, order);
    const accessToken = await createGoogleAccessToken();
    let delivered = 0;
    const invalidTokenIds: string[] = [];

    for (const target of (tokens ?? []) as PushTokenRow[]) {
      const result = await sendFcmMessage(
        accessToken,
        target.fcm_token,
        target.platform,
        message,
      );
      if (result.delivered) {
        delivered += 1;
      } else if (result.unregister) {
        invalidTokenIds.push(target.id);
      }
    }

    if (invalidTokenIds.length > 0) {
      await serviceClient.from("push_tokens").delete().in(
        "id",
        invalidTokenIds,
      );
    }
    await serviceClient
      .from("push_notification_dispatches")
      .update({ sent_at: new Date().toISOString() })
      .eq("id", dispatch.id);

    return jsonResponse({
      delivered,
      invalid_tokens_removed: invalidTokenIds.length,
    });
  } catch (error) {
    console.error("order-push failed", error);
    return jsonResponse({ error: "Notification delivery failed." }, 500);
  }
});

function buildMessage(event: PushEvent, order: OrderRow) {
  if (event === "new_order") {
    return {
      title: `New order #${order.order_number}`,
      body: `${order.customer_name} placed a ${order.order_type} order for ` +
        `R${Number(order.total_price).toFixed(2)}.`,
      channelId: "admin_orders",
      type: "admin_order",
      orderId: order.id,
      orderNumber: String(order.order_number),
      status: order.status,
    };
  }

  const titleByStatus: Record<string, string> = {
    preparing: "Your order is being prepared",
    ready: "Your order is ready!",
    completed: "Your order is completed",
    cancelled: "Your order was cancelled",
  };
  return {
    title: titleByStatus[order.status] ?? "Your order was updated",
    body: `Order #${order.order_number} is now ${order.status}.`,
    channelId: "client_order_updates",
    type: "client_order_update",
    orderId: order.id,
    orderNumber: String(order.order_number),
    status: order.status,
  };
}

async function sendFcmMessage(
  accessToken: string,
  fcmToken: string,
  platform: "android" | "ios",
  message: ReturnType<typeof buildMessage>,
) {
  const projectId = requireEnvironment("FCM_PROJECT_ID");
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: message.title,
            body: message.body,
          },
          data: {
            type: message.type,
            order_id: message.orderId,
            order_number: message.orderNumber,
            status: message.status,
            channel_id: message.channelId,
            title: message.title,
            body: message.body,
          },
          android: {
            priority: "high",
            ttl: "900s",
            notification: {
              channel_id: message.channelId,
              sound: "default",
              default_vibrate_timings: true,
              notification_priority: message.channelId === "admin_orders"
                ? "PRIORITY_MAX"
                : "PRIORITY_HIGH",
            },
          },
          ...(platform === "ios"
            ? {
              apns: {
                headers: { "apns-priority": "10" },
                payload: { aps: { sound: "default" } },
              },
            }
            : {}),
        },
      }),
    },
  );

  if (response.ok) {
    return { delivered: true, unregister: false };
  }
  const errorBody = await response.json().catch(() => ({}));
  const errorStatus = errorBody?.error?.status as string | undefined;
  const detailCodes = (errorBody?.error?.details ?? [])
    .map((detail: { errorCode?: string }) => detail.errorCode)
    .filter(Boolean);
  console.error("FCM rejected a message", response.status, errorBody);
  return {
    delivered: false,
    unregister: errorStatus === "NOT_FOUND" ||
      errorStatus === "UNREGISTERED" ||
      detailCodes.includes("UNREGISTERED"),
  };
}

async function createGoogleAccessToken() {
  const clientEmail = requireEnvironment("FCM_CLIENT_EMAIL");
  const privateKey = requireEnvironment("FCM_PRIVATE_KEY").replace(
    /\\n/g,
    "\n",
  );
  const signingKey = await importPKCS8(privateKey, "RS256");
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(signingKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const body = await response.json();
  if (!response.ok || typeof body.access_token !== "string") {
    throw new Error("Google OAuth token exchange failed.");
  }
  return body.access_token as string;
}

function requireEnvironment(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing ${name}.`);
  }
  return value;
}

// Compares digests so the time taken does not reveal how much of a guessed
// key matched.
async function sameSecret(candidate: string, secret: string) {
  const encoder = new TextEncoder();
  const [a, b] = await Promise.all([
    crypto.subtle.digest("SHA-256", encoder.encode(candidate)),
    crypto.subtle.digest("SHA-256", encoder.encode(secret)),
  ]);
  const left = new Uint8Array(a);
  const right = new Uint8Array(b);
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left[index] ^ right[index];
  }
  return difference === 0;
}

function isUuid(value: unknown): value is string {
  return (
    typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value)
  );
}
