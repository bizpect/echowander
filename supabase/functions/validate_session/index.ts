import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { jwtVerify } from "https://deno.land/x/jose@v4.15.4/index.ts";

const encoder = new TextEncoder();
const jwtSecret = Deno.env.get("JWT_SECRET") ?? "";
const jwtIssuer = Deno.env.get("JWT_ISSUER") ?? undefined;
const jwtAudience = Deno.env.get("JWT_AUDIENCE") ?? undefined;

serve(async (request) => {
  if (!jwtSecret) {
    return new Response(JSON.stringify({ valid: false, reason: "missing_secret" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  const authHeader = request.headers.get("authorization") ?? "";
  const token = authHeader.replace("Bearer ", "").trim();

  if (!token) {
    return new Response(JSON.stringify({ valid: false }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  try {
    const { payload } = await jwtVerify(token, encoder.encode(jwtSecret), {
      issuer: jwtIssuer,
      audience: jwtAudience,
    });

    if (payload.typ !== "access") {
      return new Response(JSON.stringify({ valid: false }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ valid: true, sub: payload.sub }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (_error) {
    return new Response(JSON.stringify({ valid: false }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }
});
