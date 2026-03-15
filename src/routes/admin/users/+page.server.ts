import { fail } from "@sveltejs/kit";
import {
  rolesGrant,
  rolesRevoke,
  usersDeleteAdmin,
  usersListAllAdmin,
  usersSetPasswordAdmin,
  usersUpsertAdmin
} from "$lib/server/vhRepo";

function s(v: FormDataEntryValue | null) { return typeof v === "string" ? v : ""; }
function i(v: FormDataEntryValue | null) { const n = Number(s(v)); return Number.isFinite(n) ? n : 0; }

export async function load() {
  const users = await usersListAllAdmin();
  return { users };
}

export const actions = {
  upsert: async ({ request }) => {
    const fd = await request.formData();
    const userId = i(fd.get("userId")) || null;

    const loginName = s(fd.get("loginName")).trim();
    const firstName = s(fd.get("firstName")).trim();
    const lastName  = s(fd.get("lastName")).trim();
    const email     = s(fd.get("email")).trim();
    const mobile    = s(fd.get("mobile")).trim();

    if (!loginName || !firstName || !lastName) {
      return fail(400, { error: "Login name, first name, and last name are required." });
    }

    try {
      const r = await usersUpsertAdmin({
        userId, loginName, firstName, lastName,
        email: email || null,
        mobile: mobile || null
      });
      return { ok: true, userId: r.userId };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Save failed.") });
    }
  },

  setPassword: async ({ request }) => {
    const fd = await request.formData();
    const userId = i(fd.get("userId"));
    const password = s(fd.get("password"));

    if (!userId) return fail(400, { error: "Missing user id." });

    try {
      await usersSetPasswordAdmin({ userId, password });
      return { ok: true };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Password set failed.") });
    }
  },

  grantRole: async ({ request }) => {
    const fd = await request.formData();
    const userId = i(fd.get("userId"));
    const roleCode = s(fd.get("roleCode")).trim().toLowerCase();
    if (!userId || !roleCode) return fail(400, { error: "Missing user id or role." });

    try {
      await rolesGrant({ userId, roleCode });
      return { ok: true };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Grant failed.") });
    }
  },

  revokeRole: async ({ request }) => {
    const fd = await request.formData();
    const userId = i(fd.get("userId"));
    const roleCode = s(fd.get("roleCode")).trim().toLowerCase();
    if (!userId || !roleCode) return fail(400, { error: "Missing user id or role." });

    try {
      await rolesRevoke({ userId, roleCode });
      return { ok: true };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Revoke failed.") });
    }
  },

  delete: async ({ request }) => {
    const fd = await request.formData();
    const userId = i(fd.get("userId"));
    if (!userId) return fail(400, { error: "Missing user id." });

    try {
      await usersDeleteAdmin(userId);
      return { ok: true };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Delete failed (likely FK constraints).") });
    }
  }
};