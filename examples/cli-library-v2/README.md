# ember-library-v2

An Embroider v2 addon (library), from the default blueprint, that builds and type-checks with
TypeScript 7 and [ember-content-mapper](../../README.md). The example focuses on build inputs
and outputs: `src/` holds `.gts`, `.gjs`, and `.ts` modules, and the build emits browser-ready
JS plus type declarations.

## Build

```sh
pnpm build
```

- rollup compiles `src/` to `dist/`.
- `tsc --runExternalCode` emits declarations into `declarations/` through the content mapper.
  `outputExtensions` in `tsconfig.json` makes `counter.gts` emit `counter.d.ts`, and
  `rewriteRelativeImportExtensions` rewrites `./components/counter.gts` to
  `./components/counter.js` in the other declaration files. `declarations/` has the same
  layout as `dist/`, so the `./*` entry in `package.json#exports` types every module. See
  [Publishing a library](../../README.md#publishing-a-library).

`addon.declarations()` is not used in `rollup.config.mjs`: it runs a separate declaration
command and strips `.gts` extensions from the output (a workaround for the `ember-tsc` pipeline,
see [typed-ember/glint#628](https://github.com/typed-ember/glint/issues/628)). The build script
emits the declarations with TypeScript 7 instead.

## Type checking

```sh
pnpm lint:types
```

Runs `tsc --noEmit --runExternalCode` with the `contentMappers` entry in `tsconfig.json`.

## License

This project is licensed under the [MIT License](LICENSE.md).
