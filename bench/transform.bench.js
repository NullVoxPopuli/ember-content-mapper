// `pnpm bench` — transform cost per template size, and the worker pool
// against the main thread for a batch of concurrent requests.

import { bench, group, run, summary } from 'mitata';

import { openProject } from '../src/requests/open-project.js';
import { transform } from '../src/requests/transform.js';
import { Tinypool } from 'tinypool';

import { template } from './template.js';

const sizes = { small: 10, medium: 100, large: 1000 };
const fixtures = Object.fromEntries(
  Object.entries(sizes).map(([name, elements]) => [name, template(elements)]),
);

const projectHandle = 'bench';
const project = {
  projectHandle,
  options: {},
  configFilePath: `${process.cwd()}/tsconfig.json`,
  rootDir: process.cwd(),
};
openProject(project);

group('transform request', () => {
  for (const [name, content] of Object.entries(fixtures)) {
    bench(name, () => {
      transform({ projectHandle, fileName: `/bench/${name}.gts`, content });
    });
  }
});

// A batch of `count` requests with `inFlight` outstanding at a time, the way
// TypeScript's parser threads issue them.
const count = 48;
const inFlight = 8;
const batch = Array.from({ length: count }, (_, i) => ({
  projectHandle,
  fileName: `/bench/batch-${i}.gts`,
  content: fixtures.medium,
}));

/** @param {(params: any) => Promise<unknown> | unknown} handle */
async function drain(handle) {
  let next = 0;
  await Promise.all(
    Array.from({ length: inFlight }, async () => {
      while (next < batch.length) {
        await handle(batch[next++]);
      }
    }),
  );
}

const pools = new Map();
for (const size of [2, 4, 8]) {
  pools.set(
    size,
    new Tinypool({
      filename: new URL('../src/worker.js', import.meta.url).href,
      minThreads: size,
      maxThreads: size,
    }),
  );
}

summary(() => {
  group(`${count} medium transforms, ${inFlight} in flight`, () => {
    bench('main thread (TS_CONTENT_MAPPER_WORKERS=1)', async () => {
      await drain((params) => transform(params));
    });
    for (const [size, pool] of pools) {
      bench(`pool of ${size} workers`, async () => {
        await drain((params) => pool.run({ project, params }));
      });
    }
  });
});

// MITATA_FORMAT=json for machine-readable output.
await run({ format: process.env.MITATA_FORMAT ?? 'mitata' });
await Promise.all([...pools.values()].map((pool) => pool.destroy()));
