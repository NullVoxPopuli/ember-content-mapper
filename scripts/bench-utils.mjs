/**
 * Shared utilities for benchmark formatting scripts.
 */

import { readFileSync } from 'node:fs';

export function formatTime(ns) {
  if (ns >= 1e6) return `${(ns / 1e6).toFixed(2)} ms`;
  if (ns >= 1e3) return `${(ns / 1e3).toFixed(2)} µs`;
  return `${ns.toFixed(2)} ns`;
}

/**
 * Classify a delta percentage (negative = experiment faster):
 *   ⚪ within ±2%, or within the measured round-to-round noise
 *   🟢 faster by more than 2%
 *   🟠 slower by 2–5% — worth a look, not necessarily real
 *   🔴 slower by 5% or more
 *
 * `noise` is the round-to-round spread of the same benchmark in percent.
 * A delta inside that spread is indistinguishable from measurement error.
 */
export function deltaEmoji(pct, noise) {
  const abs = Math.abs(pct);
  if (abs < 2) return '⚪';
  if (noise !== undefined && abs <= noise) return '⚪';
  if (pct <= -5) return '🟢';
  if (pct >= 5) return '🔴';
  if (pct < 0) return '🟢';
  return '🟠';
}

export const DELTA_LEGEND =
  '🟢 faster · 🔴 slower · 🟠 slightly slower · ⚪ within 2% or within round-to-round noise';

/**
 * Round-to-round spread of one side, in percent of its median:
 * (max - min) / median * 100. Returns undefined without round data.
 */
function spreadPct(stats) {
  const rounds = stats.roundP50s;
  if (!Array.isArray(rounds) || rounds.length < 2) return undefined;

  let min = Infinity;
  let max = -Infinity;
  for (const value of rounds) {
    if (value < min) min = value;
    if (value > max) max = value;
  }

  const mid = stats.p50 ?? stats.avg;

  return ((max - min) / mid) * 100;
}

/**
 * Parse benchmark JSON results into control/experiment pairs with deltas.
 * Uses p50 (median) which is more robust to outliers than avg. When the
 * results carry per-round p50s, each row also gets `noise`: the larger
 * side's round-to-round spread in percent.
 */
export function parsePairs(json) {
  const pairs = new Map();

  for (const trial of json.benchmarks || []) {
    for (const r of trial.runs || []) {
      if (!r.stats) continue;
      const m = r.name.match(/^(.+)\s+\((control|experiment)\)$/);
      if (!m) continue;
      const [, key, role] = m;
      if (!pairs.has(key)) pairs.set(key, {});
      pairs.get(key)[role] = r.stats;
    }
  }

  const rows = [];
  for (const [name, { control, experiment }] of pairs) {
    if (!control || !experiment) continue;
    const ctrlVal = control.p50 ?? control.avg;
    const expVal = experiment.p50 ?? experiment.avg;
    const delta = ((expVal - ctrlVal) / ctrlVal) * 100;

    const spreads = [spreadPct(control), spreadPct(experiment)].filter((s) => s !== undefined);
    const noise =
      spreads.length > 0 ? Math.max(spreads[0], spreads[spreads.length - 1]) : undefined;

    rows.push({ name, control: ctrlVal, experiment: expVal, delta, noise });
  }

  return rows;
}

/**
 * Read and parse the benchmark JSON results file.
 */
export function readBenchJSON(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}
