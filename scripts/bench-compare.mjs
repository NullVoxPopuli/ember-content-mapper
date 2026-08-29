/**
 * Benchmark comparison script using mitata.
 *
 * Copies the base branch's source to a temp directory, installs its
 * dependencies, then runs the bench scripts (test/mapper.bench.mjs and
 * test/tsc.bench.mjs) with one process per side per round. Separate
 * processes prevent the two sides from sharing a V8 heap, which skewed p50s
 * by up to 16% on identical code. With CPU pinning available, the two mapper
 * processes of a round run simultaneously on separate cores, so machine
 * drift hits both sides equally; the cores (or, without pinning, the run
 * order) swap every round to cancel the remaining asymmetry. The per-round
 * p50s are merged into one JSON result (median across rounds), with the
 * round-to-round spread kept as the noise estimate.
 *
 * Usage:
 *   node scripts/bench-compare.mjs [--base <branch>] [--rounds <n>]
 *
 * Options:
 *   --base <branch>   Branch to compare against (default: main)
 *   --rounds <n>      Rounds per side (default: 3, or BENCH_ROUNDS)
 */

import { execSync, spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { availableParallelism, tmpdir } from 'node:os';
import { basename, join } from 'node:path';

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

function argValue(flag) {
  const index = args.indexOf(flag);

  return index === -1 ? undefined : args[index + 1];
}

const BASE_BRANCH = argValue('--base') ?? 'main';
const ROUNDS = Number(argValue('--rounds') ?? process.env.BENCH_ROUNDS ?? 3);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function run(cmd, opts = {}) {
  return execSync(cmd, { stdio: 'inherit', ...opts });
}

/**
 * Resolve a branch name to a commit SHA. Tries `origin/<branch>` first (for CI
 * where only the PR branch is checked out locally), then falls back to `<branch>`.
 */
function resolveRef(branch) {
  for (const candidate of [`origin/${branch}`, branch]) {
    const result = spawnSync('git', ['rev-parse', '--verify', candidate], {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    if (result.status === 0) return result.stdout.trim();
  }
  throw new Error(`Could not resolve ref for branch "${branch}". Is it fetched?`);
}

function median(nums) {
  const sorted = nums.slice().sort((a, b) => a - b);
  const mid = sorted.length >> 1;

  return sorted.length % 2 === 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const ROOT = process.cwd();
const WORK_DIR = join(tmpdir(), `bench-compare-${Date.now()}`);
const CONTROL_DIR = join(WORK_DIR, 'control');
const RESULTS_DIR = join(WORK_DIR, 'results');

console.error(`\n🔧  Setting up control (${BASE_BRANCH}) in ${CONTROL_DIR}\n`);

const BASE_REF = resolveRef(BASE_BRANCH);
console.error(`   Resolved ${BASE_BRANCH} → ${BASE_REF.slice(0, 10)}\n`);

// Clean up temp dir on exit
function cleanup() {
  if (existsSync(WORK_DIR)) {
    try {
      rmSync(WORK_DIR, { recursive: true, force: true });
    } catch {
      // best-effort cleanup
    }
  }
}
process.on('exit', cleanup);
process.on('SIGINT', () => process.exit(130));
process.on('SIGTERM', () => process.exit(143));

try {
  // ── 1. Export base branch source to temp dir ─────────────────────────────
  mkdirSync(CONTROL_DIR, { recursive: true });
  mkdirSync(RESULTS_DIR, { recursive: true });

  // Copy the full tree (use the resolved SHA for reliability). The pnpm
  // workspace lists examples/* and test/test-packages/*, so a frozen-lockfile
  // install needs their manifests present.
  run(`git archive ${BASE_REF} | tar -x -C "${CONTROL_DIR}"`);

  // ── 2. Install dependencies in control dir ───────────────────────────────
  console.error(`\n📦  Installing dependencies for control (${BASE_BRANCH})…\n`);
  run('pnpm install --frozen-lockfile', {
    cwd: CONTROL_DIR,
    stdio: ['inherit', 'pipe', 'inherit'],
  });

  // ── 3. Run the bench processes per side per round ────────────────────────
  // CPU pinning on Linux to reduce cross-core migration variance
  const IS_LINUX = process.platform === 'linux';
  const HAS_TASKSET = IS_LINUX && spawnSync('which', ['taskset'], { stdio: 'pipe' }).status === 0;
  // With pinning and at least 4 logical CPUs, the two mapper processes run
  // simultaneously on separate cores: the shared time window cancels machine
  // drift, and the cores swap every round to cancel core asymmetry.
  const PARALLEL_SIDES = HAS_TASKSET && availableParallelism() >= 4;
  if (HAS_TASKSET) console.error('📌  CPU pinning enabled\n');
  if (PARALLEL_SIDES) console.error('⚡  Mapper sides run in parallel on cores 0 and 2\n');

  const SIDES = { control: CONTROL_DIR, experiment: ROOT };
  const resultFiles = [];

  const MAPPER = { script: 'test/mapper.bench.mjs', nodeArgs: ['--expose-gc'] };
  const TSC = { script: 'test/tsc.bench.mjs', nodeArgs: [] };

  /**
   * Start one bench process; resolves with its captured stdout, so parallel
   * processes never interleave their output.
   */
  function startBench(benchSpec, side, round, core) {
    const jsonPath = join(RESULTS_DIR, `round-${round}-${side}-${basename(benchSpec.script)}.json`);
    const benchArgs = benchSpec.nodeArgs.concat([
      '--max-old-space-size=4096',
      join(ROOT, benchSpec.script),
      '--dir',
      SIDES[side],
      '--label',
      side,
    ]);

    const pin = core !== undefined && HAS_TASKSET;
    const cmd = pin ? 'taskset' : 'node';
    const fullArgs = pin ? ['-c', String(core), 'node'].concat(benchArgs) : benchArgs;

    // The patched mitata (patches/mitata@1.0.34.patch) reads these sampling
    // floors from the environment. Its defaults (12 samples, 642ms of CPU
    // time per benchmark) make the p50 of the slow benchmarks unstable.
    // Values from the caller's environment win.
    const child = spawn(cmd, fullArgs, {
      cwd: ROOT,
      stdio: ['ignore', 'pipe', 'inherit'],
      env: {
        MITATA_MIN_SAMPLES: '20',
        MITATA_MIN_CPU_TIME_MS: '3000',
        ...process.env,
        BENCH_JSON_OUTPUT: jsonPath,
      },
    });

    const chunks = [];
    child.stdout.on('data', (chunk) => chunks.push(chunk));

    return new Promise((resolveOutput, reject) => {
      child.on('error', reject);
      child.on('close', (code) => {
        const output = Buffer.concat(chunks).toString();
        if (code !== 0) {
          process.stdout.write(output);
          reject(
            new Error(`Benchmark run failed (round ${round + 1}, ${side}, ${benchSpec.script}).`),
          );
          return;
        }
        resultFiles.push(jsonPath);
        resolveOutput(output);
      });
    });
  }

  function printRun(round, title, output) {
    console.log(`\n━━━ round ${round + 1}/${ROUNDS}: ${title} ━━━\n`);
    process.stdout.write(output);
  }

  for (let round = 0; round < ROUNDS; round++) {
    // Mirror per round: which core (parallel) or which slot in the run order
    // (sequential) each side gets.
    const mirrored = round % 2 === 1;

    console.error(`\n🏎️  Round ${round + 1}/${ROUNDS}: mapper…\n`);
    if (PARALLEL_SIDES) {
      const cores = mirrored ? { control: 2, experiment: 0 } : { control: 0, experiment: 2 };
      const [controlOut, experimentOut] = await Promise.all([
        startBench(MAPPER, 'control', round, cores.control),
        startBench(MAPPER, 'experiment', round, cores.experiment),
      ]);
      printRun(round, `mapper control (core ${cores.control})`, controlOut);
      printRun(round, `mapper experiment (core ${cores.experiment})`, experimentOut);
    } else {
      const order = mirrored ? ['experiment', 'control'] : ['control', 'experiment'];
      for (const side of order) {
        printRun(
          round,
          `mapper ${side}`,
          await startBench(MAPPER, side, round, HAS_TASKSET ? 0 : undefined),
        );
      }
    }

    // tsc: typescript-7 is multithreaded, so pinning or overlapping it would
    // measure a configuration nobody runs; the sides run sequentially in
    // mirrored order.
    const order = mirrored ? ['experiment', 'control'] : ['control', 'experiment'];
    for (const side of order) {
      console.error(`\n🏎️  Round ${round + 1}/${ROUNDS}: tsc ${side}…\n`);
      printRun(round, `tsc ${side}`, await startBench(TSC, side, round, undefined));
    }
  }

  // ── 4. Merge the per-round results (median of p50s across rounds) ────────
  const byName = new Map();
  let context;

  for (const file of resultFiles) {
    const json = JSON.parse(readFileSync(file, 'utf8'));
    context ??= json.context;

    for (const trial of json.benchmarks || []) {
      for (const r of trial.runs || []) {
        if (!r.stats) continue;
        if (!byName.has(r.name)) byName.set(r.name, []);
        byName.get(r.name).push(r.stats);
      }
    }
  }

  const benchmarks = [];
  for (const [name, statsList] of byName) {
    const p50s = statsList.map((s) => s.p50 ?? s.avg);

    benchmarks.push({
      alias: name,
      runs: [
        {
          name,
          stats: {
            avg: median(statsList.map((s) => s.avg)),
            p50: median(p50s),
            min: median(statsList.map((s) => s.min)),
            max: median(statsList.map((s) => s.max)),
            roundP50s: p50s,
          },
        },
      ],
    });
  }

  const jsonOut = process.env.BENCH_JSON_OUTPUT;
  if (jsonOut) {
    writeFileSync(jsonOut, JSON.stringify({ context, rounds: ROUNDS, benchmarks }, null, 2));
  }

  console.error('\n✅  Benchmark comparison complete.\n');
} catch (e) {
  console.error('❌  Error:', e.message);
  process.exit(1);
}
