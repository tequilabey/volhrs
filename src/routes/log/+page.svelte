<!--
////  src/routes/log/+page.svelte
 -->
<script lang="ts">
  export let data: {
    projects: { ProjectId: number; Name: string }[];
  };

  // action results land here
  export let form: { ok?: boolean; error?: string; values?: any } | null;

  const pad = (n: number) => String(n).padStart(2, "0");
  const d = new Date();
  const todayLocal = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

  const v = form?.values ?? {};
</script>

<h1>Log Volunteer Hours</h1>

<form method="POST" class="logForm">
  <div class="row">
    <div class="label">Project</div>
    <div class="field">
      <select name="projectId" required>
        {#each data.projects as p}
          <option value={p.ProjectId} selected={String(v.projectId ?? "") === String(p.ProjectId)}>
            {p.Name}
          </option>
        {/each}
      </select>
    </div>
  </div>

  <div class="row">
    <div class="label">Date</div>
    <div class="field">
      <input
        name="entryDate"
        type="date"
        required
        value={v.entryDate ?? todayLocal}
      />
    </div>
  </div>

  <div class="row">
    <div class="label">Hours</div>
    <div class="field">
      <input
        name="hours"
        inputmode="decimal"
        placeholder="e.g. 1.5 or 1:30"
        required
        value={v.hours ?? ""}
      />
    </div>
  </div>

  <div class="row">
    <div class="label">Notes</div>
    <div class="field">
      <textarea
        name="notes"
        rows="3"
        placeholder="Optional"
      >{v.notes ?? ""}</textarea>
    </div>
  </div>

  <div class="row">
    <div class="label"></div>
    <div class="field actions">
      <button type="submit">Save</button>
      {#if form?.error}
        <span class="err">{form.error}</span>
      {/if}
      {#if form?.ok}
        <span class="ok">Saved.</span>
      {/if}
    </div>
  </div>
</form>

<style>
  .logForm{
    max-width: 560px;
    display: grid;
    gap: 12px;
  }
  .row{
    display: grid;
    grid-template-columns: 140px 1fr;
    column-gap: 12px;
    align-items: center;
  }
  .label{
    text-align: right;
    opacity: 0.9;
    padding-right: 4px;
    white-space: nowrap;
  }
  .field :global(input),
  .field :global(select),
  .field :global(textarea){
    width: 100%;
    box-sizing: border-box;
  }
  .actions{
    display: flex;
    gap: 10px;
    align-items: center;
  }
  .err{ color: #b00020; }
  .ok{ color: #0a7a2f; }
</style>
