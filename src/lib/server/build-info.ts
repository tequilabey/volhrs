import fs from 'fs';
import path from 'path';

export function getBuildInfo() {
  const p = path.resolve('build/build-info.json');
  if (!fs.existsSync(p)) {
    return { builtAt: null };
  }
return `[ build-info path=${p} exists=${fs.existsSync(p)} ]`;
//return JSON.parse(fs.readFileSync(p, 'utf-8'));
}
