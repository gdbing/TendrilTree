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

*   **Goal:** Implement the `collapse(range:)` method to hide child paragraphs under a parent leaf.
*   **Tests:**
    *   Test `collapse(range:)` identifying the correct parent `Leaf` based on the start of the range.
    *   Test identifying the correct range of child leaves (subsequent leaves with greater indentation) and their descendants.
    *   Test that the child range is correctly removed from the visible tree (`delete` is called internally).
    *   Test that `parentLeaf.collapsedChildren` is populated with a new `Node` subtree representing the removed children (maintaining their relative structure and content).
    *   Test `TendrilTree.string` and `TendrilTree.length` are updated correctly (decrease).
    *   Test collapsing when there are no children (should be a no-op or specific error).
    *   Test collapsing a leaf that is already collapsed (should be a no-op or error).
    *   Test `TendrilTreeError.cannotCollapse`, `TendrilTreeError.invalidRange`.
*   **Implementation:**
    *   Implement logic to find the primary parent `Leaf` at `range.location`.
    *   Implement logic to find the contiguous range (`childrenRange`) of subsequent leaves that are descendants (based on `indentation > parentLeaf.indentation`). This might involve tree traversal.
    *   Extract the content of the `childrenRange`. This might involve:
        *   Getting the string representation of the children range (using `Node.string` on a temporary split?).
        *   Parsing this string using `Node.parse` to create the `collapsedTree`. **OR**
        *   Using `Node.split` carefully to isolate the `childrenRange` as a `Node` subtree directly. (More efficient if possible).
    *   Call `self.delete(range: childrenNSRange)` to remove the children from the visible tree. Ensure the `NSRange` used for deletion is correct (tab-inclusive).
    *   Set `parentLeaf.collapsedChildren = collapsedTree`.
    *   Update `TendrilTree.length` accurately.
    *   Add appropriate error handling.

**Stage 7: Expand Operation**

*   **Goal:** Implement the `expand(range:)` method to restore collapsed children into the visible tree.
*   **Tests:**
    *   Test `expand(range:)` identifying `Leaf` nodes within the range that have `collapsedChildren != nil`.
    *   Test that the `collapsedTree` is correctly retrieved.
    *   Test that the `collapsedTree` content is inserted back into the main tree immediately after the parent `Leaf`.
    *   Test that `parentLeaf.collapsedChildren` is set back to `nil`.
    *   Test `TendrilTree.string` and `TendrilTree.length` are updated correctly (increase).
    *   Test expanding a leaf that is not collapsed (should be a no-op or error).
    *   Test expanding multiple collapsed sections within the range.
    *   Test `TendrilTreeError.cannotExpand`, `TendrilTreeError.invalidRange`.
*   **Implementation:**
    *   Implement logic to find leaves within the `range` where `leaf.collapsedChildren != nil`. Iterate through them.
    *   For each such leaf:
        *   Retrieve `collapsedTree = leaf.collapsedChildren`.
        *   Set `leaf.collapsedChildren = nil`.
        *   Determine the correct insertion point (visible offset immediately after the parent leaf). This requires careful offset calculation.
        *   Insert the `collapsedTree` back into the main tree. This requires a robust way to insert a `Node` subtree. Using `split` and `join` is the likely approach:
            *   `let (left, right) = root.split(at: insertionOffset)`
            *   `let tempRoot = Node.join(left, collapsedTree)`
            *   `root = Node.join(tempRoot, right)`
        *   Update `TendrilTree.length` accurately (requires knowing the visible length of the `collapsedTree` *before* insertion).
    *   Add appropriate error handling.

## Post-Implementation

*   **Review & Refactor:** After all stages, review the code for clarity, efficiency, and consistency.
*   **Performance Testing:** Profile key operations (insert, delete, collapse, expand, string generation) on large documents. Optimize bottlenecks, potentially revisiting length calculation or subtree insertion/extraction logic.
*   **Documentation:** Update README and code comments thoroughly.

---