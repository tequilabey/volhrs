import fs from 'fs';
import path from 'path';

export function getBuildInfo() {
  const p = path.resolve(process.cwd(), 'build', 'build-info.json');

  if (!fs.existsSync(p)) {
    return {
      builtAt: null,
      debug: `[ build-info missing cwd=${process.cwd()} path=${p} ]`
    };
  }

  const raw = fs.readFileSync(p, 'utf-8');

  try {
    return {
      ...JSON.parse(raw),
      debug: `[ build-info found cwd=${process.cwd()} path=${p} raw=${raw} ]`
    };
  } catch (err) {
    return {
      builtAt: null,
      debug: `[ build-info invalid-json cwd=${process.cwd()} path=${p} raw=${raw} ]`
    };
  }
}

