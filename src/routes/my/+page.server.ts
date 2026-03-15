//
// src/routes/my/+page.server.ts
//
import { timeEntriesGetByUser } from "$lib/server/vhRepo";
import { redirect } from "@sveltejs/kit";

function hasRole(user: any, role: string) {
  const roles: string[] = user?.Roles ?? [];
  return roles.includes(role) || roles.includes("admin");
}

export async function load({ locals, url }: any) {
  if (!locals.user) throw redirect(303, "/login");
  if (!hasRole(locals.user, "volhrs")) throw redirect(303, "/");

  // Use the authenticated user id (NOT an env var)
  const userIdRaw = locals.user?.UserId ?? locals.user?.userId ?? locals.user?.id;
  const userId = Number(userIdRaw);

  if (!Number.isFinite(userId) || userId <= 0) {
    // If this trips, your session user object isn't carrying the DB UserId
    throw redirect(303, "/login");
  }

  const { entries, totalMinutes } = await timeEntriesGetByUser(userId);
  return { entries, totalMinutes };
}
