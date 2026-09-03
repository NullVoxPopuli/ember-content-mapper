# Migrating from Glint 1

Glint 1 type-checks `.gts`, `.gjs`, and `.hbs` with its own compiler, `glint`, configured by a
`glint` key in `tsconfig.json` and a set of environment packages. TypeScript 7 type-checks `.gts`
and `.gjs` itself and calls this mapper for the transform.

Coming from Glint 2 (`ember-tsc`) instead? See [MIGRATING_FROM_TS6.md](./MIGRATING_FROM_TS6.md).

## Loose mode

The mapper handles `.gts` and `.gjs` only. Loose-mode templates (`.hbs` next to a backing class,
resolved through the template registry) are not type-checked. Convert them first with
[`@embroider/template-tag-codemod`](https://github.com/embroider-build/embroider/tree/main/packages/template-tag-codemod).

A library can keep publishing a `template-registry.ts` for consumers still in loose mode. The
check does not use it.

## Two TypeScripts

Keep `typescript` on 6.x and add the 7.1 nightly under an alias. Tools such as `typescript-eslint`
load TypeScript's JS API, which the nightly does not ship.

```sh
pnpm add -D ember-content-mapper @glint/ember-tsc typescript-7@npm:typescript@next
```

```jsonc
// package.json
"devDependencies": {
  "typescript": "^6.0.0",
  "typescript-7": "npm:typescript@next",
}
```

See [Two TypeScripts](./MIGRATING_FROM_TS6.md#two-typescripts) for why the alias is called by
path rather than through `node_modules/.bin/tsc`.

## Dependencies

- Remove `@glint/core`, `@glint/environment-ember-loose`, and
  `@glint/environment-ember-template-imports`.
- Add `@glint/ember-tsc`. The mapper transforms with it and references its types.
- Keep `@glint/template`. It still types the signatures you write by hand (`ComponentLike`,
  `WithBoundArgs`, and so on).

## tsconfig.json

The `glint` key goes away. Its `environment` options move to the mapper's `options`:

```diff
 {
   "compilerOptions": {
     "types": [
+      "ember-source/types",
+      "@glint/ember-tsc/types",
       "@embroider/core/virtual",
       "vite/client",
     ],
   },
-  "glint": {
-    "environment": {
-      "ember-template-imports": {
-        "additionalGlobals": ["t"],
-      },
-    },
-  },
+  "contentMappers": [
+    {
+      "package": "ember-content-mapper",
+      "extensions": [".gts", ".gjs"],
+      "options": {
+        "additionalGlobals": ["t"],
+      },
+    },
+  ],
 }
```

The mapper does not need the two `types` entries, but ESLint's type-aware rules build their own
program on TypeScript 6 and never see the mapper. Without the entries that program loses the
`@ember/*` and Glint types.

## types/global.d.ts

Remove the environment imports Glint 1 needed:

```diff
-import '@glint/environment-ember-loose';
-import '@glint/environment-ember-template-imports';
```

If `ember-source/types` was imported here rather than listed in `compilerOptions.types`, either
form works.

## package.json

Replace `glint` in your scripts:

```diff
-"lint:types": "glint",
+"lint:types": "node ./node_modules/typescript-7/bin/tsc --noEmit --runExternalCode",
```

`glint --declaration` becomes `node ./node_modules/typescript-7/bin/tsc --declaration
--runExternalCode`. A `.gts` module emits `counter.d.gts.ts`; see
[TypeScript 7 behavior changes](./MIGRATING_FROM_TS6.md#typescript-7-behavior-changes).

## Source

Add the extension to relative imports of `.gts` and `.gjs` modules:

```diff
-export { default as Counter } from './counter';
+export { default as Counter } from './counter.gts';
```

TypeScript resolves a content-mapped file only when the specifier has the extension.

The mapper transforms with Glint 2's `@glint/ember-tsc`, so Glint 2's checks apply. A project
that is clean under Glint 1 can report new diagnostics, both from Glint 2 and from text Glint 1
dropped as unmapped. See
[Diagnostics that Glint drops](./test/test-packages/README.md#diagnostics-that-glint-drops).

The `{{! @glint-expect-error }}`, `{{! @glint-ignore }}`, and `{{! @glint-nocheck }}` directives
keep working. See [Directives](./README.md#directives).

## Editor

Uninstall the Glint 1 extension (`typed-ember.glint-vscode`). TypeScript 7's language server takes
over and needs to know about the alias: in VS Code, set `js/ts.tsdk.path` to
`./node_modules/typescript-7`. See [Editors](./README.md#editors).
