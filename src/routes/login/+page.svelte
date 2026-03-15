<script lang="ts">
  import { enhance } from '$app/forms';
  import { goto } from '$app/navigation';
  export let form;
  const v = form?.values ?? { loginName: "" };

  const debug =
    typeof window !== 'undefined' &&
    new URL(window.location.href).searchParams.get('debug') === '1';

  let diag: string[] = [];

  function log(m: string) {
    diag = [`${new Date().toISOString()} ${m}`, ...diag].slice(0, 200);
  }

  async function probeDb() {
    try {
      log('DB probe: GET /api/diag/db?debug=1');
      const r = await fetch('/api/diag/db?debug=1');
      const t = await r.text();
      log(`DB probe: status=${r.status} body=${t}`);
    } catch (e: any) {
      log(`DB probe: fetch error: ${e?.message ?? e}`);
    }
  }
</script>

<h1>Login</h1>

<form method="POST"
 style="max-width: 520px; display: grid; gap: 12px;"
  use:enhance={() => {
    log('FORM submit fired');
    return async ({ result }) => {
      console.log('[login] result:', result);

      // If the server throws redirect(...)
      if (result.type === 'redirect') {
        window.location.assign(result.location ?? '/');
        return;
      }

      // If the server returns success data instead of redirect
      if (result.type === 'success') {
        window.location.assign('/');
        return;
      };
    };
  }
} >
  <label>
    Login name
    <input name="loginName" required autocomplete="username" value={v.loginName} autofocus />
  </label>

  <label>
    Password
    <input name="password" type="password" required autocomplete="current-password" />
  </label>

  <button type="submit">Login</button>

</form>
{#if debug}
  <div style="border:1px solid #999;padding:12px;margin-top:16px;font-family:monospace">
    <div style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
      <b>LOGIN DIAGNOSTICS (debug=1)</b>
      <button type="button" on:click={probeDb}>Probe DB</button>
    </div>
    <div style="max-height:240px;overflow:auto;white-space:pre-wrap">
      {diag.join('\n')}
    </div>
  </div>
{/if}
