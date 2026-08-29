/**
 * Format benchmark JSON results as a CLI-friendly summary table.
 *
 * Environment variables:
 *   BENCH_JSON_OUTPUT - Path to the JSON bench results
 */

import { DELTA_LEGEND, deltaEmoji, formatTime, parsePairs, readBenchJSON } from './bench-utils.mjs';

const jsonPath = process.env.BENCH_JSON_OUTPUT;

if (!jsonPath) {
  console.error('BENCH_JSON_OUTPUT not set');
  process.exit(1);
}

let json;

try {
  json = readBenchJSON(jsonPath);
} catch (e) {
  console.error(`Could not read ${jsonPath}: ${e.message}`);
  process.exit(1);
}

const rows = parsePairs(json);

if (rows.length === 0) {
  console.log('No comparison data found.');
  process.exit(0);
}

// Calculate column widths
const nameW = Math.max('Benchmark'.length, ...rows.map((r) => r.name.length));
const ctrlW = Math.max('Control (p50)'.length, ...rows.map((r) => formatTime(r.control).length));
const expW = Math.max(
  'Experiment (p50)'.length,
  ...rows.map((r) => formatTime(r.experiment).length),
);
const deltaStr = (r) => {
  const sign = r.delta > 0 ? '+' : '';
  const noise = r.noise === undefined ? '' : ` ±${r.noise.toFixed(1)}%`;

  return `${sign}${r.delta.toFixed(1)}%${noise}`;
};

const deltaW = Math.max('Δ'.length, ...rows.map((r) => deltaStr(r).length));

// Print table
const pad = (s, w, right) => (right ? s.padStart(w) : s.padEnd(w));

console.log();
console.log(
  `   ${pad('Benchmark', nameW)}   ${pad('Control (p50)', ctrlW, true)}   ${pad('Experiment (p50)', expW, true)}   ${pad('Δ', deltaW, true)}`,
);
console.log(
  `   ${'─'.repeat(nameW)}   ${'─'.repeat(ctrlW)}   ${'─'.repeat(expW)}   ${'─'.repeat(deltaW)}`,
);

for (const row of rows) {
  const emoji = deltaEmoji(row.delta, row.noise);

  console.log(
    `${emoji} ${pad(row.name, nameW)}   ${pad(formatTime(row.control), ctrlW, true)}   ${pad(formatTime(row.experiment), expW, true)}   ${pad(deltaStr(row), deltaW, true)}`,
  );
}

console.log();
console.log(DELTA_LEGEND);
console.log();
