import {
  createMessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-jsonrpc/node';

import { closeProject } from './requests/close-project.js';
import { initialize } from './requests/initialize.js';
import { openProject } from './requests/open-project.js';
import { transform } from './requests/transform.js';
import { createPool, poolSize } from './util/pool.js';

const connection = createMessageConnection(
  new StreamMessageReader(process.stdin),
  new StreamMessageWriter(process.stdout),
);

// TypeScript parses files on several threads and sends their `transform`
// requests concurrently; a pool of workers answers them in parallel. The
// main thread keeps its own project state for option diagnostics and for
// the single-worker case.
const size = poolSize();
const pool = size > 1 ? createPool(size) : null;

connection.onRequest('initialize', initialize);
connection.onRequest('openProject', async (params) => {
  const result = openProject(params);
  await pool?.broadcast('openProject', params);
  return result;
});
connection.onRequest('transform', (params) => (pool ? pool.transform(params) : transform(params)));
connection.onRequest('closeProject', async (params) => {
  closeProject(params);
  await pool?.broadcast('closeProject', params);
});

connection.listen();
