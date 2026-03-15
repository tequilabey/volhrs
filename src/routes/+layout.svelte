<script lang="ts">
  let hbOpen = false;
  export let data: {
    user: { FirstName: string; LastName: string; LoginName: string; Roles: string[] } | null;
    roles: string[];
    buildId: string;
  };
  export let children: any;

  let u: typeof data.user;
  let roles: string[] = [];
  let isAdmin = false;
  let hasVolHrs = false;
  let hasMembership = false;
  let hasRentals = false;
  let defaultSub: "vh" | "mbr" | "rental" | "admin" | null = null;

  // reactive view of current user + roles
  const norm = (v: unknown) => String(v ?? "").trim().toLowerCase();

  // user is provided by +layout.server.ts (from hooks locals)
  $: u = data.user;

  // roles are provided separately (preferred); fall back to user.Roles if present
  $: roles = (data.roles?.length ? data.roles : (u?.Roles ?? []))
    .map((r: any) => norm(r?.RoleCode ?? r?.roleCode ?? r))
    .filter(Boolean);

  // de-dup (cheap)
  $: roles = Array.from(new Set(roles));

  $: isAdmin = roles.includes("admin");

  // Admin sees everything (even if roles not explicitly granted yet)
  $: hasVolHrs = isAdmin || roles.includes("volhrs");
  $: hasMembership = isAdmin || roles.includes("membership");
  $: hasRentals = isAdmin || roles.includes("rental");

  // default selection: prefer Volunteer Hours for everyone who can see it
  $: defaultSub = (
    hasVolHrs ? "vh" :
    hasMembership ? "mbr" :
    hasRentals ? "rental" :
    isAdmin ? "admin" :
    null
  ) as "vh" | "mbr" | "rental" | "admin" | null;

  import { goto } from '$app/navigation';

  let selectedSubsystem: 'vh' | 'admin' | 'rental' | 'mbr' | null = null;

  function firstAllowedSubsystem() {
    if (hasVolHrs) return 'vh';
    if (isAdmin) return 'admin';
    if (hasRentals) return 'rental';
    if (hasMembership) return 'mbr';
    return null;
  }


  // Initialize default subsystem once user is known
  $: if (!data.user) {
    selectedSubsystem = null;
  } else {
    const first = firstAllowedSubsystem();
    if (!selectedSubsystem) selectedSubsystem = first;
    if (selectedSubsystem === 'vh' && !hasVolHrs) selectedSubsystem = first;
    if (selectedSubsystem === 'admin' && !isAdmin) selectedSubsystem = first;
    if (selectedSubsystem === 'rental' && !hasRentals) selectedSubsystem = first;
    if (selectedSubsystem === 'mbr' && !hasMembership) selectedSubsystem = first;
  }

  function onSubsystemChange() {
    goto('/');            // navigate to default welcome page
  }

</script>

<header style="margin-bottom: 18px;">
  <div style="display:flex; justify-content:space-between; align-items:flex-end; gap:16px;">
    <div>
      <div style="font-size:2.1rem; font-weight:700; line-height:1.1;">Ellensburg Lodge 20</div>
    </div>

    <div style="text-align:right; opacity:.85;">
      {#if u}
        <div style="font-size:.95rem;">Signed in as {u.FirstName} {u.LastName}</div>
        <form method="POST" action="/logout" style="margin:6px 0 0 0;">
          <button type="submit">Logout</button>
        </form>
      {:else}
        <a href="/login">Login</a>  <br/>  <a href="/signup">SignUp</a>
      {/if}
    </div>
  </div>
</header>
<!-- div style="opacity:.65; font-size:.85em; margin-bottom:10px;">
  dbg: u={u ? u.LoginName : "null"} roles={JSON.stringify(roles)} data.roles={JSON.stringify(data.roles)}
</div -->
{#if u}
  <!-- Menu state controls (CSS-driven: no JS) -->
  <input id="ms_hb" class="ms_hb" type="checkbox" hidden bind:checked={hbOpen} />
 
  {#if hasVolHrs}
    <input
      id="ms_sub_vh"
      class="ms_sub"
      type="radio"
      name="ms_sub"
      value="vh"
      hidden
      bind:group={selectedSubsystem}
      on:change={onSubsystemChange}
    />
  {/if}

  {#if hasMembership}
    <input
      id="ms_sub_mbr"
      class="ms_sub"
      type="radio"
      name="ms_sub"
      value="mbr"
      hidden
      bind:group={selectedSubsystem}
      on:change={onSubsystemChange}
    />
  {/if}

  {#if hasRentals}
    <input
      id="ms_sub_rental"
      class="ms_sub"
      type="radio"
      name="ms_sub"
      value="rental"
      hidden
      bind:group={selectedSubsystem}
      on:change={onSubsystemChange}
    />
  {/if}

  {#if isAdmin}
    <input
      id="ms_sub_admin"
      class="ms_sub"
      type="radio"
      name="ms_sub"
      value="admin"
      hidden
      bind:group={selectedSubsystem}
      on:change={onSubsystemChange}

    />
  {/if}

  <!-- Top compact menu bar -->
  <nav class="ms_bar" aria-label="Main menu">
    <!-- Hamburger -->
    <label class="ms_hb_btn" for="ms_hb" aria-label="Menu">
      <span></span><span></span><span></span>
    </label>

    <!-- Selected subsystem label (CSS shows the right one) -->
    <div class="ms_selected">
      <span class="ms_sel ms_sel_vh">Volunteer Hours</span>
      <span class="ms_sel ms_sel_mbr">Membership</span>
      <span class="ms_sel ms_sel_rental">Lodge Rentals</span>
      <span class="ms_sel ms_sel_admin">Admin</span>
      <span class="ms_arrow">→</span>
    </div>

<!-- div style="opacity:.65; font-size:.85em;">
  dbg: selected={selectedSubsystem} hasVolHrs={hasVolHrs ? 'y':'n'} isAdmin={isAdmin ? 'y':'n'} roles={JSON.stringify(roles)}
</div -->

    <!-- Subsystem items (CSS shows the right one) -->
    <div class="ms_items">
      {#if selectedSubsystem === 'vh'}
        <div class="ms_itemset ms_itemset_vh">
          <a href="/log">Log</a>
          <a href="/my">My Hours</a>
          <a href="/projects">Projects</a>
          {#if isAdmin}
            <!-- Your subsystem-specific admin item appended at end -->
            <a href="/admin/vh/projects">Edit Projects</a>
          {/if}
        </div>
      {/if}

      {#if selectedSubsystem === 'mbr'}
        <div class="ms_itemset ms_itemset_mbr">
          <a href=".">(coming soon)</a>
          {#if isAdmin}
            <a href=".">(admin)</a>
          {/if}
        </div>
      {/if}

      {#if selectedSubsystem === 'rental'}
        <div class="ms_itemset ms_itemset_rental">
          <a href=".">(coming soon)</a>
          {#if isAdmin}
            <a href=".">(admin)</a>
          {/if}
        </div>
      {/if}

      {#if selectedSubsystem === 'admin'}
        <div class="ms_itemset ms_itemset_admin">
          <a href="/admin/users">Users</a>
          <!-- Your own special menu items can go here later -->
        </div>
      {/if}
    </div>

    <!-- Dropdown list of subsystems -->
    <div class="ms_dd">
      {#if hasVolHrs}
        <button type="button" class="ms_dd_item" on:click={() => { document.getElementById("ms_sub_vh")?.click(); hbOpen = false; }} >
          Volunteer Hours </button>
      {/if}
      {#if hasMembership}
      <button type="button" class="ms_dd_item" on:click={() => { document.getElementById("ms_sub_mbr")?.click(); hbOpen = false; }} >
          Membership </button>
      {/if}
      {#if hasRentals}
      <button type="button" class="ms_dd_item" on:click={() => { document.getElementById("ms_sub_rental")?.click(); hbOpen = false; }} >
          Lodge Rentals </button>
      {/if}
      {#if isAdmin}
      <button type="button" class="ms_dd_item" on:click={() => { document.getElementById("ms_sub_admin")?.click(); hbOpen = false; }} >
          Admin </button>
      {/if}
    </div>
  </nav>
{/if}

{@render children()}

<style>
  /* top bar layout */
  .ms_bar{
    display:flex;
    align-items:center;
    gap:12px;
    border:1px solid #ddd;
    border-radius:8px;
    padding:10px 12px;
    margin-bottom:18px;
    position:relative;
  }

  /* hamburger button (three horizontal lines) */
  .ms_hb_btn{
    width:38px;
    height:32px;
    display:flex;
    flex-direction:column;
    justify-content:center;
    gap:5px;
    cursor:pointer;
    border:1px solid #ddd;
    border-radius:6px;
    padding:6px;
    user-select:none;
  }
  .ms_hb_btn span{
    display:block;
    height:2px;
    background:#222;
    border-radius:2px;
  }

  .ms_selected{
    display:flex;
    align-items:baseline;
    gap:10px;
    font-size:1.15rem;
    font-weight:700;
    white-space:nowrap;
  }
  .ms_arrow{ opacity:.75; }

  .ms_items{
    display:flex;
    flex-wrap:wrap;
    gap:14px;
    align-items:baseline;
  }
  .ms_itemset{ display:none; }

  .ms_itemset a{ white-space:nowrap; }

  .ms_itemset{
    display:none;
    gap:16px;
    flex-wrap:wrap;
    align-items:baseline;
  }

  .ms_itemset a{
    display:inline-block;
    padding:2px 6px;
  }

  /* dropdown hidden by default */
  .ms_dd{
    display:none;
    position:absolute;
    top:46px;
    left:10px;
    border:1px solid #ddd;
    border-radius:8px;
    background:#fff;
    min-width:220px;
    padding:6px;
    z-index:20;
  }
  .ms_dd_item{
    display:block;
    padding:8px 10px;
    border-radius:6px;
    cursor:pointer;
  }
  .ms_dd_item:hover{ background:#f2f2f2; }

  /* open/close dropdown via checkbox */
  #ms_hb:checked ~ .ms_bar .ms_dd{ display:block; }

  /* selected subsystem label (show one) */
  .ms_sel{ display:none; }

  /* Volunteer Hours selected */
  #ms_sub_vh:checked ~ .ms_bar .ms_sel_vh{ display:inline; }
  #ms_sub_vh:checked ~ .ms_bar .ms_itemset_vh{ display:flex; }

  /* Membership selected */
  #ms_sub_mbr:checked ~ .ms_bar .ms_sel_mbr{ display:inline; }
  #ms_sub_mbr:checked ~ .ms_bar .ms_itemset_mbr{ display:flex; }

  /* Rentals selected */
  #ms_sub_rental:checked ~ .ms_bar .ms_sel_rental{ display:inline; }
  #ms_sub_rental:checked ~ .ms_bar .ms_itemset_rental{ display:flex; }

  /* Admin selected */
  #ms_sub_admin:checked ~ .ms_bar .ms_sel_admin{ display:inline; }
  #ms_sub_admin:checked ~ .ms_bar .ms_itemset_admin{ display:flex; }

  /* If user has only one subsystem, dropdown still works but is optional.
     (No extra code needed; defaultSub pre-selects a radio.) */
</style>

<footer style="opacity:.5; font-size:.85em; margin-top:30px;">
  build: {data.buildId}
</footer>
