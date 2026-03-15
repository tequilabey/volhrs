<script lang="ts">
  export let data: {
    project: {
      ProjectId: number;
      Name: string;
      TotalMinutes: number | null;
      LastActivityDate: string | null;
    };
    recent: {
      EntryDate: string;
      Minutes: number;
      Notes: string | null;
    }[];
  };

  const totalHours = ((data.project.TotalMinutes ?? 0) / 60).toFixed(1);
</script>

<p><a href="/projects">← Back to Projects</a></p>

<h1>{data.project.Name}</h1>

<p>
  <strong>{totalHours}</strong> volunteer hours
  {#if data.project.LastActivityDate}
    <span style="opacity:.7;"> • last activity {data.project.LastActivityDate}</span>
  {/if}
</p>

<h2>Recent Entries</h2>

{#if data.recent.length === 0}
  <p style="opacity:.7;">No entries yet.</p>
{:else}
  <ul style="padding-left:18px;">
    {#each data.recent as r}
      <li>
        {r.EntryDate} — {(r.Minutes / 60).toFixed(2)}h
        {#if r.Notes}
          <div style="opacity:.85">{r.Notes}</div>
        {/if}
      </li>
    {/each}
  </ul>
{/if}
