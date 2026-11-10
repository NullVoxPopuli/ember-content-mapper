import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  CompletionRequest,
  DefinitionRequest,
  DocumentDiagnosticRequest,
  HoverRequest,
  PrepareRenameRequest,
  RenameRequest,
} from 'vscode-languageserver-protocol/node';

import { positionOf, startLanguageServer } from './support/lsp-client.js';

/**
 * @param {import('vscode-languageserver-protocol').Definition | import('vscode-languageserver-protocol').LocationLink[] | null} result
 * @returns {string[]}
 */
function definitionUris(result) {
  const locations = Array.isArray(result) ? result : result ? [result] : [];
  return locations.map((location) => ('uri' in location ? location.uri : location.targetUri));
}

const tsc7 = fileURLToPath(new URL('../node_modules/typescript-7/bin/tsc', import.meta.url));
const app = fileURLToPath(new URL('../examples/nvp-app', import.meta.url));

/**
 * @param {string} relative
 * @returns {string}
 */
const file = (relative) => `${app}/${relative}`;

/** @type {Awaited<ReturnType<typeof startLanguageServer>>} */
let client;

before(async () => {
  client = await startLanguageServer(tsc7, app);
});

after(async () => {
  await client.stop();
});

test('hover on a component invoked in a template', async () => {
  const { uri, text } = client.open(file('app/templates/application.gts'));
  const result = await client.connection.sendRequest(HoverRequest.type, {
    textDocument: { uri },
    position: positionOf(text, '<Counter @initial', 1),
  });

  const contents = result?.contents;
  assert.ok(contents && !Array.isArray(contents) && typeof contents !== 'string');
  assert.match(contents.value, /class Counter/);
});

test('go to definition from a template into the component file', async () => {
  const { uri, text } = client.open(file('app/templates/application.gts'));
  const result = await client.connection.sendRequest(DefinitionRequest.type, {
    textDocument: { uri },
    position: positionOf(text, '<Counter @initial', 1),
  });

  assert.ok(definitionUris(result).some((uri) => uri.endsWith('/app/components/counter.gts')));
});

test('go to definition from a .ts import into a .gts module', async () => {
  const { uri, text } = client.open(file('app/components/index.ts'));
  const result = await client.connection.sendRequest(DefinitionRequest.type, {
    textDocument: { uri },
    position: positionOf(text, './counter.gts', 3),
  });

  assert.ok(definitionUris(result).some((uri) => uri.endsWith('/app/components/counter.gts')));
});

test('completions inside a template list the component members', async () => {
  const { uri, text } = client.open(file('app/components/counter.gts'));
  const result = await client.connection.sendRequest(CompletionRequest.type, {
    textDocument: { uri },
    position: positionOf(text, '{{yield this.count}}', '{{yield this.'.length),
  });

  assert.ok(result);
  const items = Array.isArray(result) ? result : result.items;
  const labels = items.map((item) => item.label);
  for (const member of ['count', 'step', 'increment', 'decrement']) {
    assert.ok(labels.includes(member), `expected completion for ${member}`);
  }
});

test('pull diagnostics map to the template position', async () => {
  const text = 'const probe = 1;\n<template>{{probe.nope}}</template>\n';
  const { uri } = client.open(file('app/templates/application.gts'), text);
  const result = await client.connection.sendRequest(DocumentDiagnosticRequest.type, {
    textDocument: { uri },
  });

  assert.ok(result.kind === 'full');
  assert.equal(result.items.length, 1);
  const [diagnostic] = result.items;
  assert.equal(diagnostic.code, 2339);
  assert.deepEqual(diagnostic.range, {
    start: { line: 1, character: 18 },
    end: { line: 1, character: 22 },
  });
});

test('rename from a template edits only verbatim template text', async () => {
  const { uri, text } = client.open(file('app/templates/application.gts'));
  const position = positionOf(text, '<Counter @initial', 1);

  const prepared = await client.connection.sendRequest(PrepareRenameRequest.type, {
    textDocument: { uri },
    position,
  });
  assert.ok(prepared, 'rename must be allowed on the component name');

  const edit = await client.connection.sendRequest(RenameRequest.type, {
    textDocument: { uri },
    position,
    newName: 'Tally',
  });

  // The import specifier and the opening tag. The closing tag has no
  // counterpart in the transformed output, so there is nothing to edit there.
  const templateEdits = edit?.changes?.[uri] ?? [];
  assert.equal(templateEdits.length, 2);

  // Edits reach the template only through length-preserving Verbatim
  // mappings, so every edit range must cover exactly the identifier.
  const lines = text.split('\n');
  for (const { range } of templateEdits) {
    const line = lines[range.start.line];
    assert.equal(line.slice(range.start.character, range.end.character), 'Counter');
  }
});
