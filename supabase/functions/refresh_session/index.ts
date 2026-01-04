import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { jwtVerify, SignJWT } from "https://deno.land/x/jose@v4.15.4/index.ts";

const encoder = new TextEncoder();
const jwtSecret = Deno.env.get("JWT_SECRET") ?? "";
const jwtIssuer = Deno.env.get("JWT_ISSUER") ?? "echowander";
const jwtAudience = Deno.env.get("JWT_AUDIENCE") ?? "echowander";
const accessTtlSeconds = Number(Deno.env.get("ACCESS_TTL_SECONDS") ?? 900);
const refreshTtlSeconds = Number(Deno.env.get("REFRESH_TTL_SECONDS") ?? 2592000);

serve(async (request) => {
  if (!jwtSecret) {
    return new Response(JSON.stringify({ error: "missing_secret" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  const body = await request.json().catch(() => ({}));
  const refreshToken = body.refreshToken as string | undefined;
  if (!refreshToken) {
    return new Response(JSON.stringify({ error: "missing_refresh" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  try {
    const { payload } = await jwtVerify(refreshToken, encoder.encode(jwtSecret), {
      issuer: jwtIssuer,
      audience: jwtAudience,
    });

    if (payload.typ !== "refresh") {
      return new Response(JSON.stringify({ error: "invalid_refresh" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const subject = payload.sub ?? "";
    if (!subject) {
      return new Response(JSON.stringify({ error: "invalid_sub" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const now = Math.floor(Date.now() / 1000);
    const accessToken = await new SignJWT({ typ: "access", role: "authenticated" })
      .setProtectedHeader({ alg: "HS256" })
      .setIssuer(jwtIssuer)
      .setAudience(jwtAudience)
      .setSubject(subject)
      .setIssuedAt(now)
      .setExpirationTime(now + accessTtlSeconds)
      .sign(encoder.encode(jwtSecret));

    const newRefreshToken = await new SignJWT({ typ: "refresh", role: "authenticated" })
      .setProtectedHeader({ alg: "HS256" })
      .setIssuer(jwtIssuer)
      .setAudience(jwtAudience)
      .setSubject(subject)
      .setIssuedAt(now)
      .setExpirationTime(now + refreshTtlSeconds)
      .sign(encoder.encode(jwtSecret));

    return new Response(JSON.stringify({
      accessToken,
      refreshToken: newRefreshToken,
    }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (_error) {
    return new Response(JSON.stringify({ error: "invalid_refresh" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }
});
