# test-packages

Copies of Glint's `test-packages/` at `v1.10.0-@glint/ember-tsc`. The source files are identical to
upstream. Only `package.json` (published versions, the TypeScript 7 nightly, this mapper) and
`tsconfig.json` (the `contentMappers` entry, with the upstream `glint` options as mapper options)
are changed.

The `@glint-expect-error` and `@ts-expect-error` directives in these files are the assertions. A
line without a directive asserts that there is no diagnostic.

`test/typecheck.js` runs `tsc --runExternalCode` on each package and compares the output with
`expected/<package>.txt`. An empty file means that the output is the same as Glint's. Other files
record the known differences below. When a difference is fixed, the test fails until the file is
updated.

Not copied: `package-test-core`, `package-test-template`, `test-utils` (vitest harnesses),
`ts-plugin-test-app` and `ts-template-imports-app-no-config` (editor scenarios), `js-ember-app`
(one empty fixture), `v2-ts-ember-addon` (a build test), and the `__tests__` and `*-fixture`
directories of `ts-extensionless-app` (Glint's CLI harness).

## Known differences

`ts-gts-7-1-app`, `ts-special-forms-app`, and `ts-special-forms-pre-7-1-app` type-check clean.

### Extensionless imports

TypeScript resolves content-mapped files only when the specifier has the extension.
`import Greeting from './Greeting'` reports TS2307. Glint resolves it. This causes both errors in
`ts-extensionless-app` and one in `ts-template-imports-app` (`src/index.gts`).

### `.gjs` files with declaration files

Like Glint, the mapper types `with-declaration.gjs` from `with-declaration.gjs.d.ts`: a sibling
declaration file (either Glint's `x.gjs.d.ts` convention or TypeScript 7's `x.d.gjs.ts`) wins
over transforming the module. The declaration is parsed as a `.ts` module, so anything unbodied
or uninitialized in it must use ambient (`declare`) syntax. Editing only the declaration may not
invalidate TypeScript's cached transform of the sibling until the next full run.

### `ember-source` version per process

Glint's environment resolves `ember-source` from the location of `@glint/ember-tsc`. One mapper
process serves all projects and resolves the `ember-source` of the workspace root (7.x). A
project with `ember-source` 6.x gets the 7.1 transform while its types disagree. In
`ts-template-imports-app`, `{{hash}}` in `Playground.gts` reports "Property 'hash' does not exist
on type 'Keywords & Globals'". The fix is a probe root parameter in Glint's environment.

### Parse errors

`ts-gts-7-1-app/src/globals/array-keyword-preserve-literals.test.gts` has `{{! ... }}` comments
with nested mustaches, which `@glimmer/syntax` cannot parse. Glint's CLI reports nothing and does
not check the template ([typed-ember/glint#1221](https://github.com/typed-ember/glint/issues/1221)).
The mapper reports the parse error. A parse error stops TypeScript's semantic phase for the whole
project, so the file is excluded in `tsconfig.json` and the other 17 files stay checked.

## Differences recorded outside the test packages

[`test/diagnostics-tests/upstream-differences/`](../diagnostics-tests/upstream-differences) holds
one file per known difference that Glint's test packages do not cover. `ember-tsc --noEmit`
reports nothing for the project. The mapper's output is in `expected-output.txt`. When an
upstream fix lands, the test fails until the file is updated.

### Diagnostics that Glint drops

`ember-tsc` drops a diagnostic when TypeScript anchors it on generated text that no Volar
verification mapping covers. Glint's transform documents this in `template-to-typescript.ts`
(see its `wideVerification` comments). The mapper maps every synthesized region back to the
template construct that produced it, so it reports what `ember-tsc` hides. TypeScript 5.9 on the
transformed text reports the same three errors, so the checker version is not the cause. Each is
a limitation of `@glint/template`'s types:

- `record-string-never-args.gts`: `Args: Record<string, never>` has an index signature, so
  `ComponentSignatureArgs` in `@glint/template/-private/signature.d.ts` takes the
  `{ Named; Positional }` branch and both resolve to `never`. Both a direct `<Direct />` and a
  block-param `<tab.component />` invocation report it.
  Workaround: omit `Args`, or use `Args: { Named: Record<string, never>; Positional: [] }`.
- `conditional-element-generic.gts`: an `Element` type that is a conditional over an
  unresolved type parameter does not resolve, so no attribute is assignable. Workaround: widen
  the value to a concrete type.
- `curried-component-content.gts`: `{{component Comp a="hi"}}` in content position produces a
  curried `Invokable`, and `ContentValue` accepts only `ComponentReturn<{}, any>`. Ember renders
  it. Workaround: invoke the curried value, for example `{{#let (component Comp a="hi") as |C|}}<C />{{/let}}`.

### JSDoc `@extends` over an expression heritage

`jsdoc-extends-expression-heritage.gts` imports `classic-mixin.gjs`, a classic component with
`/** @extends {Component<Sig>} */` over `Component.extend(Evented)`. TypeScript 7 ignores the
tag when the heritage is a call expression, so the component has no signature and every argument
reports `TS2554: Expected 0 arguments, but got 1`. TypeScript 5.9 honors it. This reproduces in
plain JavaScript with no Glint involved, so it is a typescript-go difference.

### Consecutive directives

Two `{{! @glint-expect-error }}` comments on consecutive lines before a valid line: the mapper
reports both as unused, and `ember-tsc` reports only the first.
[`test/diagnostics-tests/directives/`](../diagnostics-tests/directives) covers this and the
other shapes whose area of effect transforms to nothing.
