import { redirect } from "@sveltejs/kit";

export async function load({ locals }) {
  if (!locals.user) throw redirect(303, "/login");
  if (!locals.user.Roles.includes("admin")) throw redirect(303, "/");
  return {};
}
