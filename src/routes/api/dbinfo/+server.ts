import { json } from "@sveltejs/kit";
import { getPool } from "$lib/server/db";

export async function GET() {
  const pool = await getPool();
  const r = await pool.request().query(`
    SELECT
      DB_NAME() AS db,
      @@SERVERNAME AS servername,
      SUSER_SNAME() AS loginname
  `);
  return json(r.recordset[0]);
}