<script lang="ts">
  export let data: { projects?: { ProjectId: number; Name: string; IsPublic: boolean }[] };
  export let form: { ok?: boolean; error?: string } | null;

  const projects = data.projects ?? [];
</script>

<h1>Edit Projects</h1>
<p style="opacity:.7;">Loaded projects: {projects.length}</p>
<p style="opacity:.7;">DB: {data.db}</p>

{#if form?.error}
  <p style="color:#b00020;">{form.error}</p>
{/if}
{#if form?.ok}
  <p style="color:green;">Saved.</p>
{/if}

<h2>Add Project</h2>
<form method="POST" action="?/upsert" style="display:grid; gap:10px; max-width:520px; margin-bottom:20px;">
  <label>
    Name
    <input name="name" required autofocus/>
  </label>

  <label style="display:flex; align-items:center; gap:8px;">
    <input type="checkbox" name="isPublic" checked />
    Public
  </label>

  <button type="submit">Add</button>
</form>

<h2>Existing Projects</h2>

<table style="border-collapse:collapse; width:100%; max-width:900px;">
  <thead>
    <tr>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Name</th>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Public</th>
      <th style="text-align:left; border-bottom:1px solid #ddd; padding:6px;">Actions</th>
    </tr>
  </thead>
  <tbody>
    {#each projects as p}
      <tr>
        <td style="border-bottom:1px solid #eee; padding:6px;">
          <form method="POST" action="?/upsert" style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
            <input type="hidden" name="projectId" value={p.ProjectId} />
            <input name="name" value={p.Name} required style="min-width:260px;" />
            <label style="display:flex; align-items:center; gap:8px;">
              <input type="checkbox" name="isPublic" checked={p.IsPublic} />
              Public
            </label>
            <button type="submit">Save</button>
          </form>
        </td>

        <td style="border-bottom:1px solid #eee; padding:6px;">
          {p.IsPublic ? "Yes" : "No"}
        </td>

        <td style="border-bottom:1px solid #eee; padding:6px;">
            <form method="POST" action="?/delete"
            on:submit|preventDefault={(e) => {
                if (confirm("Delete this project? (Will fail if hours exist)")) {
                    (e.currentTarget as HTMLFormElement).submit();
                }
            }}
            >
            <input type="hidden" name="projectId" value={p.ProjectId} />
            <button type="submit">Delete</button>
          </form>
        </td>
      </tr>
    {/each}
  </tbody>
</table>

