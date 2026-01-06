import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { SignJWT } from "https://deno.land/x/jose@v4.15.4/index.ts";

const supabaseUrl = Deno.env.get("APP_SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("APP_SUPABASE_ANON_KEY") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const fcmProjectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
const fcmClientEmail = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
const fcmPrivateKey = Deno.env.get("FCM_PRIVATE_KEY") ?? "";
const dispatchJobSecret = Deno.env.get("DISPATCH_JOB_SECRET") ?? "";

serve(async (request) => {
  if (!supabaseUrl || !anonKey) {
    return jsonResponse({ error: "missing_supabase_config" }, 500);
  }
  if (!fcmProjectId || !fcmClientEmail || !fcmPrivateKey) {
    return jsonResponse({ error: "missing_fcm_config" }, 500);
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (dispatchJobSecret) {
    const headerSecret = request.headers.get("x-dispatch-secret") ?? "";
    if (headerSecret !== dispatchJobSecret) {
      return jsonResponse({ error: "invalid_dispatch_secret" }, 401);
    }
  }

  const body = await request.json().catch(() => ({}));
  const journeyId = body.journey_id ?? body.journeyId ?? null;
  const batchSize = Number(body.batch_size ?? body.batchSize ?? 10);
  const completeBatchSize = Number(body.complete_batch_size ?? body.completeBatchSize ?? 10);

  const rpcName = journeyId ? "match_journey" : "match_pending_journeys";
  const payload = journeyId
    ? { target_journey_id: journeyId }
    : { batch_size: batchSize };

  console.log(`[dispatch] Starting: rpc=${rpcName}, journey_id=${journeyId || 'batch'}, batch_size=${batchSize}`);

  const authHeader = request.headers.get("Authorization") ?? "";
  const authToUse =
    authHeader || (serviceRoleKey ? `Bearer ${serviceRoleKey}` : "");

  if (!authToUse) {
    console.error(`[dispatch] Missing auth header and service_role key`);
    return jsonResponse({ error: "missing_auth" }, 401);
  }

  const rpcResponse = await fetch(`${supabaseUrl}/rest/v1/rpc/${rpcName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: anonKey,
      Authorization: authToUse,
    },
    body: JSON.stringify(payload),
  });

  const rpcText = await rpcResponse.text();
  if (!rpcResponse.ok) {
    console.error(`[dispatch] RPC ${rpcName} failed: status=${rpcResponse.status}, body=${rpcText}`);
    return jsonResponse(
      {
        error: "match_failed",
        status: rpcResponse.status,
        body: rpcText,
      },
      500,
    );
  }

  const rows = safeJsonArray(rpcText);
  const targets = rows.filter((row) =>
    row &&
    typeof row.device_token === "string" &&
    row.device_token.length > 0
  );

  console.log(`[dispatch] Match completed: matched=${rows.length}, with_tokens=${targets.length}`);

  const results = await Promise.allSettled(
    targets.map(async (row) => {
      const journeyId = row.journey_id as string;
      const recipientUserId = row.recipient_user_id as string;
      const localeTag = normalizeLocaleTag(row.locale_tag as string | undefined);
      const text = resolvePushText(localeTag);
      const route = `/inbox?highlight=${encodeURIComponent(journeyId)}`;
      try {
        await sendFcm({
          token: row.device_token as string,
          journeyId,
          projectId: fcmProjectId,
          title: text.title,
          body: text.body,
          route,
        });
        await insertNotificationLog({
          userId: recipientUserId,
          title: text.title,
          body: text.body,
          route,
          data: {
            type: "journey_assigned",
            journey_id: journeyId,
            fcm_status: "success",
          },
        });
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`[dispatch] FCM failed for journey=${journeyId}, user=${recipientUserId}: ${errorMessage}`);
        await insertNotificationLog({
          userId: recipientUserId,
          title: text.title,
          body: text.body,
          route,
          data: {
            type: "journey_assigned",
            journey_id: journeyId,
            fcm_status: "failed",
            fcm_error: errorMessage,
          },
        });
        throw error;
      }
    }),
  );

  const successCount = results.filter((item) => item.status === "fulfilled")
    .length;
  const failedResults = results.filter((item) => item.status === "rejected");
  if (failedResults.length > 0) {
    console.error(`[dispatch] ${failedResults.length} FCM push(es) failed`);
  }

  const completionResult = await dispatchCompletion({
    batchSize: completeBatchSize,
    projectId: fcmProjectId,
  });

  const responseData = {
    matched: rows.length,
    pushTargets: targets.length,
    pushSuccess: successCount,
    completion: completionResult,
  };

  console.log(`[dispatch] Completed: ${JSON.stringify(responseData)}`);

  return jsonResponse(responseData, 200);
});

async function sendFcm({
  token,
  journeyId,
  projectId,
  title,
  body,
  route,
}: {
  token: string;
  journeyId: string;
  projectId: string;
  title: string;
  body: string;
  route: string;
}) {
  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token,
        notification: {
          title,
          body,
        },
        data: {
          route,
          journey_id: journeyId,
          type: "journey_assigned",
        },
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    // UNREGISTERED 토큰 무효화 처리
    if (response.status === 404 && body.includes("UNREGISTERED")) {
      console.log(`[dispatch] Invalidating UNREGISTERED token: ${token.substring(0, 20)}...`);
      await invalidateDeviceToken(token);
    }
    throw new Error(`fcm_error:${response.status}:${body}`);
  }
}

function resolvePushText(localeTag: string) {
  switch (localeTag) {
    case "ko":
      return { title: "새 메시지", body: "새 릴레이 메시지가 도착했어요." };
    case "ja":
      return { title: "新しいメッセージ", body: "新しいリレーメッセージが届きました。" };
    case "es":
      return { title: "Nuevo mensaje", body: "Llegó un nuevo mensaje de relé." };
    case "fr":
      return { title: "Nouveau message", body: "Un nouveau message relais est arrivé." };
    case "pt_BR":
      return { title: "Nova mensagem", body: "Chegou uma nova mensagem de relé." };
    case "pt":
      return { title: "Nova mensagem", body: "Chegou uma nova mensagem de relé." };
    case "zh":
      return { title: "新消息", body: "新的转发消息已到达。" };
    case "en":
    default:
      return { title: "New message", body: "A new relay message has arrived." };
  }
}

function resolveResultPushText(localeTag: string) {
  switch (localeTag) {
    case "ko":
      return { title: "결과 도착", body: "릴레이 결과를 확인해 주세요." };
    case "ja":
      return { title: "結果が到着", body: "リレー結果を確認してください。" };
    case "es":
      return { title: "Resultados listos", body: "Consulta el resultado del relé." };
    case "fr":
      return { title: "Résultat disponible", body: "Consultez le résultat du relais." };
    case "pt_BR":
      return { title: "Resultado disponível", body: "Confira o resultado do relé." };
    case "pt":
      return { title: "Resultado disponível", body: "Veja o resultado do relé." };
    case "zh":
      return { title: "结果已到达", body: "请查看转发结果。" };
    case "en":
    default:
      return { title: "Result ready", body: "Your relay result is ready." };
  }
}

function normalizeLocaleTag(tag?: string) {
  if (!tag) {
    return "en";
  }
  if (tag === "pt-BR") {
    return "pt_BR";
  }
  if (tag.startsWith("pt-")) {
    return "pt";
  }
  if (tag.startsWith("zh")) {
    return "zh";
  }
  if (tag.startsWith("en")) {
    return "en";
  }
  if (tag.startsWith("es")) {
    return "es";
  }
  if (tag.startsWith("fr")) {
    return "fr";
  }
  if (tag.startsWith("ja")) {
    return "ja";
  }
  if (tag.startsWith("ko")) {
    return "ko";
  }
  return tag;
}

async function dispatchCompletion({
  batchSize,
  projectId,
}: {
  batchSize: number;
  projectId: string;
}) {
  if (!serviceRoleKey) {
    return { skipped: true, reason: "missing_service_role" };
  }
  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/complete_due_journeys`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: anonKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify({ batch_size: batchSize }),
  });
  const text = await response.text();
  if (!response.ok) {
    return { skipped: false, success: false, status: response.status };
  }
  const rows = safeJsonArray(text);
  if (rows.length === 0) {
    return { skipped: false, success: true, notified: 0 };
  }
  const resultPushes = await Promise.allSettled(
    rows
      .filter((row) => row && typeof row.device_token === "string")
      .map(async (row) => {
        const journeyId = row.journey_id as string;
        const userId = row.user_id as string;
        const localeTag = normalizeLocaleTag(row.locale_tag as string | undefined);
        const text = resolveResultPushText(localeTag);
        const route = `/results/${journeyId}?highlight=1`;
        try {
          await sendResultFcm({
            token: row.device_token as string,
            journeyId,
            projectId,
            title: text.title,
            body: text.body,
            route,
          });
          await insertNotificationLog({
            userId,
            title: text.title,
            body: text.body,
            route,
            data: {
              type: "journey_result",
              journey_id: journeyId,
              fcm_status: "success",
            },
          });
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          console.error(`[dispatch] Result FCM failed for journey=${journeyId}, user=${userId}: ${errorMessage}`);
          await insertNotificationLog({
            userId,
            title: text.title,
            body: text.body,
            route,
            data: {
              type: "journey_result",
              journey_id: journeyId,
              fcm_status: "failed",
              fcm_error: errorMessage,
            },
          });
          throw error;
        }
      }),
  );
  const resultSuccess = resultPushes.filter((item) => item.status === "fulfilled")
    .length;
  const resultFailed = resultPushes.filter((item) => item.status === "rejected").length;
  if (resultFailed > 0) {
    console.error(`[dispatch] ${resultFailed} result FCM push(es) failed`);
  }
  return { skipped: false, success: true, notified: resultSuccess };
}

async function sendResultFcm({
  token,
  journeyId,
  projectId,
  title,
  body,
  route,
}: {
  token: string;
  journeyId: string;
  projectId: string;
  title: string;
  body: string;
  route: string;
}) {
  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token,
        notification: {
          title,
          body,
        },
        data: {
          route,
          journey_id: journeyId,
          type: "journey_result",
        },
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    // UNREGISTERED 토큰 무효화 처리
    if (response.status === 404 && body.includes("UNREGISTERED")) {
      console.log(`[dispatch] Invalidating UNREGISTERED token: ${token.substring(0, 20)}...`);
      await invalidateDeviceToken(token);
    }
    throw new Error(`fcm_result_error:${response.status}:${body}`);
  }
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: fcmClientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  try {
    const key = await importPrivateKey(fcmPrivateKey);
    const jwt = await new SignJWT(payload)
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .sign(key);
    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });
    if (!response.ok) {
      const body = await response.text();
      console.error(`[dispatch] OAuth2 token request failed: status=${response.status}, body=${body}`);
      throw new Error(`oauth_error:${response.status}:${body}`);
    }
    const data = await response.json();
    return data.access_token as string;
  } catch (error) {
    console.error(`[dispatch] getAccessToken failed: ${error instanceof Error ? error.message : String(error)}`);
    throw error;
  }
}

async function importPrivateKey(pem: string) {
  const cleaned = pem.replace(/\\n/g, "\n");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(cleaned),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
  return key;
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const raw = atob(base64);
  const buffer = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i += 1) {
    buffer[i] = raw.charCodeAt(i);
  }
  return buffer.buffer;
}

function safeJsonArray(payload: string): Record<string, unknown>[] {
  try {
    const parsed = JSON.parse(payload);
    if (Array.isArray(parsed)) {
      return parsed;
    }
  } catch (_) {
    return [];
  }
  return [];
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

async function insertNotificationLog({
  userId,
  title,
  body,
  route,
  data,
}: {
  userId: string;
  title: string;
  body: string;
  route: string;
  data: Record<string, unknown>;
}) {
  if (!serviceRoleKey) {
    return;
  }
  const response = await fetch(
    `${supabaseUrl}/rest/v1/rpc/insert_notification_log`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({
        _user_id: userId,
        _title: title,
        _body: body,
        _route: route,
        _data: data,
      }),
    },
  );
  if (!response.ok) {
    const bodyText = await response.text();
    console.error(`[dispatch] notification_log insert failed: ${response.status} - ${bodyText}`);
    throw new Error(`notification_log_failed:${response.status}:${bodyText}`);
  }
}

async function invalidateDeviceToken(token: string) {
  if (!serviceRoleKey) {
    console.warn(`[dispatch] Cannot invalidate token: missing service_role key`);
    return;
  }
  try {
    // RPC 호출로 변경 (RLS 우회)
    const response = await fetch(
      `${supabaseUrl}/rest/v1/rpc/invalidate_device_token`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
        body: JSON.stringify({
          p_token: token,
        }),
      },
    );
    if (!response.ok) {
      const bodyText = await response.text();
      console.error(`[dispatch] Token invalidation RPC failed: ${response.status} - ${bodyText}`);
    } else {
      console.log(`[dispatch] Token invalidated successfully: ${token.substring(0, 20)}...`);
    }
  } catch (error) {
    console.error(`[dispatch] Token invalidation error: ${error instanceof Error ? error.message : String(error)}`);
  }
}
