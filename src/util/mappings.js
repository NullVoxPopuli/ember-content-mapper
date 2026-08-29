/**
 * @import { CodeInformation } from '@volar/language-core'
 * @import TransformedModule from '@glint/ember-tsc/transform/template/transformed-module'
 * @import { CorrelatedSpan } from '@glint/ember-tsc/transform/template/transformed-module'
 * @import GlimmerASTMappingTree from '@glint/ember-tsc/transform/template/glimmer-ast-mapping-tree'
 * @import { SpanMapping } from '../protocol.js'
 */

import { SpanMapFeature, SpanMapKind } from '../constants.js';

/**
 * A region of virtual and original text, in absolute offsets.
 *
 * @typedef {object} Region
 * @property {number} originalStart
 * @property {number} originalEnd
 * @property {number} virtualStart
 * @property {number} virtualEnd
 */

/**
 * The placeholder Glint emits for an `@glint-expect-error` directive: a
 * `// @ts-expect-error` comment followed by an empty `;` statement, so that
 * the comment has a line to apply to.
 *
 * @typedef {Region & { statementStart: number, statementEnd: number }} Placeholder
 */

/**
 * Directive-related regions recovered from the mapping tree.
 *
 * Glint does not report `@glint-expect-error` / `@glint-ignore` /
 * `@glint-nocheck` directives as data on the transformed module. Instead it
 * bakes their semantics into each mapping node's Volar `CodeInformation`:
 * nodes inside an ignored area carry `verification: false`, nodes inside an
 * expect-error area carry a `verification.shouldReport` callback, and each
 * expect-error directive additionally emits a placeholder `// @ts-expect-error`
 * comment node that maps back to the directive comment in the template.
 *
 * @typedef {object} DirectiveAnalysis
 * @property {Region[]} scaffolding
 *   Synthesized regions (placeholder comments, the auto-import anchor) whose
 *   TypeScript diagnostics must be suppressed.
 * @property {Placeholder[]} placeholders
 *   Placeholder comment regions; their original range is the
 *   `@glint-expect-error` directive comment.
 * @property {Region[]} expectNodes
 *   Mapping nodes inside an expect-error area of effect.
 * @property {Region[]} ignoreNodes
 *   Mapping nodes inside an ignore/nocheck area of effect.
 */

/**
 * Compute the SpanMapFeature bitmask for a Volar CodeInformation object.
 *
 * Glint's transform annotates each mapping-tree node with Volar's coarse
 * feature switches; TypeScript 7 wants a finer-grained bitmask. Features are
 * grouped the same way Volar groups them.
 *
 * @param {CodeInformation | undefined} info
 *   The Volar code information for a mapping node.
 * @returns {number}
 *   The corresponding SpanMapFeature bitmask.
 */
function featuresFor(info) {
  if (!info) {
    return SpanMapFeature.All;
  }

  let features = SpanMapFeature.None;

  if (info.completion) {
    features |= SpanMapFeature.Completion | SpanMapFeature.AutoInsert;
  }

  if (info.semantic) {
    features |=
      SpanMapFeature.Hover |
      SpanMapFeature.SignatureHelp |
      SpanMapFeature.InlayHints |
      SpanMapFeature.CodeLens |
      SpanMapFeature.CodeActions;

    const shouldHighlight =
      typeof info.semantic !== 'object' || (info.semantic.shouldHighlight?.() ?? true);
    if (shouldHighlight) {
      features |= SpanMapFeature.SemanticTokens;
    }
  }

  if (info.navigation) {
    features |=
      SpanMapFeature.Definition |
      SpanMapFeature.TypeDefinition |
      SpanMapFeature.Implementation |
      SpanMapFeature.References |
      SpanMapFeature.Rename |
      SpanMapFeature.CallHierarchy |
      SpanMapFeature.DocumentHighlights |
      SpanMapFeature.LinkedEditing;
  }

  if (info.structure) {
    features |=
      SpanMapFeature.DocumentSymbols |
      SpanMapFeature.FoldingRanges |
      SpanMapFeature.SelectionRanges;
  }

  if (info.format) {
    features |= SpanMapFeature.Formatting;
  }

  return features;
}

/**
 * Whether a synthesized region is scaffolding for Glint's Volar-based
 * diagnostic handling: `@ts-expect-error` placeholders emitted for
 * `@glint-expect-error` directives, or the auto-import anchor reference.
 * These would produce spurious diagnostics (TS2578, TS2688) under plain
 * TypeScript, so the transform covers them with Ignore directives instead.
 *
 * @param {string} virtualText
 *   The synthesized text.
 * @returns {boolean}
 *   Whether the text needs an Ignore cover.
 */
function isVolarScaffolding(virtualText) {
  const trimmed = virtualText.trimStart();
  return trimmed.startsWith('// @ts-expect-error') || trimmed.startsWith('/// <reference');
}

/**
 * Flatten a Glint TransformedModule into non-overlapping TypeScript 7 span
 * mappings.
 *
 * Glint's own Volar mappings deliberately overlap (wide verification-only
 * spans cover the same generated text as their narrower children), which the
 * content mapper protocol forbids. Instead of consuming those, this walks the
 * correlated spans and their mapping trees directly:
 *
 * - Script content copied verbatim becomes a single Verbatim mapping with all
 *   language features enabled.
 * - Within templates, leaf nodes whose original and generated text match
 *   byte-for-byte (identifiers, string literals) become Verbatim mappings
 *   carrying the node's language features.
 * - Generated boilerplate between child nodes becomes Atom mappings back to
 *   the enclosing node's original range with no language features, so that
 *   diagnostics anchored on synthesized code (e.g. a `resolve(...)` callee)
 *   still map into the template.
 *
 * @param {TransformedModule} transformedModule
 *   The module produced by Glint's `rewriteModule`.
 * @returns {{ mappings: SpanMapping[], analysis: DirectiveAnalysis }}
 *   The flattened span mappings plus the directive analysis.
 */
export function buildMappings(transformedModule) {
  /** @type {SpanMapping[]} */
  const mappings = [];
  /** @type {DirectiveAnalysis} */
  const analysis = { scaffolding: [], placeholders: [], expectNodes: [], ignoreNodes: [] };
  const transformed = transformedModule.transformedContents;

  /**
   * @param {CorrelatedSpan} span
   *   The correlated span the node belongs to.
   * @param {number} spanVirtualStart
   *   The recomputed absolute offset of the span in the transformed text.
   * @param {GlimmerASTMappingTree} node
   *   The mapping-tree node to flatten.
   */
  function walk(span, spanVirtualStart, node) {
    const virtualStart = spanVirtualStart + node.transformedRange.start;
    const virtualEnd = spanVirtualStart + node.transformedRange.end;
    const originalStart = span.originalStart + node.originalRange.start;
    const originalEnd = span.originalStart + node.originalRange.end;
    const originalLength = originalEnd - originalStart;

    if (virtualEnd <= virtualStart) {
      return;
    }

    if (node.originalRange.start < 0 || node.originalRange.end < node.originalRange.start) {
      // Under @glint/ember-tsc 1.11, a block whose body contains a nested
      // block's `|params|` anchors its own params with an indexOf that can
      // miss (fixed upstream in typed-ember/glint#1235). The fixture at
      // test/fixtures/invalid-original-range emits, for `groupId`:
      //
      //   { originalRange: { start: -1, end: 6 }, ... }
      //
      // `span.originalStart + (-1)` would anchor that mapping just before the
      // template span — inside the script's verbatim mapping — and
      // demoteOverlappingOriginals would demote the script mapping to a
      // zero-length anchor: every script diagnostic then reports at (1,1).
      // Treat the node as unmapped boilerplate (parent gap mappings) instead.
      return;
    }

    const virtualText = transformed.slice(virtualStart, virtualEnd);
    const originalText = span.originalFile.contents.slice(originalStart, originalEnd);
    const region = { originalStart, originalEnd, virtualStart, virtualEnd };

    const verification = node.codeInformation?.verification;
    if (verification === false) {
      analysis.ignoreNodes.push(region);
    } else if (typeof verification === 'object') {
      if (virtualText !== originalText && virtualText.startsWith('// @ts-expect-error')) {
        // The placeholder comment Glint emits for an expect-error directive.
        // Left unsuppressed it would always produce TS2578.
        analysis.scaffolding.push(region);
        const statementStart = transformed.indexOf(';', virtualEnd);
        analysis.placeholders.push({ ...region, statementStart, statementEnd: statementStart + 1 });
        return;
      }

      analysis.expectNodes.push(region);
    }

    const children = node.children
      .slice()
      .sort((a, b) => a.transformedRange.start - b.transformedRange.start);

    if (children.length === 0) {
      const kind = virtualText === originalText ? SpanMapKind.Verbatim : SpanMapKind.Atom;
      mappings.push([
        virtualStart,
        virtualEnd - virtualStart,
        originalStart,
        originalLength,
        kind,
        featuresFor(node.codeInformation),
      ]);
      return;
    }

    let cursor = virtualStart;
    for (const child of children) {
      const childVirtualStart = spanVirtualStart + child.transformedRange.start;
      const childVirtualEnd = spanVirtualStart + child.transformedRange.end;
      if (childVirtualStart > cursor) {
        pushGapMappings(cursor, childVirtualStart, originalStart, originalLength);
      }

      walk(span, spanVirtualStart, child);
      cursor = Math.max(cursor, childVirtualEnd);
    }

    if (virtualEnd > cursor) {
      pushGapMappings(cursor, virtualEnd, originalStart, originalLength);
    }
  }

  /**
   * Map a synthesized boilerplate segment back to the enclosing node's
   * original range, leaving holes around Glint's `__glintY__` declarations.
   *
   * The transform declares `const __glintY__ = __glintDSL__.emitElement(...)`
   * for every element, and the binding goes unused when the element has no
   * attributes, modifiers, or blocks. TypeScript suppresses
   * declared-but-not-used diagnostics only in unmapped regions, so mapping
   * the declaration name would surface a TS6133 hint in editors.
   *
   * @param {number} virtualStart
   *   The start of the gap in the transformed text.
   * @param {number} virtualEnd
   *   The end of the gap in the transformed text.
   * @param {number} originalStart
   *   The start of the enclosing node's original range.
   * @param {number} originalLength
   *   The length of the enclosing node's original range.
   */
  function pushGapMappings(virtualStart, virtualEnd, originalStart, originalLength) {
    const declaration = 'const __glintY__ =';
    const binding = '__glintY__';
    const text = transformed.slice(virtualStart, virtualEnd);

    let cursor = virtualStart;
    let index = text.indexOf(declaration);
    while (index !== -1) {
      const holeStart = virtualStart + index + 'const '.length;
      const holeEnd = holeStart + binding.length;
      if (holeStart > cursor) {
        mappings.push([
          cursor,
          holeStart - cursor,
          originalStart,
          originalLength,
          SpanMapKind.Atom,
          SpanMapFeature.None,
        ]);
      }

      cursor = holeEnd;
      index = text.indexOf(declaration, index + declaration.length);
    }

    if (virtualEnd > cursor) {
      mappings.push([
        cursor,
        virtualEnd - cursor,
        originalStart,
        originalLength,
        SpanMapKind.Atom,
        SpanMapFeature.None,
      ]);
    }
  }

  // Glint records incorrect `transformedStart` values for some synthesized
  // trailing spans, so recompute every span's absolute offset the same way
  // the transformed contents were assembled: by accumulating the lengths of
  // each span's transformed source in order.
  let virtualOffset = 0;
  for (const span of transformedModule.correlatedSpans) {
    const spanVirtualStart = virtualOffset;
    virtualOffset += span.transformedSource.length;

    if (span.glimmerAstMapping) {
      walk(span, spanVirtualStart, span.glimmerAstMapping);
      continue;
    }

    if (span.transformedSource.length === 0) {
      continue;
    }

    const originalText = span.originalFile.contents.slice(
      span.originalStart,
      span.originalStart + span.transformedSource.length,
    );

    if (span.transformedSource === originalText) {
      mappings.push([
        spanVirtualStart,
        span.transformedSource.length,
        span.originalStart,
        span.transformedSource.length,
        SpanMapKind.Verbatim,
      ]);
    } else if (isVolarScaffolding(span.transformedSource)) {
      analysis.scaffolding.push({
        originalStart: span.originalStart,
        originalEnd: span.originalStart + span.originalLength,
        virtualStart: spanVirtualStart,
        virtualEnd: virtualOffset,
      });
    } else {
      mappings.push([
        spanVirtualStart,
        span.transformedSource.length,
        span.originalStart,
        span.originalLength,
        SpanMapKind.Atom,
        SpanMapFeature.None,
      ]);
    }
  }

  demoteOverlappingOriginals(mappings);
  mappings.sort((a, b) => a[0] - b[0]);

  // Defensive: the protocol rejects overlapping virtual spans, so trim or drop
  // anything that overlaps its predecessor rather than failing the transform.
  /** @type {SpanMapping[]} */
  const disjoint = [];
  let previousEnd = 0;
  for (const mapping of mappings) {
    let [virtualStart, virtualLength] = mapping;
    if (virtualStart < previousEnd) {
      const overlap = previousEnd - virtualStart;
      if (overlap >= virtualLength) {
        continue;
      }

      // Trimming changes the length, so a Verbatim mapping can no longer
      // guarantee identical text; demote it to Atom.
      mapping[0] = previousEnd;
      mapping[1] = virtualLength - overlap;
      mapping[4] = SpanMapKind.Atom;
    }

    disjoint.push(mapping);
    previousEnd = mapping[0] + mapping[1];
  }

  return { mappings: disjoint, analysis };
}

/**
 * TypeScript rejects mappings whose original spans overlap without being
 * identical. The mapping tree nests original ranges by design: boilerplate
 * around `{{foo.bar}}`'s children maps to the whole mustache while `foo` and
 * `bar` map to themselves. Resolve the conflict by demoting every mapping
 * whose original range strictly contains another mapping's distinct range to
 * a zero-length anchor at its original start: diagnostics that TypeScript
 * anchors on synthesized boilerplate then point at the start of the template
 * construct that produced it, while identifier-level mappings keep their
 * exact ranges.
 *
 * microsoft/TypeScript#63936 removes this restriction; once that ships, this
 * pass (and the anchor-point fidelity loss) can go away.
 *
 * @param {SpanMapping[]} mappings
 *   The mappings to fix up, mutated in place.
 * @returns {undefined}
 */
function demoteOverlappingOriginals(mappings) {
  const sorted = mappings.slice().sort((a, b) => a[2] - b[2] || b[2] + b[3] - (a[2] + a[3]));

  /** @type {SpanMapping[]} */
  const stack = [];
  /** @type {Set<SpanMapping>} */
  const demote = new Set();

  for (const mapping of sorted) {
    const start = mapping[2];
    const end = start + mapping[3];

    while (stack.length > 0) {
      const top = /** @type {SpanMapping} */ (stack.at(-1));
      if (top[2] + top[3] <= start) {
        stack.pop();
      } else {
        break;
      }
    }

    for (const open of stack) {
      if (open[2] !== start || open[2] + open[3] !== end) {
        demote.add(open);
      }
    }

    stack.push(mapping);
  }

  for (const mapping of demote) {
    mapping[3] = 0;
    mapping[4] = SpanMapKind.Atom;
  }
}
