/**
 * A component with `elements` nested divs, each carrying attribute
 * mustaches and a helper call — the shapes that drive Glint's mapping work.
 *
 * @param {number} elements
 * @param {string} [name]
 * @returns {string}
 */
export function template(elements, name = 'Bench') {
  const rows = Array.from(
    { length: elements },
    (_, i) =>
      `    <div class={{if this.on "a" "b"}} title={{concat "row " ${i}}}>{{this.label}} <span>{{yield}}</span></div>`,
  ).join('\n');
  return `import Component from '@glimmer/component';
import { concat } from '@ember/helper';

export default class ${name} extends Component<{ Blocks: { default: [] } }> {
  on = true;
  label = 'x';
  <template>
${rows}
  </template>
}
`;
}
