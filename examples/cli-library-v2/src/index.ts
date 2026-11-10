// A plain TypeScript module importing .gts and .gjs modules: the content
// mapper resolves these imports and types the .ts side of the boundary.
//
// All relative specifiers keep their extension: rollup resolves the literal
// path, and .gts/.gjs modules additionally require it (TypeScript resolves a
// content-mapped file only when the specifier has the extension). In the
// emitted declarations, rewriteRelativeImportExtensions turns './counter.gts'
// into './counter.js', which resolves to counter.d.ts.
export { default as Avatar } from './components/avatar.gjs';
export { default as Counter } from './components/counter.gts';
export type { CounterSignature } from './components/counter.gts';
export { default as Greeting } from './components/greeting.gts';
export type { GreetingSignature } from './components/greeting.gts';
export { formatCount, shout } from './utils/format.ts';
