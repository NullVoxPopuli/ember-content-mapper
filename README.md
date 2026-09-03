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

## Migrating

- [From TypeScript 6 and Glint 2 (`ember-tsc`)](./MIGRATING_FROM_TS6.md)
- [From Glint 1](./MIGRATING_FROM_GLINT1.md)

## Editors

- VS Code: TypeScript (Native Preview), TypeScript Nightly, and Glint 2 1.4.2 or newer, with
  `"js/ts.experimental.useTsgo": true`.
- Neovim: [ember.nvim](https://github.com/NullVoxPopuli/ember.nvim) attaches TypeScript 7's LSP
  when `tsconfig.json` has `contentMappers`.

[examples/README.md](./examples/README.md) has the details.

## Debug

`TS_CONTENT_MAPPER_DEBUG=1` logs the JSON-RPC traffic between `tsc` and the mapper.

`TS_CONTENT_MAPPER_WORKERS=<n>` sets the number of transform workers (default: cores − 1, at most 8;
`1` = main thread). `tsc --extendedDiagnostics` shows the wait as `Content mapper request wait time`.

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
