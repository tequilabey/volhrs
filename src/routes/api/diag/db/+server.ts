import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
  if (url.searchParams.get('debug') !== '1') {
    return new Response('Not found', { status: 404 });
  }

  const started = Date.now();

  try {
    // Dynamic import so even import-time failures get caught and returned as JSON
    const mod = await import('$lib/server/db');

    const getPool = (mod as any).getPool;
    if (typeof getPool !== 'function') {
      console.error('[DIAG DB] getPool export missing. exports=', Object.keys(mod as any));
      return json(
        {
          ok: false,
          ms: Date.now() - started,
          error: { stage: 'import', message: 'getPool export missing', exports: Object.keys(mod as any) }
        },
        { status: 500 }
      );
    }

    const pool = await getPool();
    const r = await pool.request().query('SELECT 1 as ok');

    return json({
      ok: true,
      ms: Date.now() - started,
      result: r?.recordset?.[0] ?? null
    });
  } catch (err: any) {
    console.error('[DIAG DB] exception:', err);
    return json(
      {
        ok: false,
        ms: Date.now() - started,
        error: {
          stage: 'exception',
          name: err?.name ?? null,
          message: err?.message ?? String(err),
          code: err?.code ?? null
        }
      },
      { status: 500 }
    );
  }
};
