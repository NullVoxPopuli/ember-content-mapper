import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const testDirectory = fileURLToPath(new URL('.', import.meta.url));
const tsc7 = fileURLToPath(new URL('../node_modules/typescript-7/bin/tsc', import.meta.url));

/**
 * @param {string[]} args
 * @param {NodeJS.ProcessEnv} [env]
 * @returns {{ stdout: string, stderr: string }}
 */
function run(args, env = {}) {
  const result = spawnSync(process.execPath, [tsc7, ...args], {
    cwd: testDirectory,
    env: { ...process.env, ...env },
    encoding: 'utf8',
  });
  return { stdout: result.stdout, stderr: result.stderr };
}

test('declaration emit for a .gts component', () => {
  const project = 'diagnostics-tests/declaration';
  rmSync(`${testDirectory}${project}/dist`, { recursive: true, force: true });

  const { stdout } = run(['-p', project, '--runExternalCode']);
  assert.equal(stdout, '');

  const declaration = `${testDirectory}${project}/dist/Greeting.d.gts.ts`;
  assert.ok(existsSync(declaration), 'App.gts emits App.d.gts.ts');
  assert.equal(
    readFileSync(declaration, 'utf8'),
    readFileSync(`${testDirectory}${project}/expected/Greeting.d.gts.ts`, 'utf8'),
  );
  assert.equal(
    readFileSync(`${testDirectory}${project}/dist/index.d.ts`, 'utf8'),
    readFileSync(`${testDirectory}${project}/expected/index.d.ts`, 'utf8'),
  );
});

test('declaration emit with outputExtensions', () => {
  const project = 'diagnostics-tests/declaration-output-extensions';
  rmSync(`${testDirectory}${project}/dist`, { recursive: true, force: true });

  const { stdout } = run(['-p', project, '--runExternalCode']);
  assert.equal(stdout, '');

  assert.ok(
    !existsSync(`${testDirectory}${project}/dist/Greeting.d.gts.ts`),
    'Greeting.gts does not emit Greeting.d.gts.ts',
  );
  assert.equal(
    readFileSync(`${testDirectory}${project}/dist/Greeting.d.ts`, 'utf8'),
    readFileSync(`${testDirectory}${project}/expected/Greeting.d.ts`, 'utf8'),
  );
  assert.equal(
    readFileSync(`${testDirectory}${project}/dist/index.d.ts`, 'utf8'),
    readFileSync(`${testDirectory}${project}/expected/index.d.ts`, 'utf8'),
  );
});

test('a second --build run transforms nothing', () => {
  const project = 'diagnostics-tests/incremental';
  rmSync(`${testDirectory}${project}/dist`, { recursive: true, force: true });
  const debug = { TS_CONTENT_MAPPER_DEBUG: '1' };
  const transforms = (/** @type {string} */ log) =>
    (log.match(/"method":"transform"/g) ?? []).length;

  const first = run(['--build', project, '--runExternalCode'], debug);
  assert.equal(first.stdout, '');
  assert.equal(transforms(first.stderr), 1, 'the first build transforms the component');

  const second = run(['--build', project, '--runExternalCode'], debug);
  assert.equal(second.stdout, '');
  assert.equal(transforms(second.stderr), 0, 'the up-to-date build transforms nothing');
});
