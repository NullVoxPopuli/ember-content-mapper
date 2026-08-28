// A transform worker. TypeScript sends `transform` requests concurrently
// (one per parser thread); `src/server.js` spreads them over a pool of
// these workers. Each worker holds its own copy of the project state, so
// `openProject` and `closeProject` are replayed to every worker.

import { parentPort } from 'node:worker_threads';

import { closeProject } from './requests/close-project.js';
import { openProject } from './requests/open-project.js';
import { transform } from './requests/transform.js';

/** @type {Record<string, (params: any) => unknown>} */
const handlers = { openProject, closeProject, transform };

if (!parentPort) {
  throw new Error('worker.js must run as a worker thread');
}
const port = parentPort;

port.on('message', ({ id, method, params }) => {
  try {
    const handler = handlers[method];
    if (!handler) {
      throw new Error(`Unknown worker method: ${method}`);
    }
    port.postMessage({ id, result: handler(params) ?? null });
  } catch (error) {
    port.postMessage({
      id,
      error: { message: error instanceof Error ? error.message : String(error) },
    });
  }
});
