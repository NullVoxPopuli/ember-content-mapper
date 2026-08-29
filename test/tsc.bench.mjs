/**
 * End-to-end tsc benchmark. Generates a project from the bench fixtures
 * inside the measured tree (so that tree's own mapper and typescript-7
 * resolve), runs `tsc --noEmit --runExternalCode --extendedDiagnostics`
 * several times, and reports the median total time and content-mapper wait
 * time. No mitata: one tsc run costs seconds, so the runner does its own
 * small sampling and emits the same JSON shape as the mitata benches.
 *
 * The fixtures import packages this repository does not depend on (for
 * example ember-truth-helpers), so tsc reports unresolved-import errors.
 * They are identical on both sides of a comparison and do not affect the
 * mapper work being measured.
 *
 * Usage:
 *   node test/tsc.bench.mjs [--dir <path>] [--label <name>]
 *
 * Options:
 *   --dir <path>     Source tree to benchmark (default: the repo root)
 *   --label <name>   Suffix for benchmark names (default: no suffix)
 *
 * Environment:
 *   BENCH_TSC_RUNS     Measured runs after one warm-up run (default: 3)
 *   BENCH_TSC_COPIES   Copies of each fixture in the project (default: 6)
 *   BENCH_JSON_OUTPUT  Path for the JSON results
 */

import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

/**
 * @param {string} flag
 *   The flag to look up.
 * @returns {string | undefined}
 *   The value after the flag.
 */
function argValue(flag) {
  const index = args.indexOf(flag);

  return index === -1 ? undefined : args[index + 1];
}

const dirArg = argValue('--dir');
const TREE = dirArg ? resolve(dirArg) : fileURLToPath(new URL('..', import.meta.url));
const LABEL = argValue('--label');

/**
 * @param {string} name
 *   The plain benchmark name.
 * @returns {string}
 *   The name with the side label appended.
 */
function withLabel(name) {
  return LABEL ? `${name} (${LABEL})` : name;
}

const RUNS = Number(process.env['BENCH_TSC_RUNS'] ?? 3);
const COPIES = Number(process.env['BENCH_TSC_COPIES'] ?? 6);

// ---------------------------------------------------------------------------
// Generate the project inside the measured tree, under node_modules so it is
// never picked up by git or the repo's own tsconfig
// ---------------------------------------------------------------------------

const fixturesDir = fileURLToPath(new URL('./bench/', import.meta.url));
const fixtureNames = [
  'small.gts',
  'medium.gts',
  'large.gts',
  'small.gjs',
  'medium.gjs',
  'large.gjs',
];

const projectDir = join(TREE, 'node_modules', '.bench-tsc');
rmSync(projectDir, { recursive: true, force: true });
mkdirSync(join(projectDir, 'src'), { recursive: true });

let fileCount = 0;
for (const name of fixtureNames) {
  const content = readFileSync(join(fixturesDir, name), 'utf8');
  const extension = name.slice(name.indexOf('.'));
  const base = basename(name, extension);

  for (let copy = 0; copy < COPIES; copy++) {
    writeFileSync(join(projectDir, 'src', `${base}-${copy}${extension}`), content);
    fileCount++;
  }
}

writeFileSync(
  join(projectDir, 'tsconfig.json'),
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

// ---------------------------------------------------------------------------
// Run tsc and parse --extendedDiagnostics
// ---------------------------------------------------------------------------

const tscBin = join(TREE, 'node_modules', 'typescript-7', 'bin', 'tsc');

/**
 * @returns {{ wait: number, total: number }}
 *   Content-mapper wait time and total time, in seconds.
 */
function runOnce() {
  const result = spawnSync(
    process.execPath,
    [tscBin, '-p', projectDir, '--noEmit', '--runExternalCode', '--extendedDiagnostics'],
    { encoding: 'utf8', maxBuffer: 1024 * 1024 * 1024 },
  );

  const out = `${result.stdout}${result.stderr}`;
  const seconds = (/** @type {string} */ label) =>
    Number(out.match(new RegExp(`^${label}:\\s+([\\d.]+)s`, 'm'))?.[1] ?? Number.NaN);

  const total = seconds('Total time');
  if (Number.isNaN(total)) {
    console.error(out.slice(-2000));
    throw new Error('tsc produced no --extendedDiagnostics output');
  }

  return { wait: seconds('Content mapper request wait time'), total };
}

/**
 * @param {number[]} nums
 *   The values.
 * @returns {number}
 *   The median.
 */
function median(nums) {
  const sorted = nums.slice().sort((a, b) => a - b);
  const mid = sorted.length >> 1;

  return sorted.length % 2 === 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

console.log(
  `tsc: ${fileCount} files (${fixtureNames.length} fixtures × ${COPIES}), ${RUNS} runs after warm-up`,
);

runOnce(); // warm-up: file system caches, first mapper spawn

/** @type {{ wait: number, total: number }[]} */
const samples = [];
for (let i = 0; i < RUNS; i++) {
  const sample = runOnce();
  samples.push(sample);
  console.log(
    `  run ${i + 1}: total ${sample.total.toFixed(2)}s, mapper wait ${sample.wait.toFixed(2)}s`,
  );
}

rmSync(projectDir, { recursive: true, force: true });

// ---------------------------------------------------------------------------
// Report, in the same JSON shape as the mitata benches (times in ns)
// ---------------------------------------------------------------------------

/**
 * @param {string} name
 *   The benchmark name.
 * @param {number[]} seconds
 *   The per-run values in seconds.
 * @returns {{ name: string, stats: { avg: number, min: number, max: number, p50: number } }}
 *   A run entry.
 */
function toRun(name, seconds) {
  const ns = seconds.map((s) => s * 1e9);
  const sum = ns.reduce((acc, value) => acc + value, 0);

  let min = Infinity;
  let max = -Infinity;
  for (const value of ns) {
    if (value < min) min = value;
    if (value > max) max = value;
  }

  return { name: withLabel(name), stats: { avg: sum / ns.length, min, max, p50: median(ns) } };
}

const totalRun = toRun(
  'tsc total',
  samples.map((s) => s.total),
);
const waitRun = toRun(
  'tsc mapper wait',
  samples.map((s) => s.wait),
);

console.log(
  `  p50: total ${(totalRun.stats.p50 / 1e9).toFixed(2)}s, mapper wait ${(waitRun.stats.p50 / 1e9).toFixed(2)}s`,
);

const jsonPath = process.env['BENCH_JSON_OUTPUT'];
if (jsonPath) {
  writeFileSync(
    jsonPath,
    JSON.stringify({ benchmarks: [{ alias: 'tsc', runs: [totalRun, waitRun] }] }, null, 2),
  );
}
