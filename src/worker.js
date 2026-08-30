// A transform worker (tinypool). Each task carries its project's
// `openProject` params, so a worker opens the project on first use.

import { openProject } from './requests/open-project.js';
import { transform } from './requests/transform.js';
import { projects } from './util/projects.js';

/**
 * @import { OpenProjectParams, TransformParams, TransformResult } from './protocol.js'
 */

/**
 * @param {{ project: OpenProjectParams, params: TransformParams }} task
 * @returns {TransformResult}
 */
export default function run({ project, params }) {
  if (!projects.has(params.projectHandle)) {
    openProject(project);
  }
  return transform(params);
}
