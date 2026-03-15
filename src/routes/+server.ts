import { json } from "@sveltejs/kit";
import { getPool } from "$lib/server/db";

export async function GET() {
  const pool = await getPool();
  const r = await pool.request().query("SELECT 1 AS ok, SYSUTCDATETIME() AS nowUtc");
  return json(r.recordset[0]);
}
