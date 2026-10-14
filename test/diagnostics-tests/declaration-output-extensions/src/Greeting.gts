import type { TOC } from '@ember/component/template-only';

export interface GreetingSignature {
  Args: { name: string };
  Blocks: { default?: [] };
  Element: HTMLParagraphElement;
}

export const Greeting: TOC<GreetingSignature> = <template>
  <p ...attributes>Hello, {{@name}}! {{yield}}</p>
</template>;

export default Greeting;
