export async function load({ locals }) {
  return {
    user: locals.user ?? null,
    roles: locals.roles ?? [],
    buildId: new Date().toISOString()
  };
}