/**
 * @import { OpenProjectParams, OpenProjectResult, OptionDiagnostic } from '../protocol.js'
 */

import { createRequire } from 'node:module';

import { GlintEnvironment } from '@glint/ember-tsc/config/index';

import { probeEmberSource } from '../util/ember-probe.js';
import { projects } from '../util/projects.js';
import { buildReferencePrefix } from '../util/references.js';

const require = createRequire(import.meta.url);

/** @type {{ name: string, version: string }} */
const ownManifest = require('ember-content-mapper/package.json');

/** @type {{ version: string }} */
const emberTscManifest = require('@glint/ember-tsc/package.json');

/**
 * Validate the `contentMappers` entry's `options` object.
 *
 * @param {Record<string, unknown>} options
 *   The options to validate.
 * @returns {OptionDiagnostic[]}
 *   Diagnostics for invalid option values.
 */
function validateOptions(options) {
  /** @type {OptionDiagnostic[]} */
  const diagnostics = [];

  for (const key of Object.keys(options)) {
    if (key !== 'additionalGlobals' && key !== 'additionalSpecialForms' && key !== 'formControls') {
      diagnostics.push({
        path: [key],
        messageText: `Unknown option '${key}'. Supported options are 'additionalGlobals', 'additionalSpecialForms' and 'formControls'.`,
      });
    }
  }

  const additionalGlobals = options['additionalGlobals'];
  if (additionalGlobals !== undefined) {
    if (Array.isArray(additionalGlobals)) {
      for (const [index, value] of additionalGlobals.entries()) {
        if (typeof value !== 'string') {
          diagnostics.push({
            path: ['additionalGlobals', index],
            messageText: `'additionalGlobals' entries must be strings.`,
          });
        }
      }
    } else {
      diagnostics.push({
        path: ['additionalGlobals'],
        messageText: `'additionalGlobals' must be an array of strings.`,
      });
    }
  }

  const additionalSpecialForms = options['additionalSpecialForms'];
  if (
    additionalSpecialForms !== undefined &&
    (typeof additionalSpecialForms !== 'object' ||
      additionalSpecialForms === null ||
      Array.isArray(additionalSpecialForms))
  ) {
    diagnostics.push({
      path: ['additionalSpecialForms'],
      messageText: `'additionalSpecialForms' must be an object.`,
    });
  }

  const formControls = options['formControls'];
  if (formControls !== undefined && typeof formControls !== 'boolean') {
    diagnostics.push({
      path: ['formControls'],
      messageText: `'formControls' must be a boolean.`,
    });
  }

  return diagnostics;
}

/**
 * @param {OpenProjectParams} params
 * @returns {OpenProjectResult}
 *   The result for the `openProject` request.
 */
export function openProject(params) {
  const options = params.options ?? {};
  const optionDiagnostics = validateOptions(options);
  const environment = GlintEnvironment.load(options);

  // The transform's output depends on configuration discovered outside the
  // tsconfig: the installed ember-source (which decides whether the 7.1
  // built-in keywords are treated as globals, and whether its types can be
  // referenced) and the installed Glint transform itself.
  const emberSource = probeEmberSource();
  const referencePrefix = buildReferencePrefix(emberSource?.version);

  projects.set(params.projectHandle, { params, environment, referencePrefix });

  const configIdentity = [
    `${ownManifest.name}@${ownManifest.version}`,
    `@glint/ember-tsc@${emberTscManifest.version}`,
    `ember-source@${emberSource?.version ?? 'none'}`,
  ].join(';');

  /** @type {OpenProjectResult} */
  const result = { configIdentity };
  if (emberSource) {
    result.watchedFiles = [emberSource.packageJsonPath];
  }

  if (optionDiagnostics.length > 0) {
    result.optionDiagnostics = optionDiagnostics;
  }

  return result;
}
