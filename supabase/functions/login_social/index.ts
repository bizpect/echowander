import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  SignJWT,
  createRemoteJWKSet,
  jwtVerify,
} from "https://deno.land/x/jose@v4.15.4/index.ts";

const encoder = new TextEncoder();
const jwtSecret = Deno.env.get("JWT_SECRET") ?? "";
const jwtIssuer = Deno.env.get("JWT_ISSUER") ?? "echowander";
const jwtAudience = Deno.env.get("JWT_AUDIENCE") ?? "echowander";
const accessTtlSeconds = Number(Deno.env.get("ACCESS_TTL_SECONDS") ?? 900);
const refreshTtlSeconds = Number(Deno.env.get("REFRESH_TTL_SECONDS") ?? 2592000);

const googleClientId = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const appleClientId = Deno.env.get("APPLE_CLIENT_ID") ?? "";
const allowDevSocial = (Deno.env.get("ALLOW_DEV_SOCIAL") ?? "false") === "true";
const namespaceUuid = Deno.env.get("USER_NAMESPACE_UUID") ?? "6f1c219a-7b12-4ce0-9f30-9d9f1b3db6d1";

const supabaseUrl = Deno.env.get("APP_SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("APP_SUPABASE_ANON_KEY") ?? "";

const googleJwks = createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs"));
const appleJwks = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

serve(async (request) => {
  if (!jwtSecret) {
    return jsonResponse({ error: "missing_secret" }, 500);
  }

  const body = await request.json().catch(() => ({}));
  const provider = body.provider as string | undefined;
  const idToken = body.idToken as string | undefined;

  if (!provider || !idToken) {
    await logLoginAttempt({ loginTypeCode: "unknown", result: "failed" });
    return jsonResponse({ error: "missing_payload" }, 400);
  }

  let providerSubject: string | null = null;

  try {
    if (allowDevSocial && idToken === "dev") {
      providerSubject = "dev";
    } else {
      switch (provider) {
        case "google":
          providerSubject = await verifyGoogle(idToken);
          break;
        case "apple":
          providerSubject = await verifyApple(idToken);
          break;
        case "kakao":
          providerSubject = await verifyKakao(idToken);
          break;
        default:
          await logLoginAttempt({ loginTypeCode: "unknown", result: "failed" });
          return jsonResponse({ error: "unsupported_provider" }, 400);
      }
    }
  } catch (_error) {
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse({ error: "invalid_token" }, 401);
  }

  if (!providerSubject) {
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse({ error: "invalid_token" }, 401);
  }

  const userId = await uuidV5(`${provider}:${providerSubject}`, namespaceUuid);
  const now = Math.floor(Date.now() / 1000);

  const accessToken = await new SignJWT({ typ: "access", role: "authenticated" })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer(jwtIssuer)
    .setAudience(jwtAudience)
    .setSubject(userId)
    .setIssuedAt(now)
    .setExpirationTime(now + accessTtlSeconds)
    .sign(encoder.encode(jwtSecret));

  // ✅ refresh_token은 JWT가 아닌 HMAC 서명 토큰으로 생성
  // 형식: base64url(userId:timestamp:random) + "." + base64url(HMAC)
  // 점이 1개만 있으므로 JWT(점 2개)와 구분됨
  const randomBytes = new Uint8Array(32);
  crypto.getRandomValues(randomBytes);
  const randomString = btoa(String.fromCharCode(...randomBytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const payload = `${userId}:${now}:${randomString}`;
  const payloadBytes = encoder.encode(payload);
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(jwtSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, payloadBytes);
  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const payloadBase64 = btoa(payload)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
  const refreshToken = `${payloadBase64}.${signatureBase64}`;

  // ✅ 불변식 검사: access_token은 JWT여야 함 (점 2개)
  const accessTokenDotCount = (accessToken.match(/\./g) || []).length;
  if (accessTokenDotCount !== 2) {
    const accessTokenFingerprint = accessToken.substring(0, 12);
    console.error(
      `[login_social] ⚠️ 치명적 토큰 매핑 오류: access_token이 JWT 형태가 아닙니다 ` +
        `(fp=${accessTokenFingerprint}, len=${accessToken.length}, dots=${accessTokenDotCount})`,
    );
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse(
      {
        error: "server_misconfigured_access_token",
        msg: "access_token must be JWT format",
      },
      500,
    );
  }

  // ✅ 불변식 검사: refresh_token은 JWT가 아니어야 함 (점 2개면 안 됨)
  const refreshTokenDotCount = (refreshToken.match(/\./g) || []).length;
  if (refreshTokenDotCount >= 2) {
    // refresh_token이 JWT 형태(점 2개)면 치명적 매핑 오류
    const refreshTokenFingerprint = refreshToken.substring(0, 12);
    console.error(
      `[login_social] ⚠️ 치명적 토큰 매핑 오류: refresh_token이 JWT 형태입니다 ` +
        `(fp=${refreshTokenFingerprint}, len=${refreshToken.length}, dots=${refreshTokenDotCount})`,
    );
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse(
      {
        error: "server_misconfigured_refresh_token",
        msg: "refresh_token must not be JWT format",
      },
      500,
    );
  }

  // ✅ 불변식 검사: refresh_token이 access_token과 같은 값으로 매핑되는 치명적 오류 방지
  if (refreshToken === accessToken) {
    const accessTokenFingerprint = accessToken.substring(0, 12);
    const refreshTokenFingerprint = refreshToken.substring(0, 12);
    console.error(
      `[login_social] ⚠️ 치명적 토큰 매핑 오류: refresh_token이 access_token과 동일합니다 ` +
        `(accessFp=${accessTokenFingerprint}, refreshFp=${refreshTokenFingerprint}, len=${refreshToken.length})`,
    );
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse(
      {
        error: "server_misconfigured_refresh_token",
        msg: "refresh_token must not equal access_token",
      },
      500,
    );
  }

  const synced = await syncUser(accessToken, provider, providerSubject);
  if (!synced) {
    await logLoginAttempt({ loginTypeCode: provider ?? "unknown", result: "failed" });
    return jsonResponse({ error: "user_sync_failed" }, 500);
  }

  await logLoginAttempt({
    loginTypeCode: provider ?? "unknown",
    result: "success",
    accessToken,
  });

  // ✅ SSOT: 응답 JSON 키를 access_token/refresh_token으로 통일
  return jsonResponse({ access_token: accessToken, refresh_token: refreshToken }, 200);
});

async function verifyGoogle(idToken: string): Promise<string> {
  if (!googleClientId) {
    throw new Error("missing_google_client_id");
  }
  const { payload } = await jwtVerify(idToken, googleJwks, {
    issuer: ["https://accounts.google.com", "accounts.google.com"],
    audience: googleClientId,
  });
  return payload.sub ?? "";
}

async function verifyApple(idToken: string): Promise<string> {
  if (!appleClientId) {
    throw new Error("missing_apple_client_id");
  }
  const { payload } = await jwtVerify(idToken, appleJwks, {
    issuer: "https://appleid.apple.com",
    audience: appleClientId,
  });
  return payload.sub ?? "";
}

async function verifyKakao(accessToken: string): Promise<string> {
  const response = await fetch("https://kapi.kakao.com/v1/user/access_token_info", {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error("invalid_kakao_token");
  }
  const payload = (await response.json()) as { id?: number };
  return payload.id?.toString() ?? "";
}

async function syncUser(
  accessToken: string,
  provider: string,
  providerSubject: string,
): Promise<boolean> {
  if (!supabaseUrl || !anonKey) {
    return false;
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/create_or_get_user`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      authorization: `Bearer ${accessToken}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      _provider: provider,
      _provider_subject: providerSubject,
      _login_type_code: provider,
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    console.error("syncUser failed", response.status, body);
    return false;
  }
  return true;
}

async function logLoginAttempt(params: {
  loginTypeCode: string;
  result: "success" | "failed";
  accessToken?: string;
}): Promise<void> {
  if (!supabaseUrl || !anonKey) {
    console.error("logLoginAttempt missing supabase config");
    return;
  }

  const headers: Record<string, string> = {
    apikey: anonKey,
    "content-type": "application/json",
  };
  if (params.accessToken) {
    headers.authorization = `Bearer ${params.accessToken}`;
  }

  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/log_login_attempt`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      _login_type_code: params.loginTypeCode,
      _result: params.result,
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    console.error("logLoginAttempt failed", response.status, body);
  }
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

async function uuidV5(name: string, namespace: string): Promise<string> {
  const namespaceBytes = parseUuid(namespace);
  const nameBytes = encoder.encode(name);

  const buffer = new Uint8Array(namespaceBytes.length + nameBytes.length);
  buffer.set(namespaceBytes);
  buffer.set(nameBytes, namespaceBytes.length);

  const hash = new Uint8Array(await crypto.subtle.digest("SHA-1", buffer));
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;

  const hex = [...hash.slice(0, 16)].map((b) => b.toString(16).padStart(2, "0"));
  return `${hex.slice(0, 4).join("")}-${hex.slice(4, 6).join("")}-${hex
    .slice(6, 8)
    .join("")}-${hex.slice(8, 10).join("")}-${hex.slice(10, 16).join("")}`;
}

function parseUuid(value: string): Uint8Array {
  const hex = value.replaceAll("-", "");
  if (hex.length !== 32) {
    throw new Error("invalid_namespace_uuid");
  }
  const bytes = new Uint8Array(16);
  for (let i = 0; i < 16; i += 1) {
    bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}
