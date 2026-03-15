import sql from "mssql";
import { env } from "$env/dynamic/private";

const config: sql.config = {
  user: "sa",
  password: env.MSSQL_SA_PASSWORD,
  server: env.MSSQL_HOST ?? "127.0.0.1",
  port: Number(env.MSSQL_PORT ?? 1433),
  database: env.MSSQL_DB ?? "VolHrs",
  options: { encrypt: false, trustServerCertificate: true }
};

let pool: sql.ConnectionPool | null = null;
let poolPromise: Promise<sql.ConnectionPool> | null = null;

export async function getPool(): Promise<sql.ConnectionPool> {
  if (pool && pool.connected) {
    return pool;
  }

  if (!poolPromise) {
    console.log("Creating new SQL connection pool...");
    poolPromise = new sql.ConnectionPool(config)
      .connect()
      .then(async (p) => {
        pool = p;

        const r = await p.request().query("SELECT DB_NAME() as Db");
        console.log("Connected to DB:", r.recordset[0].Db);

        p.on("error", (err) => {
          console.error("SQL pool error:", err);
          pool = null;
          poolPromise = null;
        });

        return p;
      })
      .catch((err) => {
        poolPromise = null;
        throw err;
      });
  }

  return poolPromise;
}
