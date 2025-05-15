# TendrilTree Outliner Implementation Plan

## Overview

This document outlines the staged plan to enhance the `TendrilTree` library with outliner capabilities, including indentation and content collapsing/expanding. The implementation will follow a Test-Driven Development (TDD) approach, where each stage begins with writing specific unit tests for the desired functionality, followed by implementing the code changes to make those tests pass. Each stage aims to leave the library in a functionally complete and stable state.

Refer to the `TendrilTree Outliner Update Specification` document for detailed design decisions.

## Guiding Principles

*   **Test-Driven:** Write tests *before* implementation for each stage.
*   **Incremental:** Build features progressively, ensuring stability at each step.
*   **Invariant Maintenance:** Continuously ensure core `TendrilTree` invariants (paragraph-based leaves, AVL balance, weight correctness relative to *visible* content) are upheld or consciously adapted.
*   **Clear API:** Maintain a clean and understandable public API for `TendrilTree`.

## Stages

**Stage 0: Baseline & Setup**

*   **Goal:** Ensure the current codebase is stable and all existing tests pass.
*   **Tests:** Verify all existing `TendrilTreeTests` pass on the `main` branch.
*   **Implementation:** No code changes. Establish a starting point.

**Stage 1: Indentation Data Model & Parsing**

*   **Goal:** Introduce the `indentation` property to `Leaf` nodes and update parsing to recognize and store indentation levels from input strings.
*   **Tests:**
    *   Test `Leaf(content:indentation:)` initializer stores both values correctly.
    *   Test `Node.parse(content:)` correctly identifies leading tabs (`\t`) in input lines, stores the count in `Leaf.indentation`, and removes the tabs from `Leaf.content`.
    *   Test parsing handles lines with no indentation (level 0).
    *   Test parsing handles empty input or input with only newlines correctly.
    *   *(Initial)* Test that `Node.string` and `TendrilTree.string` still return content *without* indentation prefixes (representation handled in Stage 3).
    *   *(Initial)* Test that `Node.weight` and `TendrilTree.length` reflect only the `Leaf.content` length (excluding virtual tabs, handled in Stage 3).
*   **Implementation:**
    *   Add `indentation: Int` property to `Leaf.swift`, default to 0.
    *   Update `Leaf.init` to accept and store `indentation`.
    *   Modify `Node.parse(paragraphs:)` (internal static method) to detect leading tabs, store the count, and trim tabs from the string before creating the `Leaf`.
    *   Ensure `Node.parse(content:)` correctly calls the modified internal parser.
    *   Ensure `resetCache()` is called where necessary, although `string` and `length` aren't fully correct yet.

**Stage 2: Preserve Indentation During Insert/Delete**

*   **Goal:** Ensure basic `insert` and `delete` operations correctly handle the `indentation` property when leaves are split or merged, preserving the outline structure during editing.
*   **Tests:**
    *   Test `insert`: When an insertion splits a `Leaf`, both the new preceding leaf and the modified original leaf (now the succeeding part) retain the *original* leaf's `indentation` level.
    *   Test `delete`: When deletion causes two leaves to merge (via the `cutLeaf` mechanism), the resulting merged leaf retains the `indentation` level of the *first* (preceding) leaf involved in the merge.
    *   Test insertions/deletions at the beginning/end of leaves and the document.
    *   Verify `Node.weight` remains accurate (based on `Leaf.content` length only).
*   **Implementation:**
    *   Modify `Leaf.splitNode` to propagate the original `indentation` to both the newly created left `Leaf` and the modified `self` (right `Leaf`).
    *   Review and potentially adjust the `Node.cutLeaf` return value (it might not need to return indentation if the merge logic always uses the target leaf's indent).
    *   Modify the merge logic within `Node+Deletion.swift` (e.g., in `deleteFromBoth` or wherever `cutLeaf`'s result is used) to explicitly preserve the indentation of the leaf being appended *to*.
    *   Ensure `weight` calculations in `insert`, `delete`, `splitNode`, and balancing remain based only on `Leaf.content.utf16Length`.

**Stage 3: Serialization & Indentation Query**

*   **Goal:** 
    *   Add a new computed property `fileString` (and `fileLength`) that includes the virtual leading tabs exactly as they must be written back to disk.  Serialization round-trips must be identical.
    *   Expose a `depth(at:)` method to query the indentation level at any UTF-16 offset in the *visible* content (for the layout engine).
*   **Tests:**
    *   `fileString`
        *   Given a document with mixed indentation, `TendrilTree.fileString` must prefix each line with `"\t"` repeated `Leaf.indentation` times, and otherwise match the input file exactly.
        *   `Node.fileString` likewise must recurse and prepend tabs on each `Leaf`.
        *   `fileLength` (UTF-16 count of `fileString`) should reflect the added tabs.
    *   `string` & `length` unaffected
        *   Existing `string` and `length` continue to represent the content *without* virtual tabs.
    *   Round-trip equality
        *   Initializing with `TendrilTree(content: someFileText)` then reading `fileString` must return exactly `someFileText`.
    *   `depth(at:)`
        *   Offsets measured in the *visible* `string` (no tabs) map to the correct `Leaf.indentation`.
        *   Querying within the first line of a leaf returns that leaf’s indentation.
        *   Queries on invalid offsets throw `TendrilTreeError.invalidQueryOffset`.
*   **Implementation:**
    *   `Leaf`: implement `fileString`
    *   `Node`: implement `fileString`
    *   `TendrilTree`: 
        *   implement `fileString`
        *   implement `depth(at offset: Int)`
        
**Stage 4: Indent/Outdent Operations**

*   **Goal:** Implement the `indent(depth: Int, range: NSRange)` method for manipulating paragraph indentation levels (positive `depth` for indenting, negative for outdenting).
*   **Tests:**
    *   Test `indent(depth: Int, range: NSRange)` correctly adjusts `Leaf.indentation` (positive `depth` increases, negative `depth` decreases, clamped at 0) for all leaves overlapping the given `NSRange`.
    *   Test ranges spanning multiple leaves, partial overlaps, and edge cases (start/end of document).
    *   Verify `TendrilTree.string` and `TendrilTree.length` are correctly updated after indentation operations.
    *   Test `TendrilTreeError.invalidRange` for invalid input ranges.
*   **Implementation:**
    *   Implement an efficient `Node.leaves(inVisibleRange range: NSRange) -> [Leaf]` helper function (using offset mapping and tree traversal).
    *   Implement `TendrilTree.indent(depth: Int, range: NSRange)`: Use `leaves(inVisibleRange:)`, iterate, adjust `indentation` by `depth` (clamped at >= 0), call `resetCache()` on affected nodes (or globally), and update `TendrilTree.length`.
    *   Ensure `TendrilTree.length` update is accurate (change in length = number of affected leaves * change in indentation level).

**Stage 5: Collapse Data Model & Basic Preservation**

*   **Goal:** Introduce the `collapsedChildren: Node?` property to `Leaf` and ensure basic operations preserve this pointer correctly. Collapsed content should not affect `string` or `length`.
*   **Tests:**
    *   Test `Leaf(content:indentation:collapsedChildren:)` initializer.
    *   Test `insert` splitting a leaf: The `collapsedChildren` pointer should remain with the original leaf object (which becomes the *left* part in the split), and the new *right* part gets `nil`. *Correction based on spec review: `splitNode` creates `newLeft` and modifies `self` to be right. `newLeft` inherits `collapsedChildren`, `self` (right part) gets `nil`.*
    *   Test `delete` merging leaves: The resulting merged leaf should retain the `collapsedChildren` pointer from the *first* (preceding) leaf.
    *   Test `delete` removing the trailing `\n` from a `Leaf` that has `collapsedChildren != nil`: Verify `collapsedChildren` becomes `nil`.
    *   Test `string` and `length` remain unaffected by the presence of `collapsedChildren`. They should only represent visible content.
*   **Implementation:**
    *   Add `collapsedChildren: Node?` to `Leaf.swift`.
    *   Update `Leaf.init`.
    *   Update `Leaf.splitNode` to handle the pointer as specified in tests/spec (new left leaf inherits, right part gets nil).
    *   Update `Leaf.deleteFromLeaf` to set `collapsedChildren = nil` if the final `\n` is deleted.
    *   Update merge logic in `Node+Deletion.swift` to preserve the `collapsedChildren` pointer of the target leaf.
    *   Explicitly ensure `Node.string` generation logic *ignores* `collapsedChildren`.
    *   Ensure `TendrilTree.length` calculation *ignores* `collapsedChildren`.

**Stage 6: Collapse Operation**

*   **Goal:** Implement the `collapse(range:NSRange)` method to hide child paragraphs under a parent leaf, based on a given range. The method must intelligently determine the appropriate collapse target(s) depending on the location and shape of the range.

Key Behaviors Based on Selection Shape:
    1.  Cursor or range within a collapsible parent node:
If the range is inside a node that has children (i.e. subsequent nodes with greater indentation), collapse that node and move its children into collapsedChildren.
    2.  Cursor or range within a child node with no children:
If the node has no children, climb upward to its nearest ancestor (a preceding node with smaller indentation), and collapse that ancestor. This collapses all its children, including the selected node.
    3.  Selection spans a collapsible node and one or more of its children:
The parent is still the collapse target. Collapse it and move all appropriate children into collapsedChildren.
    4.  Selection spans disjoint or nested collapsible regions:
For complex ranges that include multiple structural elements (e.g. a child node on line 1 and its parent on line 2), identify all distinct collapsible parents whose descendants fall within the range. Each collapsible parent should be collapsed independently.

Tests:
    •   collapse(range:) identifies:
    •   the correct parent leaf(s) based on indentation relationships and range.
    •   the correct child range(s) to collapse.
    •   Children are removed from the visible tree and preserved in collapsedChildren on the correct parent leaf.
    •   Collapsing a node that has no children is a no-op or returns TendrilTreeError.cannotCollapse.
    •   Collapsing a node that is already collapsed is a no-op or returns TendrilTreeError.cannotCollapse.
    •   TendrilTree.string and TendrilTree.length reflect the collapsed state.
    •   Multi-parent collapse scenarios are handled cleanly.
    •   Invalid ranges throw TendrilTreeError.invalidRange.

Implementation:
    •   Identify all top-level parents within the range:
    •   Traverse leaves intersecting the range.
    •   For each, determine whether it is:
    •   A collapsible parent (has children),
    •   A descendant (needs to climb to a parent).
    •   Avoid collapsing the same parent multiple times.
    •   For each identified parent:
    •   Determine the full childrenRange by scanning forward while indentation > parent.indentation.
    •   Extract the subtree for childrenRange and store in parentLeaf.collapsedChildren.
    •   Delete the children from the tree.
    •   Update length and caching appropriately.

**Stage 7: Expand Operation**

*   **Goal:** Implement expand(range:NSRange) to restore previously collapsed child paragraphs, based on the current range. This must intelligently detect whether the range intersects one or more collapsed parent nodes, and expand them appropriately.

Key Behaviors Based on Selection Shape:
    1.  Cursor or range inside a collapsed parent node:
If the range is within a node that has non-nil collapsedChildren, expand that node and reinsert the children at the correct position.
    2.  Cursor or range inside a node that is itself a collapsed child (i.e. not currently in the visible tree):
This case shouldn’t happen since collapsed children are hidden from the document view. If it does, treat it as an error or no-op.
    3.  Selection spans multiple collapsed parent nodes:
Expand all visible nodes in the range that have collapsed children.
    4.  Selection includes both collapsed and non-collapsed nodes:
Only nodes with non-empty collapsedChildren are affected. Others are ignored.

Tests:
    •   expand(range:) identifies:
    •   the correct collapsed parent leaf(s) within the range.
    •   verifies that collapsedChildren is non-empty before attempting to expand.
    •   Previously hidden children are reinserted into the tree at the correct position after the parent.
    •   Tree order, structure, and indentation are preserved after reinsertion.
    •   Expanding a node that has no collapsedChildren is a no-op or returns TendrilTreeError.cannotExpand.
    •   TendrilTree.string and TendrilTree.length reflect the expanded state.
    •   Multi-parent expansion scenarios are handled cleanly.
    •   Invalid ranges throw TendrilTreeError.invalidRange.

Implementation:
    •   Traverse visible leaves intersecting the range range.
    •   For each leaf:
    •   If it has collapsedChildren, reinsert them after the leaf in the visible tree.
    •   Clear collapsedChildren.
    •   Update all affected tree metadata:
    •   Line ranges
    •   Lengths
    •   Cache invalidation (if applicable)

## Post-Implementation

*   **Review & Refactor:** After all stages, review the code for clarity, efficiency, and consistency.
*   **Performance Testing:** Profile key operations (insert, delete, collapse, expand, string generation) on large documents. Optimize bottlenecks, potentially revisiting length calculation or subtree insertion/extraction logic.
*   **Documentation:** Update README and code comments thoroughly.