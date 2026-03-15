import { error } from "@sveltejs/kit";
import { projectsGetPublicDetail } from "$lib/server/vhRepo";

export async function load({ params }) {
  const projectId = Number(params.id);
  if (!Number.isFinite(projectId) || projectId <= 0) throw error(404);

  const { project, recent } = await projectsGetPublicDetail(projectId);
  if (!project || !project.IsPublic) throw error(404);

  return { project, recent };
}
