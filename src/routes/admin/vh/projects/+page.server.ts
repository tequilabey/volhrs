import { fail } from "@sveltejs/kit";
import { projectsDelete, projectsListAll, projectsUpsert } from "$lib/server/vhRepo";

function asStr(v: FormDataEntryValue | null) {
  return typeof v === "string" ? v : "";
}

function asInt(v: FormDataEntryValue | null) {
  const n = Number(asStr(v));
  return Number.isFinite(n) ? n : 0;
}

function asBool(v: FormDataEntryValue | null) {
  const s = asStr(v).toLowerCase();
  return s === "1" || s === "true" || s === "on" || s === "yes";
}

import { getPool } from "$lib/server/db";

export async function load() {
  console.log("EDIT PROJECTS loader HIT:", import.meta.url);
    const pool = await getPool();
  const r = await pool.request().execute("vh.Projects_ListAll");
  return { projects: r.recordset };
}

/*import { getPool } from "$lib/server/db";

export async function load() {
  const pool = await getPool();
  const db = await pool.request().query("SELECT DB_NAME() AS db");
  const projects = await projectsListAll();
  return { projects, db: db.recordset[0].db };
}*/


export const actions = {
  upsert: async ({ request }) => {
    const fd = await request.formData();
    const projectId = asInt(fd.get("projectId")) || null;
    const name = asStr(fd.get("name")).trim();
    const isPublic = asBool(fd.get("isPublic"));

    if (!name) return fail(400, { error: "Project name is required." });

    try {
      await projectsUpsert({ projectId, name, isPublic });
      return { ok: true };
    } catch (e: any) {
      return fail(400, { error: String(e?.message ?? "Save failed.") });
    }
  },

  delete: async ({ request }) => {
    const fd = await request.formData();
    const projectId = asInt(fd.get("projectId"));

    if (!projectId) return fail(400, { error: "Missing project id." });

    try {
      await projectsDelete(projectId);
      return { ok: true };
    } catch (e: any) {
      // common: FK constraint due to existing TimeEntries
      return fail(400, { error: String(e?.message ?? "Delete failed.") });
    }
  }
};
