//
// src/routes/projects/+page.server.ts
//
import { projectsGetSummaryPublic } from "$lib/server/vhRepo";
import { redirect } from "@sveltejs/kit";

function hasRole(user: any, role: string) {
  const roles: string[] = user?.Roles ?? [];
  return roles.includes(role) || roles.includes("admin");
}

export async function load({ locals, url }: any) {
  if (!locals.user) throw redirect(303, "/login");
  if (!hasRole(locals.user, "volhrs")) throw redirect(303, "/");

  return await projectsGetSummaryPublic( );
}
