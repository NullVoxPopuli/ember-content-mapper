/**
 * @import { TransformParams, TransformResult } from '../protocol.js'
 */

import { availableParallelism } from 'node:os';
import { Worker } from 'node:worker_threads';

/**
 * The number of transform workers: `TS_CONTENT_MAPPER_WORKERS` when set,
 * otherwise one per core minus the main thread, at most 8. `1` disables the
 * pool and transforms on the main thread.
 *
 * @returns {number}
 */
export function poolSize() {
  const fromEnv = Number.parseInt(process.env.TS_CONTENT_MAPPER_WORKERS ?? '', 10);
  if (Number.isInteger(fromEnv) && fromEnv >= 1) {
    return fromEnv;
  }
  return Math.min(8, Math.max(1, availableParallelism() - 1));
}

/**
 * @param {number} size
 *   The number of workers.
 * @returns {{
 *   broadcast(method: string, params: unknown): Promise<void>,
 *   transform(params: TransformParams): Promise<TransformResult>,
 *   terminate(): Promise<void>,
 * }}
 *   A pool that replays project state to every worker and spreads
 *   transforms over the least busy one. `terminate` stops the workers;
 *   until then they keep the process alive.
 */
export function createPool(size) {
  let nextId = 0;
  const workers = Array.from({ length: size }, () => {
    const worker = new Worker(new URL('../worker.js', import.meta.url));
    /** @type {Map<number, { resolve: (value: any) => void, reject: (error: Error) => void }>} */
    const pending = new Map();
    worker.on('message', ({ id, result, error }) => {
      const request = pending.get(id);
      pending.delete(id);
      if (!request) return;
      if (error) reject(request, error.message);
      else request.resolve(result);
    });
    worker.on('error', (error) => {
      for (const request of pending.values()) request.reject(error);
      pending.clear();
    });
    return { worker, pending };
  });

  /**
   * @param {{ reject: (error: Error) => void }} request
   * @param {string} message
   */
  function reject(request, message) {
    request.reject(new Error(message));
  }

  /**
   * @param {(typeof workers)[number]} entry
   * @param {string} method
   * @param {unknown} params
   * @returns {Promise<any>}
   */
  function send(entry, method, params) {
    const id = nextId++;
    return new Promise((resolve, reject) => {
      entry.pending.set(id, { resolve, reject });
      entry.worker.postMessage({ id, method, params });
    });
  }

  return {
    async broadcast(method, params) {
      await Promise.all(workers.map((entry) => send(entry, method, params)));
    },
    transform(params) {
      const entry = workers.reduce((least, candidate) =>
        candidate.pending.size < least.pending.size ? candidate : least,
      );
      return send(entry, 'transform', params);
    },
    async terminate() {
      await Promise.all(workers.map((entry) => entry.worker.terminate()));
    },
  };
}
