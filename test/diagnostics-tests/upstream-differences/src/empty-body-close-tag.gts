import type { ComponentLike } from '@glint/template';

declare const NoBlocks: ComponentLike<{ Args: { x: number } }>;

export const SelfClosed = <template><NoBlocks @x={{1}} /></template>;

export const ExplicitlyClosed = <template><NoBlocks @x={{1}}></NoBlocks></template>;
