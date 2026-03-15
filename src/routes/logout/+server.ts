import { redirect } from "@sveltejs/kit";
import { sessionsDelete } from "$lib/server/vhRepo";

const COOKIE_NAME = "vh_session";

export async function POST({ cookies }) {
  const token = cookies.get(COOKIE_NAME);
  if (token) await sessionsDelete(token);

  cookies.delete(COOKIE_NAME, { path: "/" });
  throw redirect(303, "/");
}
