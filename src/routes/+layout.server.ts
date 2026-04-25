import { getBuildInfo } from '$lib/server/build-info';

export async function load({ locals }) {
  const buildInfo = getBuildInfo();

  return {
    user: locals.user ?? null,
    roles: locals.roles ?? [],
    buildId: buildInfo.builtAt ?? "no build info"
  };
}
