// `pnpm bench` — transform cost per template size, the mapper's overhead
// over Glint's rewrite, and the worker pool against the main thread for a
// batch of concurrent requests (TypeScript keeps several in flight).

import { bench, group, run, summary } from 'mitata';

import { rewriteModuleStandalone } from '@glint/ember-tsc/transform/standalone';

import { openProject } from '../src/requests/open-project.js';
import { transform } from '../src/requests/transform.js';
import { createPool } from '../src/util/pool.js';
import { projects } from '../src/util/projects.js';

/**
 * A component with `elements` nested divs, each carrying attribute
 * mustaches and a helper call — the shapes that drive Glint's mapping work.
 *
 * @param {number} elements
 * @returns {string}
 */
function template(elements) {
  const rows = Array.from(
    { length: elements },
    (_, i) =>
      `    <div class={{if this.on${i} "a" "b"}} title={{concat "row " ${i}}}>{{this.label${i}}} <span>{{yield}}</span></div>`,
  ).join('\n');
  return `import Component from '@glimmer/component';
import { concat } from '@ember/helper';

export default class Bench extends Component {
${Array.from({ length: elements }, (_, i) => `  on${i} = true;\n  label${i} = 'x';`).join('\n')}
  <template>
${rows}
  </template>
}
`;
}

const sizes = { small: 10, medium: 100, large: 1000 };
const fixtures = Object.fromEntries(
  Object.entries(sizes).map(([name, elements]) => [name, template(elements)]),
);

const projectHandle = 'bench';
openProject({
  projectHandle,
  options: {},
  configFilePath: `${process.cwd()}/tsconfig.json`,
  rootDir: process.cwd(),
});
const { environment } = projects.get(projectHandle);

group('Glint rewrite (rewriteModuleStandalone)', () => {
  for (const [name, contents] of Object.entries(fixtures)) {
    bench(`${name} (${sizes[name]} elements, ${(contents.length / 1024).toFixed(0)} KB)`, () => {
      rewriteModuleStandalone(
        { script: { filename: `/bench/${name}.gts`, contents } },
        environment,
      );
    });
  }
});

group('mapper transform request (rewrite + mappings + directives)', () => {
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
  const pool = createPool(size);
  await pool.broadcast('openProject', {
    projectHandle,
    options: {},
    configFilePath: `${process.cwd()}/tsconfig.json`,
    rootDir: process.cwd(),
  });
  pools.set(size, pool);
}

summary(() => {
  group(`${count} medium transforms, ${inFlight} in flight`, () => {
    bench('main thread (TS_CONTENT_MAPPER_WORKERS=1)', async () => {
      await drain((params) => transform(params));
    });
    for (const [size, pool] of pools) {
      bench(`pool of ${size} workers`, async () => {
        await drain((params) => pool.transform(params));
      });
    }
  });
});

await run();
await Promise.all([...pools.values()].map((pool) => pool.terminate()));
