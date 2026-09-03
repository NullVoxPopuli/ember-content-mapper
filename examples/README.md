# Examples

Two Ember apps and two Ember libraries that type-check with TypeScript 7 and this mapper. Open
them in your editor to debug the mapper against real code.

## Apps

- `nvp-app`: from `pnpm dlx ember.nvp --type app --layers typescript --layers qunit --layers prettier`
- `cli-app`: from `pnpm dlx ember-cli@latest new cli-app --typescript`

Changes from the generated apps:

- `typescript` is a 7.1 nightly.
- `tsconfig.json` has a `contentMappers` entry for `.gts` and `.gjs`.
- `lint:types` runs `tsc --noEmit --runExternalCode`.
- `@glint/tsserver-plugin` and the lint tooling are removed.
- `compilerOptions.types` no longer lists `ember-source/types` or `@glint/ember-tsc/types`. The
  mapper references both from the transformed text.

Each app has a class component with a signature and blocks (`counter.gts`), a template-only
component (`greeting.gts`), a `.gjs` component with a JSDoc signature (`avatar.gjs`), a modifier,
helper functions, a `.ts` file that imports `.gts` and `.gjs` modules (`components/index.ts`), the
Ember 7.1 keywords, and a rendering test in `.gts`.

## Libraries

Both libraries focus on build inputs and outputs: `src/` holds `.gts`, `.gjs`, and `.ts` modules,
and the build emits browser-ready JS plus type declarations. Each has a class component with a
signature and blocks (`counter.gts`), a template-only component (`greeting.gts`), helper
functions, and an `index.ts` that imports the `.gts` modules.

- `ember-library-v2`: from the Embroider v2 addon blueprint. Rollup compiles `src/` to `dist/`
  and `tsc --runExternalCode` emits `declarations/` through the mapper. A `.gts` module emits
  `counter.d.gts.ts`, and the `.gts`/`.gjs` specifiers in the other declaration files stay as
  written; TypeScript 7 consumers resolve them through the same mapper. `addon.declarations()`
  is not used: it strips `.gts` extensions from the emitted declarations (an `ember-tsc`-era
  workaround), which would break that resolution. Also has a `.gjs` component (`avatar.gjs`) and
  a filled-in `template-registry.ts`.
- `nvp-library`: from the `ember.nvp` library blueprint, built with tsdown and
  `@nullvoxpopuli/ember-rolldown`, which bundle `dist/index.js` and emit a bundled
  `dist/index.d.ts` via isolated declarations. The build tooling needs classic TypeScript's JS
  API, which the 7.1 nightly no longer ships, so `typescript` stays on 6.x and the nightly is
  aliased as `typescript-7`; `lint:types` runs `node ./node_modules/typescript-7/bin/tsc
  --noEmit --runExternalCode`.

## CLI

```sh
pnpm install
pnpm --filter nvp-app lint:types
pnpm --filter cli-app lint:types
pnpm --filter nvp-library lint:types
pnpm --filter ember-library-v2 lint:types
pnpm --filter nvp-library build
pnpm --filter ember-library-v2 build
```

Add a type error inside a `<template>` in `app/templates/application.gts`. The error points at
the template. `TS_CONTENT_MAPPER_DEBUG=1` logs the JSON-RPC traffic.

## VS Code

Open an example directory, for example `code examples/nvp-app`. Each example has a `.vscode/`
directory with the settings and extension recommendations below.

1. Install [TypeScript (Native Preview)](https://marketplace.visualstudio.com/items?itemName=TypeScriptTeam.native-preview)
   and [TypeScript Nightly](https://marketplace.visualstudio.com/items?itemName=TypeScriptTeam.vscode-typescript-nightly).
   Native Preview is the TypeScript 7 client. It runs the nightly build that TypeScript Nightly
   installs, unless `js/ts.tsdk.path` points somewhere else.
2. Install [Glint 2](https://marketplace.visualstudio.com/items?itemName=typed-ember.glint2-vscode)
   1.4.0 or newer. On TypeScript 7 workspaces it registers `.gts` and `.gjs` with TypeScript and
   does not start its own language server. The "Glint2 Language Server" output channel logs this.
   Uninstall Glint 1 (`typed-ember.glint-vscode`).
3. Install [Glimmer Syntax](https://marketplace.visualstudio.com/items?itemName=lifeart.vscode-glimmer-syntax)
   for highlighting. Glint 2 registers the languages and ships no grammar.
4. Trust the workspace and accept the prompt to use the workspace TypeScript. The examples set:

   ```json
   {
     "js/ts.experimental.useTsgo": true,
     "js/ts.tsdk.path": "./node_modules/typescript"
   }
   ```

`js/ts.tsdk.path` makes the editor run the same TypeScript as `lint:types`. When `typescript` stays
on 6.x for other tooling and the nightly is an alias, point it at the alias. `nvp-library` uses
`./node_modules/typescript-7`.

VS Code moved the `typescript.*` settings to `js/ts.*` and deprecated the old names.
`typescript.experimental.useTsgo` and `typescript.tsdk` still work, but VS Code flags them in
`settings.json`.

For a large project, `js/ts.server.goMemLimit` (for example `"8GiB"`) sets `GOMEMLIMIT` for the
language server.

The "TypeScript 7" output channel logs the mapper's JSON-RPC traffic at log level Trace.

## Neovim

[ember.nvim](https://github.com/NullVoxPopuli/ember.nvim) attaches nvim-lspconfig's `tsc`
(TypeScript 7's LSP) when the nearest `tsconfig.json` has `contentMappers`, and keeps `ts_ls`
and `glint` detached. Without ember.nvim:

```lua
vim.lsp.config('tsc', {
  filetypes = { 'javascript', 'typescript', 'javascript.glimmer', 'typescript.glimmer' },
  -- TypeScript starts content mappers only with this opt-in.
  init_options = { runExternalCode = true },
  get_language_id = function(_, filetype)
    if filetype == 'typescript.glimmer' then
      return 'typescript'
    end

    if filetype == 'javascript.glimmer' then
      return 'javascript'
    end

    return filetype
  end,
})
vim.lsp.enable('tsc')
```
