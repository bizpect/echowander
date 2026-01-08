import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { SignJWT } from "https://deno.land/x/jose@v4.15.4/index.ts";

const encoder = new TextEncoder();
const jwtSecret = Deno.env.get("JWT_SECRET") ?? "";
const jwtIssuer = Deno.env.get("JWT_ISSUER") ?? "echowander";
const jwtAudience = Deno.env.get("JWT_AUDIENCE") ?? "echowander";
const accessTtlSeconds = Number(Deno.env.get("ACCESS_TTL_SECONDS") ?? 900);
const refreshTtlSeconds = Number(Deno.env.get("REFRESH_TTL_SECONDS") ?? 2592000);

serve(async (request) => {
  // ✅ 코드 진입 여부를 1초 만에 확정하는 hit 로그 (게이트 차단 vs 내부 로직 분기)
  const hasAuth = !!request.headers.get("Authorization");
  const hasApiKey = !!request.headers.get("apikey");
  console.log("[refresh_session] hit", { hasAuth, hasApiKey });

  if (!jwtSecret) {
    return new Response(JSON.stringify({ error: "missing_secret" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  const body = await request.json().catch(() => ({}));
  // ✅ SSOT: 요청 body 키를 refresh_token으로 통일 (클라이언트와 동일)
  const refreshToken = body.refresh_token as string | undefined;
  if (!refreshToken) {
    return new Response(JSON.stringify({ error: "missing_refresh" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  // ✅ 불변식 검사: refresh_token이 JWT 형태(점 2개)면 안 됨
  const refreshTokenDotCount = (refreshToken.match(/\./g) || []).length;
  if (refreshTokenDotCount >= 2) {
    // refresh_token이 JWT 형태면 치명적 매핑 오류 (access_token을 잘못 매핑한 것)
    const refreshTokenFingerprint = refreshToken.substring(0, 12);
    console.error(
      `[refresh_session] ⚠️ 치명적 토큰 매핑 오류: refresh_token이 JWT 형태입니다 ` +
        `(fp=${refreshTokenFingerprint}, len=${refreshToken.length}, dots=${refreshTokenDotCount})`,
    );
    return new Response(
      JSON.stringify({
        error: "server_misconfigured_refresh_token",
        msg: "refresh_token must not be JWT format",
      }),
      {
        status: 500,
        headers: { "content-type": "application/json" },
      },
    );
  }

  try {
    // ✅ refresh_token 검증: HMAC 서명 검증
    // 형식: base64url(userId:timestamp:random) + "." + base64url(HMAC)
    const parts = refreshToken.split(".");
    if (parts.length !== 2) {
      return new Response(JSON.stringify({ error: "invalid_refresh" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const [payloadBase64, signatureBase64] = parts;
    const payload = atob(payloadBase64.replace(/-/g, "+").replace(/_/g, "/"));
    const [userId, timestampStr, randomString] = payload.split(":");

    if (!userId || !timestampStr || !randomString) {
      return new Response(JSON.stringify({ error: "invalid_refresh" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    // HMAC 서명 검증
    const payloadBytes = encoder.encode(payload);
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(jwtSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    const signatureBytes = Uint8Array.from(
      atob(signatureBase64.replace(/-/g, "+").replace(/_/g, "/")),
      (c) => c.charCodeAt(0),
    );
    const isValid = await crypto.subtle.verify("HMAC", key, signatureBytes, payloadBytes);

    if (!isValid) {
      return new Response(JSON.stringify({ error: "invalid_refresh" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    // 만료 시간 검증
    const timestamp = parseInt(timestampStr, 10);
    const now = Math.floor(Date.now() / 1000);
    if (now - timestamp > refreshTtlSeconds) {
      return new Response(JSON.stringify({ error: "invalid_refresh" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    // 새 access_token 발급
    const accessToken = await new SignJWT({ typ: "access", role: "authenticated" })
      .setProtectedHeader({ alg: "HS256", typ: "JWT" })
      .setIssuer(jwtIssuer)
      .setAudience(jwtAudience)
      .setSubject(userId)
      .setIssuedAt(now)
      .setExpirationTime(now + accessTtlSeconds)
      .sign(encoder.encode(jwtSecret));

    // 새 refresh_token 발급 (동일한 형식)
    const newRandomBytes = new Uint8Array(32);
    crypto.getRandomValues(newRandomBytes);
    const newRandomString = btoa(String.fromCharCode(...newRandomBytes))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
    const newPayload = `${userId}:${now}:${newRandomString}`;
    const newPayloadBytes = encoder.encode(newPayload);
    const newKey = await crypto.subtle.importKey(
      "raw",
      encoder.encode(jwtSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const newSignature = await crypto.subtle.sign("HMAC", newKey, newPayloadBytes);
    const newSignatureBase64 = btoa(String.fromCharCode(...new Uint8Array(newSignature)))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
    const newPayloadBase64 = btoa(newPayload)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
    const newRefreshToken = `${newPayloadBase64}.${newSignatureBase64}`;

    // ✅ 불변식 검사: 새 refresh_token이 JWT 형태가 아니어야 함
    const newRefreshTokenDotCount = (newRefreshToken.match(/\./g) || []).length;
    if (newRefreshTokenDotCount >= 2) {
      const newRefreshTokenFingerprint = newRefreshToken.substring(0, 12);
      console.error(
        `[refresh_session] ⚠️ 치명적 토큰 매핑 오류: 새 refresh_token이 JWT 형태입니다 ` +
          `(fp=${newRefreshTokenFingerprint}, len=${newRefreshToken.length}, dots=${newRefreshTokenDotCount})`,
      );
      return new Response(
        JSON.stringify({
          error: "server_misconfigured_refresh_token",
          msg: "refresh_token must not be JWT format",
        }),
        {
          status: 500,
          headers: { "content-type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        access_token: accessToken,
        refresh_token: newRefreshToken,
      }),
      {
        status: 200,
        headers: { "content-type": "application/json" },
      },
    );
  } catch (_error) {
    return new Response(JSON.stringify({ error: "invalid_refresh" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }
});
