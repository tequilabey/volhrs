<!--
////  src/routes/my/+page.svelte
 -->
<script lang="ts">
  export let data: {
    entries: { EntryDate: string; Minutes: number; Notes: string | null; ProjectName: string }[];
    totalMinutes: number;
  };

  const totalHours = (data.totalMinutes / 60).toFixed(2);
</script>

<h1>My Hours</h1>
<p><strong>Total:</strong> {totalHours} hours</p>

<ul style="display:grid; gap:10px; padding-left: 18px;">
  {#each data.entries as e}
    <li>
      <strong>{e.EntryDate}</strong> — {e.ProjectName} — {(e.Minutes / 60).toFixed(2)}h
      {#if e.Notes}
        <div style="opacity:.85">{e.Notes}</div>
      {/if}
    </li>
  {/each}
</ul>
