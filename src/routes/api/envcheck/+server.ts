import { json } from "@sveltejs/kit";
import { env } from "$env/dynamic/private";

export async function GET() {
  return json({
    MSSQL_HOST: env.MSSQL_HOST ?? null,
    MSSQL_PORT: env.MSSQL_PORT ?? null,
    MSSQL_DB: env.MSSQL_DB ?? null,
    HAS_PASSWORD: Boolean(env.MSSQL_SA_PASSWORD),
    PASSWORD_LEN: env.MSSQL_SA_PASSWORD?.length ?? 0
  });
}
