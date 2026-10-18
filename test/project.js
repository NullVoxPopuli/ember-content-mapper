import assert from 'node:assert/strict';
import { test } from 'node:test';

import { closeProject } from '../src/requests/close-project.js';
import { openProject } from '../src/requests/open-project.js';
import { projects } from '../src/util/projects.js';
import { buildReferencePrefix } from '../src/util/references.js';
import pkg from '../package.json' with { type: 'json' };

test('open and close project', () => {
  const projectHandle = `${pkg.name}@${pkg.version}:project-test`;
  const result = openProject({
    compilerOptions: {},
    configFileName: 'example/tsconfig.json',
    projectHandle,
    options: {},
  });

  assert.equal(result.optionDiagnostics, undefined);
  assert.match(String(result.configIdentity), /^ember-content-mapper@/);
  assert.ok(result.watchedFiles?.some((file) => file.endsWith('ember-source/package.json')));
  assert.ok(projects.has(projectHandle));
  assert.equal(
    projects.get(projectHandle)?.referencePrefix,
    '/// <reference types="ember-source/types" />\n/// <reference types="@glint/ember-tsc/types" />\n',
  );

  closeProject({ projectHandle });
  assert.equal(projects.has(projectHandle), false);
});

test('invalid options produce option diagnostics', () => {
  const projectHandle = `${pkg.name}@${pkg.version}:invalid-options-test`;
  const result = openProject({
    compilerOptions: {},
    configFileName: 'example/tsconfig.json',
    projectHandle,
    options: {
      additionalGlobals: ['t', 42],
      additionalSpecialForms: 'nope',
      formControls: 'yes',
      typo: true,
    },
  });

  assert.deepEqual(result.optionDiagnostics, [
    {
      path: ['typo'],
      messageText:
        "Unknown option 'typo'. Supported options are 'additionalGlobals', 'additionalSpecialForms' and 'formControls'.",
    },
    {
      path: ['additionalGlobals', 1],
      messageText: "'additionalGlobals' entries must be strings.",
    },
    {
      path: ['additionalSpecialForms'],
      messageText: "'additionalSpecialForms' must be an object.",
    },
    {
      path: ['formControls'],
      messageText: "'formControls' must be a boolean.",
    },
  ]);

  closeProject({ projectHandle });
});

test('the reference prefix drops ember-source when it is not installed', () => {
  assert.equal(
    buildReferencePrefix(undefined),
    '/// <reference types="@glint/ember-tsc/types" />\n',
  );
});
