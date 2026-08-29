import {
  createMessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-jsonrpc/node';

import { availableParallelism } from 'node:os';

import { Tinypool } from 'tinypool';

import { closeProject } from './requests/close-project.js';
import { initialize } from './requests/initialize.js';
import { openProject } from './requests/open-project.js';
import { transform } from './requests/transform.js';
import { projects } from './util/projects.js';

const connection = createMessageConnection(
  new StreamMessageReader(process.stdin),
  new StreamMessageWriter(process.stdout),
);

// TypeScript decides how many `transform` requests are in flight. The
// mapper decides how they execute: a pool of worker threads, or the main
// thread when `TS_CONTENT_MAPPER_WORKERS=1` (microsoft/TypeScript#64075).
const fromEnv = Number.parseInt(process.env.TS_CONTENT_MAPPER_WORKERS ?? '', 10);
const size =
  Number.isInteger(fromEnv) && fromEnv >= 1
    ? fromEnv
    : Math.min(8, Math.max(1, availableParallelism() - 1));
const pool =
  size > 1
    ? new Tinypool({
        filename: new URL('./worker.js', import.meta.url).href,
        minThreads: size,
        maxThreads: size,
      })
    : null;

connection.onRequest('initialize', initialize);
connection.onRequest('openProject', openProject);
connection.onRequest('transform', (params) => {
  const project = projects.get(params.projectHandle);
  if (!pool || !project) {
    return transform(params);
  }
  return pool.run({ project: project.params, params });
});
connection.onRequest('closeProject', closeProject);
// The workers keep the process alive until TypeScript closes the connection.
connection.onClose(() => {
  void pool?.destroy();
});
connection.listen();
