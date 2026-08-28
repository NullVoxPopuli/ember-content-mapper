// A transform worker. TypeScript sends `transform` requests concurrently
// (one per parser thread); `src/server.js` spreads them over a pool of
// these workers. Each worker holds its own copy of the project state, so
// `openProject` and `closeProject` are replayed to every worker.

import { parentPort } from 'node:worker_threads';

import { closeProject } from './requests/close-project.js';
import { openProject } from './requests/open-project.js';
import { transform } from './requests/transform.js';

const handlers = { openProject, closeProject, transform };

parentPort.on('message', ({ id, method, params }) => {
  try {
    parentPort.postMessage({ id, result: handlers[method](params) ?? null });
  } catch (error) {
    parentPort.postMessage({
      id,
      error: { message: error instanceof Error ? error.message : String(error) },
    });
  }
});
