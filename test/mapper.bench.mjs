/**
 * Benchmark script using mitata. Two benchmarks, each processing the whole
 * fixture set per iteration, so cross-file effects (inline-cache
 * polymorphism, GC pressure from mixed shapes) are part of the measurement:
 *
 *   transform   the transform request (rewrite + mappings + directives)
 *   server      the same requests through src/server.js over jsonrpc,
 *               8 in flight, the way TypeScript issues them
 *
 * Each process measures exactly one source tree. By default that is the
 * current checkout; `--dir <path>` measures another tree with the same
 * fixtures and harness (bench-compare.mjs uses this for the base branch).
 * The two sides of a comparison never share a process: two copies of the
 * same code in one V8 heap get different code layout and optimization
 * treatment, which skewed p50s by up to 16% on identical code.
 *
 * Usage:
 *   node --expose-gc test/mapper.bench.mjs [--dir <path>] [--label <name>]
 *
 * Options:
 *   --dir <path>     Source tree to benchmark (default: the repo root)
 *   --label <name>   Suffix for benchmark names, e.g. "control" produces
 *                    "transform (control)" (default: no suffix)
 */

import { spawn } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { bench, do_not_optimize, run } from 'mitata';
import {
  createMessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-jsonrpc/node';

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

// ---------------------------------------------------------------------------
// Load the tree's modules and open a bench project
// ---------------------------------------------------------------------------

/** @type {{ openProject: typeof import('../src/requests/open-project.js').openProject }} */
const { openProject } = await import(
  pathToFileURL(join(TREE, 'src/requests/open-project.js')).href
);
/** @type {{ transform: typeof import('../src/requests/transform.js').transform }} */
const { transform } = await import(pathToFileURL(join(TREE, 'src/requests/transform.js')).href);

openProject({ configFileName: '', compilerOptions: {}, projectHandle: 'bench' });

// ---------------------------------------------------------------------------
// Fixture content
// ---------------------------------------------------------------------------

/**
 * @param {string} name
 *   The fixture file name.
 * @returns {{ content: string, path: string }}
 *   The fixture content and its absolute path.
 */
function fixture(name) {
  const path = fileURLToPath(new URL(`./bench/${name}`, import.meta.url));

  return { content: readFileSync(path, 'utf8'), path };
}

const TYPES = /** @type {const} */ (['gts', 'gjs']);
const SIZES = /** @type {const} */ (['small', 'medium', 'large']);

const FIXTURES = TYPES.flatMap((type) => SIZES.map((size) => fixture(`${size}.${type}`)));

// ---------------------------------------------------------------------------
// The two workloads, each covering the whole fixture set
// ---------------------------------------------------------------------------

function transformAll() {
  for (const { content, path } of FIXTURES) {
    do_not_optimize(transform({ content, fileName: path, projectHandle: 'bench' }));
  }
}

const server = spawn(process.execPath, [join(TREE, 'src/server.js')], {
  stdio: ['pipe', 'pipe', 'inherit'],
});
if (!server.stdout || !server.stdin) throw new Error('server did not expose stdio pipes');

const connection = createMessageConnection(
  new StreamMessageReader(server.stdout),
  new StreamMessageWriter(server.stdin),
);
connection.listen();

await connection.sendRequest('initialize', {
  protocolVersion: 1,
  positionEncodings: ['utf-8', 'utf-16'],
});
await connection.sendRequest('openProject', {
  configFileName: '',
  compilerOptions: {},
  projectHandle: 'bench',
});

const IN_FLIGHT = 8;

async function serverAll() {
  let next = 0;
  await Promise.all(
    Array.from({ length: IN_FLIGHT }, async () => {
      while (next < FIXTURES.length) {
        const { content, path } = FIXTURES[next++];

        do_not_optimize(
          await connection.sendRequest('transform', {
            content,
            fileName: path,
            projectHandle: 'bench',
          }),
        );
      }
    }),
  );
}

// ---------------------------------------------------------------------------
// JIT warm-up — run every workload so V8 compiles and optimises the hot
// paths before any measurement begins
// ---------------------------------------------------------------------------

const WARMUP_ROUNDS = 5;

for (let i = 0; i < WARMUP_ROUNDS; i++) {
  transformAll();
  await serverAll();
}

globalThis.gc?.();

// ---------------------------------------------------------------------------
// Register and run
// ---------------------------------------------------------------------------

bench(withLabel('transform'), transformAll);
bench(withLabel('server 8-in-flight'), serverAll);

const result = await run({ colors: false, throw: true });

connection.dispose();
server.kill();

// Write JSON output if requested
const jsonPath = process.env['BENCH_JSON_OUTPUT'];
if (jsonPath) {
  const { writeFileSync } = await import('node:fs');

  const benchmarks = result.benchmarks.map((trial) => ({
    alias: trial.alias,
    runs: trial.runs.map((r) => ({
      name: r.name,
      args: r.args,
      error: r.error
        ? { message: r.error instanceof Error ? r.error.message : String(r.error) }
        : undefined,
      stats: r.stats
        ? {
            avg: r.stats.avg,
            min: r.stats.min,
            max: r.stats.max,
            p50: r.stats.p50,
            samples: r.stats.samples,
          }
        : undefined,
    })),
  }));

  writeFileSync(jsonPath, JSON.stringify({ context: result.context, benchmarks }, null, 2));
}
