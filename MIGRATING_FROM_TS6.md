# Migrating from TypeScript 6

On TypeScript 6, Glint 2 type-checks `.gts` and `.gjs` with its own compiler, `ember-tsc`, and
serves editors from its own language server. TypeScript 7 does both itself and calls this mapper
for the transform. Most of the migration is deleting configuration.

Coming from Glint 1 instead? See [MIGRATING_FROM_GLINT1.md](./MIGRATING_FROM_GLINT1.md).

## Two TypeScripts

Keep `typescript` on 6.x and add the 7.1 nightly under an alias:

```sh
pnpm add -D ember-content-mapper typescript-7@npm:typescript@next
```

```jsonc
// package.json
"devDependencies": {
  "typescript": "^6.0.0",
  "typescript-7": "npm:typescript@next",
}
```

TypeScript 7 does not ship the JS API that `typescript-eslint`, `tsdown`, and other build tools
load from the `typescript` package. Those tools keep resolving `typescript` and get 6.x. Only the
type-check runs on 7.

`node_modules/.bin/tsc` points at one of the two packages, and which one depends on the package
manager. Call the alias by path instead:

```jsonc
// package.json
"scripts": {
  "lint:types": "node ./node_modules/typescript-7/bin/tsc --noEmit --runExternalCode",
}
```

Without `--runExternalCode`, TypeScript reports `TS100024: Content mappers require the
'--runExternalCode' command line flag to be enabled.`

A project with no tool on the classic JS API can replace `typescript` with the nightly and use
`tsc` from `.bin`. [`examples/`](./examples) has both layouts.

## Dependencies

- Keep `@glint/ember-tsc` and `@glint/template`. The mapper transforms with `@glint/ember-tsc`
  and references its types. `@glint/template` types the signatures you write by hand.
- Remove `@glint/tsserver-plugin`. TypeScript 7 does not load tsserver plugins.

## tsconfig.json

```diff
 {
   "compilerOptions": {
-    "plugins": [{ "name": "@glint/tsserver-plugin" }],
     "types": [
       "ember-source/types",
       "@glint/ember-tsc/types",
       "@embroider/core/virtual",
       "vite/client",
     ],
   },
+  "contentMappers": [
+    {
+      "package": "ember-content-mapper",
+      "extensions": [".gts", ".gjs"],
+    },
+  ],
 }
```

Keep `"ember-source/types"` and `"@glint/ember-tsc/types"` in `compilerOptions.types`. The mapper
does not need them, but ESLint's type-aware rules build their own program on TypeScript 6 and never
see the mapper. Without the entries that program loses the `@ember/*` and Glint types.

A project with a Glint 1 `glint` key still in `tsconfig.json` moves its `environment` options to the
mapper's `options`. See [Options](./README.md#options).

## Source

Add the extension to relative imports of `.gts` and `.gjs` modules:

```diff
-export { default as Counter } from './counter';
+export { default as Counter } from './counter.gts';
```

TypeScript resolves a content-mapped file only when the specifier has the extension. Glint resolved
it either way, so this is usually the only source change.

A project that is clean under `ember-tsc` can report a few diagnostics that Glint dropped because
they landed on unmapped generated text. See
[Diagnostics that Glint drops](./test/test-packages/README.md#diagnostics-that-glint-drops).

The `{{! @glint-expect-error }}`, `{{! @glint-ignore }}`, and `{{! @glint-nocheck }}` directives
keep working. See [Directives](./README.md#directives).

## TypeScript 7 behavior changes

These surface through the mapper but are compiler behaviors, not mapper bugs. Each links to the
upstream report.

- JSDoc `@extends` over expression heritage is dropped
  ([TypeScript#64058](https://github.com/microsoft/TypeScript/issues/64058)). On TypeScript 6, a
  classic `class Foo extends Component.extend(SomeMixin) {}` with a
  `/** @extends {Component<FooSignature>} */` tag keeps its signature. TypeScript 7 rejects the tag
  (`TS8023`/`TS8026`) and the signature is lost, so every invocation types the component as taking
  no arguments, blocks, or element. Workaround: a sibling declaration file (see
  [Declaration files](./README.md#declaration-files)).
- Closure-style `function(...)` JSDoc types no longer parse, and the parse error silently drops
  every later `@property` in the same typedef. Arguments vanish from the signature with no error at
  the definition. Rewrite them as arrow types: `{function(string)=}` becomes
  `{((s: string) => void)=}`. Documented as intentional in
  [typescript-go's CHANGES.md](https://github.com/microsoft/typescript-go/blob/main/CHANGES.md).
- Declaration builds emit `foo.d.gts.ts` rather than `foo.d.ts`, which complicates
  `package.json#exports` for published packages
  ([TypeScript#64053](https://github.com/microsoft/TypeScript/issues/64053)).

Tracked in [#23](https://github.com/NullVoxPopuli/ember-content-mapper/issues/23), along with a
request for a mapper debug mode
([TypeScript#64055](https://github.com/microsoft/TypeScript/issues/64055)).

## Editor

Glint's language server is no longer in the loop. TypeScript 7's language server takes over and
needs to know about the alias: in VS Code, set `js/ts.tsdk.path` to `./node_modules/typescript-7`.
See [Editors](./README.md#editors).
