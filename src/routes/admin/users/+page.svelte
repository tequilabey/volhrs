<script lang="ts">
  export let data: {
    users: {
      UserId: number;
      LoginName: string;
      FirstName: string;
      LastName: string;
      Email: string | null;
      Mobile: string | null;
      Roles: string[];
    }[];
  };

  export let form: { ok?: boolean; error?: string; userId?: number } | null;

  const users = data.users ?? [];
  const roleSet = (u: any) => new Set((u.Roles ?? []).map((r: string) => r.toLowerCase()));
</script>

<h1>Users</h1>

{#if form?.error}
  <p style="color:#b00020;">{form.error}</p>
{:else if form?.ok}
  <p style="color:green;">Saved.</p>
{/if}

<h2>Add User</h2>
<h2>Add User</h2>
<form method="POST" action="?/create" style="display:grid; gap:10px; max-width:680px; margin-bottom:18px;">
  <label>Login name <input name="loginName" required autofocus /></label>
  <label>First name <input name="firstName" required /></label>
  <label>Last name <input name="lastName" required /></label>
  <label>Email <input name="email" type="email" /></label>
  <label>Mobile <input name="mobile" type="tel" /></label>

  <fieldset style="border:1px solid #ddd; border-radius:8px; padding:10px;">
    <legend style="padding:0 6px; font-weight:700;">Roles</legend>
    <label style="display:flex; align-items:center; gap:8px; margin:6px 0;">
      <input type="checkbox" name="roles" value="volhrs" checked />
      volhrs
    </label>
    <label style="display:flex; align-items:center; gap:8px; margin:6px 0;">
      <input type="checkbox" name="roles" value="admin" />
      admin
    </label>
  </fieldset>

  <button type="submit">Create User</button>

  <div style="opacity:.7; font-size:.95em;">
    Default password will be set to <b>EL20_T3mp</b>. User must use “Forgot password” to change it.
  </div>
</form>

<p style="opacity:.7; margin-top:0;">
  After creating a user, set a password below and grant roles (volhrs/admin).
</p>

<h2>Existing Users</h2>

<table style="border-collapse:collapse; width:100%; max-width:1100px;">
  <thead>
    <tr>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">User</th>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Roles</th>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Password</th>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Delete</th>
    </tr>
  </thead>

  <tbody>
    {#each users as u}
      {@const rs = roleSet(u)}
      <tr>
        <td style="border-bottom:1px solid #eee; padding:6px; vertical-align:top;">
          <form method="POST" action="?/upsert" style="display:grid; gap:8px;">
            <input type="hidden" name="userId" value={u.UserId} />
            <label>Login <input name="loginName" value={u.LoginName} required /></label>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
              <label style="flex:1; min-width:180px;">First <input name="firstName" value={u.FirstName} required /></label>
              <label style="flex:1; min-width:180px;">Last <input name="lastName" value={u.LastName} required /></label>
            </div>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
              <label style="flex:1; min-width:220px;">Email <input name="email" value={u.Email ?? ""} /></label>
              <label style="flex:1; min-width:180px;">Mobile <input name="mobile" value={u.Mobile ?? ""} /></label>
            </div>
            <div>
              <button type="submit">Save</button>
              <span style="opacity:.7; margin-left:10px;">UserId {u.UserId}</span>
            </div>
          </form>
        </td>

        <td style="border-bottom:1px solid #eee; padding:6px; vertical-align:top;">
          <div style="display:flex; gap:10px; flex-wrap:wrap; margin-bottom:8px;">
            <span style="opacity:.8;">Current:</span>
            {#if (u.Roles?.length ?? 0) === 0}
              <span style="opacity:.7;">(none)</span>
            {:else}
              {#each u.Roles as r}
                <span style="border:1px solid #ddd; border-radius:999px; padding:2px 8px;">{r}</span>
              {/each}
            {/if}
          </div>

          <div style="display:flex; gap:10px; flex-wrap:wrap;">
            {#if rs.has("volhrs")}
              <form method="POST" action="?/revokeRole">
                <input type="hidden" name="userId" value={u.UserId} />
                <input type="hidden" name="roleCode" value="volhrs" />
                <button type="submit">Revoke volhrs</button>
              </form>
            {:else}
              <form method="POST" action="?/grantRole">
                <input type="hidden" name="userId" value={u.UserId} />
                <input type="hidden" name="roleCode" value="volhrs" />
                <button type="submit">Grant volhrs</button>
              </form>
            {/if}

            {#if rs.has("admin")}
              <form method="POST" action="?/revokeRole">
                <input type="hidden" name="userId" value={u.UserId} />
                <input type="hidden" name="roleCode" value="admin" />
                <button type="submit">Revoke admin</button>
              </form>
            {:else}
              <form method="POST" action="?/grantRole">
                <input type="hidden" name="userId" value={u.UserId} />
                <input type="hidden" name="roleCode" value="admin" />
                <button type="submit">Grant admin</button>
              </form>
            {/if}
          </div>
        </td>

        <td style="border-bottom:1px solid #eee; padding:6px; vertical-align:top;">
          <form method="POST" action="?/setPassword" style="display:grid; gap:8px;">
            <input type="hidden" name="userId" value={u.UserId} />
            <label>
              New password
              <input name="password" type="password" minlength="8" required />
            </label>
            <button type="submit">Set Password</button>
          </form>
          {#if u.LoginName && u.LoginName.length > 0}
            <div style="opacity:.65; font-size:.9em; margin-top:6px;">
              (This overwrites the current password.)
            </div>
          {/if}
        </td>

        <td style="border-bottom:1px solid #eee; padding:6px; vertical-align:top;">
          <form method="POST" action="?/delete">
            <input type="hidden" name="userId" value={u.UserId} />
            <button type="submit">Delete</button>
          </form>
          <div style="opacity:.65; font-size:.9em; margin-top:6px;">
            (May fail if linked records exist.)
          </div>
        </td>
      </tr>
    {/each}
  </tbody>
</table>
