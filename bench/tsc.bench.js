// `pnpm bench:tsc` — `tsc --extendedDiagnostics` over a generated
// template-dense project, main thread vs the worker pool. Reports the two
// lines that show where the parse phase waits: "Content mapper request
// wait time" and "Total time".
//
//   FILES=300 ELEMENTS=100 RUNS=3 pnpm bench:tsc

import { spawnSync } from 'node:child_process';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

import { template } from './template.js';

const files = Number(process.env.FILES ?? 300);
const elements = Number(process.env.ELEMENTS ?? 100);
const runs = Number(process.env.RUNS ?? 3);

const root = fileURLToPath(new URL('./.project/', import.meta.url));
rmSync(root, { recursive: true, force: true });
mkdirSync(`${root}src`, { recursive: true });
for (let i = 0; i < files; i++) {
  writeFileSync(`${root}src/component-${i}.gts`, template(elements, `Component${i}`));
}
writeFileSync(
  `${root}tsconfig.json`,
  JSON.stringify(
    {
      extends: '@tsconfig/ember/tsconfig.json',
      compilerOptions: { noEmit: true, skipLibCheck: true },
      contentMappers: [{ package: 'ember-content-mapper', extensions: ['.gts', '.gjs'] }],
      include: ['src'],
    },
    null,
    2,
  ),
);

const tsc = fileURLToPath(new URL('../node_modules/typescript-7/bin/tsc', import.meta.url));

/**
 * @param {Record<string, string>} env
 * @returns {{ wait: number, total: number, errors: number }}
 */
function measure(env) {
  const result = spawnSync(
    process.execPath,
    [tsc, '-p', root, '--noEmit', '--runExternalCode', '--extendedDiagnostics'],
    { encoding: 'utf8', env: { ...process.env, ...env }, maxBuffer: 1024 * 1024 * 1024 },
  );
  const out = result.stdout + result.stderr;
  const seconds = (/** @type {string} */ label) =>
    Number(out.match(new RegExp(`^${label}:\\s+([\\d.]+)s`, 'm'))?.[1] ?? Number.NaN);
  return {
    wait: seconds('Content mapper request wait time'),
    total: seconds('Total time'),
    errors: (out.match(/error TS/g) ?? []).length,
  };
}

/** @param {Record<string, string>} env */
function best(env) {
  let bestRun = measure(env);
  for (let i = 1; i < runs; i++) {
    const run = measure(env);
    if (run.total < bestRun.total) bestRun = run;
  }
  return bestRun;
}

console.log(`${files} .gts files × ${elements} elements, best of ${runs}\n`);
console.log('                              mapper wait   total   errors');
for (const [label, env] of [
  ['main thread (WORKERS=1)   ', { TS_CONTENT_MAPPER_WORKERS: '1' }],
  ['worker pool (default)     ', { TS_CONTENT_MAPPER_WORKERS: '' }],
]) {
  const { wait, total, errors } = best(env);
  console.log(
    `${label}   ${wait.toFixed(2).padStart(6)} s  ${total.toFixed(2).padStart(6)} s  ${errors}`,
  );
}
