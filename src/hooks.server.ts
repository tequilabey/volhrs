import type { Handle } from "@sveltejs/kit";
import { sessionsGetUserByToken, sessionsTouch } from "$lib/server/vhRepo";

const COOKIE_NAME = "vh_session";
const DAYS_90_MS = 90 * 24 * 60 * 60 * 1000;

export const handle: Handle = async ({ event, resolve }) => {
  const token = event.cookies.get(COOKIE_NAME) ?? null;

  event.locals.user = null;
  event.locals.sessionToken = token;
  event.locals.sessionId = null;
  event.locals.roles = [];

  if (token) {
    const u = await sessionsGetUserByToken(token);
    if (u) {
      const roles = (u.Roles ?? []).map((r: any) => String(r?.RoleCode ?? r?.roleCode ?? r).trim().toLowerCase()).filter(Boolean);
      const rolesDedup = Array.from(new Set(roles));
      event.locals.user = { UserId: u.UserId, LoginName: u.LoginName, FirstName: u.FirstName, LastName: u.LastName, Roles: rolesDedup };
      event.locals.sessionId = u.sessionId;
      event.locals.roles = rolesDedup;

      // rolling expiry: push it out 90 days on activity
      const newExp = new Date(Date.now() + DAYS_90_MS);
      await sessionsTouch({ sessionId: u.sessionId, newExpiresAtUtc: newExp });

      // cookie: 90 days, HttpOnly.
      // secure: true only on HTTPS (prod); on localhost you need secure=false.
      event.cookies.set(COOKIE_NAME, token, {
        path: "/",
        httpOnly: true,
        sameSite: "lax",
        secure: event.url.protocol === "https:",
        maxAge: 90 * 24 * 60 * 60
      });
    } else {
      // invalid/expired token -> clear cookie
      event.cookies.delete(COOKIE_NAME, { path: "/" });
    }
  }

  return resolve(event);
};
