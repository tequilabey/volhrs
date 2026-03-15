<script lang="ts">
  export let form:
    | { ok?: boolean; error?: string; values?: { loginName: string; firstName: string; lastName: string; email: string; mobile: string } }
    | null;

  const v = form?.values ?? { loginName: "", firstName: "", lastName: "", email: "", mobile: "" };
</script>

<h1>Sign Up</h1>

<form method="POST" style="max-width: 520px; display: grid; gap: 12px;">
  <label>
    Login name
    <input name="loginName" required autocomplete="username" value={v.loginName} autofocus/>
  </label>

  <label>
    Password
    <input name="password" type="password" required autocomplete="new-password" />
    <div style="opacity:.7; font-size:.9em;">Minimum 8 characters.</div>
  </label>

  <label>
    First name
    <input name="firstName" required autocomplete="given-name" value={v.firstName} />
  </label>

  <label>
    Last name
    <input name="lastName" required autocomplete="family-name" value={v.lastName} />
  </label>

  <label>
    Email
    <input name="email" type="email" autocomplete="email" value={v.email} />
  </label>

  <label>
    Mobile phone
    <input name="mobile" type="tel" autocomplete="tel" value={v.mobile} />
  </label>

  <button type="submit">Create account</button>

  {#if form?.ok}
    <p style="color: green;">Account created. You can now log in.</p>
  {/if}
  {#if form?.error}
    <p style="color: #b00020;">{form.error}</p>
  {/if}
</form>

