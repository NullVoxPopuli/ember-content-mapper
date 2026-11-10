import type { TOC } from '@ember/component/template-only';
export interface GreetingSignature {
    Args: {
        name: string;
    };
    Blocks: {
        default?: [];
    };
    Element: HTMLParagraphElement;
}
export declare const Greeting: TOC<GreetingSignature>;
export default Greeting;
