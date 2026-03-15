<!--
////  src/routes/projects/+page.svelte
 -->
<script lang="ts">
  export let data: {
    projects: {
      ProjectId: number;
      Name: string;
      TotalMinutes: number | null;
      LastActivityDate: string | null;
    }[];
    recent: {
      EntryDate: string;
      Minutes: number;
      ProjectName: string;
    }[];
  };

  const hours = (m: number | null) =>
    ((m ?? 0) / 60).toFixed(1);
</script>

<h1>Our Projects</h1>

<section style="display:grid; gap:12px; max-width:700px;">
  {#each data.projects as p}
    <div style="border:1px solid #ddd; padding:12px; border-radius:6px;">
       <h3 style="margin:0 0 4px 0;">
         <a href={"/projects/" + p.ProjectId}>{p.Name}</a>
       </h3>
      <div>
        <strong>{hours(p.TotalMinutes)}</strong> volunteer hours
      </div>
      {#if p.LastActivityDate}
        <div style="opacity:.7; font-size:.9em;">
          Last activity: {p.LastActivityDate}
        </div>
      {/if}
    </div>
  {/each}
</section>

<h2 style="margin-top:32px;">Recent Activity</h2>

<ul style="padding-left:18px;">
  {#each data.recent as r}
    <li>
      {r.EntryDate} — {r.ProjectName} — {(r.Minutes / 60).toFixed(2)}h
    </li>
  {/each}
</ul>
