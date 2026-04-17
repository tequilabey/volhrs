import { getBuildInfo } from '$lib/server/build-info';

export function load() {
  const build = getBuildInfo();

  return {
    builtAt: build.builtAt
  };
}