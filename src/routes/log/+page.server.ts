//
// src/routes/log/+page.server.ts
//
import { fail } from "@sveltejs/kit";
import { projectsGetForUser, timeEntriesInsert } from "$lib/server/vhRepo";
import { redirect } from "@sveltejs/kit";

function hasRole(user, role) {
  return user?.Roles?.includes(role) || user?.Roles?.includes("admin");
}

export async function load({ locals, url }) {
  console.log("LOG PAGE LOAD", url.pathname);

  if (!locals.user) throw redirect(303, "/login");
  if (!hasRole(locals.user, "volhrs")) throw redirect(303, "/");

  return { projects: await projectsGetForUser({ userId: locals.user.UserId }) };
};

/* ---------- helpers ---------- */

function parseHoursToMinutes(raw: string): { minutes: number } | { error: string } {
  let s = (raw ?? "").trim();
  if (!s) return { error: "Hours is required." };

  // Allow shorthand:
  //  - ":15" -> "0:15"
  //  - ".5"  -> "0.5"
  if (s.startsWith(":")) s = `0${s}`;
  if (s.startsWith(".")) s = `0${s}`;

  // H:MM format (allow H=0 too, but minutes must end up > 0)
  if (s.includes(":")) {
    const m = /^(\d+):([0-5]\d)$/.exec(s);
    if (!m) return { error: "Hours must be H:MM (e.g. 1:30 or :15)." };
    const h = Number(m[1]);
    const mm = Number(m[2]);
    const minutes = h * 60 + mm;
    if (minutes <= 0) return { error: "Time must be greater than 0." };
    return { minutes };
  }

  // Decimal hours (allow 2, 1.5, 0.25, .5 (normalized above))
  if (!/^\d+(\.\d+)?$/.test(s)) {
    return { error: "Hours must be like 2, 1.5, .5, 0.25, 1:30, or :15." };
  }

  const hours = Number(s);
  if (!Number.isFinite(hours)) return { error: "Invalid hours number." };

  // Convert to minutes; round to nearest minute
  const minutes = Math.round(hours * 60);
  if (minutes <= 0) return { error: "Time must be greater than 0." };
  return { minutes };
}

/* ---------- form action ---------- */

export const actions = {
  default: async ({ request, locals }) => {
    if (!locals.user) throw redirect(303, "/login");

    const fd = await request.formData();

    const projectId = Number(fd.get("projectId"));
    const entryDateStr = String(fd.get("entryDate") ?? "").trim();
    const hoursRaw = String(fd.get("hours") ?? "").trim();
    const notes = String(fd.get("notes") ?? "").trim() || null;

    const values = {
      projectId: projectId || "",
      entryDate: entryDateStr,
      hours: hoursRaw,
      notes: notes ?? ""
    };

    if (!projectId) {
      return fail(400, { error: "Project is required.", values });
    }

    if (!entryDateStr || !/^\d{4}-\d{2}-\d{2}$/.test(entryDateStr)) {
      return fail(400, { error: "Valid date is required.", values });
    }

    const parsed = parseHoursToMinutes(hoursRaw);
    if ("error" in parsed) {
      return fail(400, { error: parsed.error, values });
    }

    // Avoid timezone drift (use noon local time)
    const entryDate = new Date(`${entryDateStr}T12:00:00`);

    try {
      await timeEntriesInsert({
        userId: locals.user.UserId,
        projectId,
        entryDate,
        minutes: parsed.minutes,
        notes
      });

      return {
        ok: true,
        values: { entryDate: entryDateStr } // keep date, clear rest
      };
    } catch (e: any) {
      console.error("LOG SAVE FAILED:", e);
      return fail(500, { error: "Failed to save log entry.", values });
    }
  }
};
