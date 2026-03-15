import { json } from "@sveltejs/kit";
import { getPool } from "$lib/server/db";

export async function GET() {
  const pool = await getPool();

  const db = await pool.request().query("SELECT DB_NAME() AS db");
  const cnt = await pool.request().query("SELECT COUNT(*) AS cnt FROM vh.Projects");

  const proc = await pool.request().execute("vh.Projects_ListAll");

  return json({
    db: db.recordset[0]?.db,
    tableCount: cnt.recordset[0]?.cnt,
    procRecordsetLen: proc.recordset?.length ?? null,
    procRecordsetsLens: proc.recordsets?.map((rs) => rs.length) ?? null,
    sample: (proc.recordset ?? []).slice(0, 5)
  });
}
