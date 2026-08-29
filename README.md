# ember-content-mapper

Type-check `.gts` and `.gjs` files with native TypeScript 7.

This package is a [TypeScript content mapper](https://github.com/microsoft/typescript-go/pull/4712).

## Requirements

- TypeScript 7.1 nightly or newer (`typescript@next`)
- Node 22.21.1 or newer, or Node 24.10.0 or newer 
- imports must specify the file extensions

## Install

```sh
pnpm add -D ember-content-mapper @glint/ember-tsc
```

## Use

Add the mapper to `tsconfig.json`:

```jsonc
{
  "contentMappers": [
    {
      "package": "ember-content-mapper",
      "extensions": [".gts", ".gjs"],
    },
  ],
  "include": ["src"],
}
```

Type-check:

```sh
tsc --noEmit --runExternalCode
```

### Options

`options` accepts the options of Glint's `ember-template-imports` environment:

```jsonc
{
  "contentMappers": [
    {
      "package": "ember-content-mapper",
      "extensions": [".gts", ".gjs"],
      "options": {
        "additionalGlobals": ["t"],
        "additionalSpecialForms": {},
      },
    },
  ],
}
```

### Directives

Glint's directives work as before:

- `{{! @glint-expect-error }}` suppresses the diagnostics on the next line. If there are none,
  TypeScript reports `glint2578: Unused '@glint-expect-error' directive.`
- `{{! @glint-ignore }}` suppresses the diagnostics on the next line.
- `{{! @glint-nocheck }}` suppresses the diagnostics in the whole template.

### Declaration files

A sibling declaration file wins over transforming the module, matching Glint: `counter.gjs` is
typed from `counter.d.gjs.ts` (TypeScript 7's arbitrary-extension convention) or `counter.gjs.d.ts`
(Glint's) when one exists. The declaration is parsed as a `.ts` module, so anything unbodied or
uninitialized in it must use ambient (`declare`) syntax.

## Migrating from TS6

On TypeScript 6, Glint 2 type-checks `.gts` and `.gjs` with its own compiler, `ember-tsc`, and
serves editors from its own language server. TypeScript 7 does both itself and calls this mapper
for the transform. So most of the migration is deleting configuration.

Install the TypeScript 7 nightly and the mapper:

```sh
pnpm add -D typescript@next ember-content-mapper
```

Keep `@glint/ember-tsc` and `@glint/template` installed. The mapper transforms with
`@glint/ember-tsc` and references its types, and `@glint/template` types the signatures you write
by hand.

### tsconfig.json

Add the `contentMappers` entry from [Use](#use). Then remove:

- `"ember-source/types"` and `"@glint/ember-tsc/types"` from `compilerOptions.types`. The mapper
  references both from the transformed text now. Keep every other entry, for example
  `"@embroider/core/virtual"` or `"vite/client"`. If nothing is left and the config extends
  `@tsconfig/ember` or `@ember/app-tsconfig`, drop the key: those already set `"types": []`.
- `{ "name": "@glint/tsserver-plugin" }` from `compilerOptions.plugins`. TypeScript 7 does not
  load tsserver plugins. The `contentMappers` entry replaces it.

If the project still has a Glint 1 `glint` key, its `environment` options move to the mapper's
`options`. See [Options](#options).

### package.json

- Replace `ember-tsc` in your scripts with `tsc --noEmit --runExternalCode`. Without
  `--runExternalCode`, TypeScript reports `TS100024: Content mappers require the
  '--runExternalCode' command line flag to be enabled.`
- Remove `@glint/tsserver-plugin`.

### Source

Add the extension to relative imports of `.gts` and `.gjs` modules:

```diff
-export { default as Counter } from './counter';
+export { default as Counter } from './counter.gts';
```

TypeScript resolves a content-mapped file only when the specifier has the extension. Glint
resolved it either way, so this is usually the only source change the migration needs.

Glint's `{{! @glint-expect-error }}`, `{{! @glint-ignore }}`, and `{{! @glint-nocheck }}`
directives keep working. See [Directives](#directives).

### Editor

Glint's language server is no longer in the loop. See [Editors](#editors) for what replaces it.

## Known issues

TypeScript 7 behavior changes that surface through the mapper. These are compiler behaviors, not
mapper bugs; each links to the upstream report.

- JSDoc `@extends` over expression heritage is dropped
  ([TypeScript#64058](https://github.com/microsoft/TypeScript/issues/64058)). On TypeScript 6, a
  classic `class Foo extends Component.extend(SomeMixin) {}` with a
  `/** @extends {Component<FooSignature>} */` tag keeps its signature. TypeScript 7 rejects the
  tag (`TS8023`/`TS8026`) and the signature is lost, so every invocation types the component as
  taking no arguments, blocks, or element. Workaround: a sibling declaration file (see
  [Declaration files](#declaration-files)).
- Closure-style `function(...)` JSDoc types no longer parse, and the parse error silently drops
  every later `@property` in the same typedef — arguments vanish from the signature with no error
  at the definition. Rewrite them as arrow types: `{function(string)=}` becomes
  `{((s: string) => void)=}`. Documented as intentional in
  [typescript-go's CHANGES.md](https://github.com/microsoft/typescript-go/blob/main/CHANGES.md).
- Declaration builds emit `foo.d.gts.ts` rather than `foo.d.ts`, which complicates
  `package.json#exports` for published packages
  ([TypeScript#64053](https://github.com/microsoft/TypeScript/issues/64053)).

Tracked in [#23](https://github.com/NullVoxPopuli/ember-content-mapper/issues/23), along with a
request for a mapper debug mode
([TypeScript#64055](https://github.com/microsoft/TypeScript/issues/64055)).

## Editors

- VS Code: TypeScript (Native Preview) plus Glint 2 1.4.0 or newer. Glint registers `.gts` and
  `.gjs` with TypeScript and stands down its own language server.
- Neovim: [ember.nvim](https://github.com/NullVoxPopuli/ember.nvim) attaches TypeScript 7's LSP
  when `tsconfig.json` has `contentMappers`.

[examples/README.md](./examples/README.md) has the details.

## Debug

`TS_CONTENT_MAPPER_DEBUG=1` logs the JSON-RPC traffic between `tsc` and the mapper.

## Repository

- [`examples/`](./examples): two Ember apps that use the mapper.
- [`test/test-packages/`](./test/test-packages): copies of Glint's test packages, with the known
  differences recorded in [test/test-packages/README.md](./test/test-packages/README.md).
- [`test/`](./test): snapshot tests of the transform, tests of the server process, LSP tests
  against the example app (hover, definition, completion, diagnostics, rename), and compiler
  mode tests (declaration emit, `--build` up-to-date checks, option diagnostics).

## Prior art

- [mdx-content-mapper](https://github.com/remcohaszing/mdx-content-mapper), which this package
  follows.
- [Vue's content mapper](https://github.com/vuejs/language-tools/issues/6170).

## License

[MIT](LICENSE.md)
