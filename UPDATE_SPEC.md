## TendrilTree Outliner Update Specification

**1. Goals:**

*   Enhance `TendrilTree` to store and manipulate hierarchical outliner data.
*   Introduce indentation levels for paragraphs (leaves).
*   Implement collapsing and expanding of hierarchical sections.
*   Ensure existing rope operations (`insert`, `delete`) correctly handle indentation and collapsed state while maintaining performance and invariants.
*   Provide a clear API for outliner-specific manipulations.

**2. Core Data Structure Changes (`Leaf.swift`):**

*   Modify the `Leaf` class to store outliner-specific metadata:
    *   **`indentation: Int`**:
        *   Represents the logical indentation level of the paragraph (leaf).
        *   Starts at 0 for top-level items.
        *   Corresponds to the number of leading tabs (or equivalent spaces, TBD - see Section 7) that *would* prefix the line in a plain text representation.
        *   The actual `content` string **will not** store these leading whitespace characters.
    *   **`collapsedChildren: Node?`**:
        *   Stores the root of a separate `TendrilTree` subtree representing the content logically nested *under* this leaf when it is collapsed.
        *   `nil` if the leaf is not collapsed or has no children to collapse.
        *   The content within `collapsedChildren` maintains its own indentation levels relative to the document root (i.e., absolute indentation).

*   **Updated `Leaf` Definition:**

    ```swift
    class Leaf: Node {
        var content: String // Stores the paragraph text, ending in '\n', *without* leading indentation whitespace.
        var indentation: Int
        var collapsedChildren: Node? // Root of the subtree containing collapsed children.

        // Updated Initializer
        init(_ content: String, indentation: Int = 0, collapsedChildren: Node? = nil) {
            // Ensure content ends with newline, trim leading/trailing whitespace *except* the final newline.
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            self.content = trimmedContent.isEmpty ? "\n" : trimmedContent + "\n"
            self.indentation = indentation
            self.collapsedChildren = collapsedChildren
            super.init()
            // Weight remains the UTF-16 length of the *visible* content in this leaf.
            // Collapsed children do *not* contribute to the parent leaf's weight.
            self.weight = self.content.utf16Length
        }

        // string property modification needed later (see Section 6.1)

        // insert method modification needed later (see Section 6.2)

        // splitNode method modification needed later (see Section 6.2)

        // deleteFromLeaf method modification needed later (see Section 6.3)
    }
    ```

**3. Invariant Changes:**

*   **Paragraph Invariant:** Remains the same. Each `Leaf.content` must represent a single paragraph ending in `\n`.
*   **Indentation Invariant:** `Leaf.content` *never* contains the leading whitespace represented by `Leaf.indentation`. This whitespace is virtual, managed by the `indentation` property.
*   **Weight Invariant:** `Node.weight` stores the total UTF-16 length of all *visible* content (including the final `\n`) in the *left* subtree. Content within `collapsedChildren` does *not* contribute to the `weight` of parent nodes in the main tree structure.
*   **Collapsed Children Invariant:** Only `Leaf` nodes can have non-nil `collapsedChildren`. The subtree referenced by `collapsedChildren` is a valid `TendrilTree` structure itself.

**4. New Public Methods (`TendrilTree.swift`):**

*   Add the following methods to the public `TendrilTree` class:

    ```swift
    public extension TendrilTree {
        /// Returns the indentation level of the leaf containing the given UTF-16 offset.
        /// - Parameter offset: A UTF-16 offset within the document's visible content.
        /// - Returns: The indentation level (0-based).
        /// - Throws: `TendrilTreeError.invalidQueryOffset` if the offset is out of bounds or does not fall within a leaf node.
        func depth(at offset: Int) throws -> Int {
            // Implementation: Find leaf at offset, return its indentation.
            // Needs careful handling of offset == length boundary case.
        }

        /// Adjusts the indentation level of all leaves overlapping the given range.
        /// - Parameters:
        ///   - depth: The change in indentation level (positive to indent, negative to outdent).
        ///   - range: An NSRange specified in UTF-16 offsets relative to the visible content.
        /// - Note: Does not change the actual text content, only the `indentation` property.
        /// - Note: Resulting indentation is clamped at 0.
        func indent(depth: Int, range: NSRange) throws {
            // Implementation: Iterate through leaves in range, adjust indentation by depth (clamped at >= 0).
        }

        /// Collapses the children of the primary leaf node identified by the range.
        /// - Parameter range: An NSRange specified in UTF-16 offsets. Identifies the leaf node(s) whose children should be collapsed. If the range spans multiple potential parents, typically collapses children of the *first* leaf in the range.
        /// - Throws: `TendrilTreeError.invalidRange` or `TendrilTreeError.cannotCollapse` if conditions aren't met.
        func collapse(range: NSRange) throws {
            // Implementation:
            // 1. Find the primary leaf (`parentLeaf`) starting at or overlapping range.location.
            // 2. Identify subsequent sibling leaves (`childLeaf`) where `childLeaf.indentation > parentLeaf.indentation`. Stop finding children when indentation becomes <= `parentLeaf.indentation`.
            // 3. Gather the full range (`childrenRange`) of all identified children and their recursive descendants.
            // 4. Extract the content and structure of the childrenRange into a new `Node` subtree (`collapsedTree`). This likely involves:
            //    a. Getting the string representation (with indentation) of the childrenRange.
            //    b. Parsing this string using `Node.parse` to create `collapsedTree`.
            // 5. Delete `childrenRange` from the main tree using `self.delete`.
            // 6. Set `parentLeaf.collapsedChildren = collapsedTree`.
            // 7. Update `self.length` (will decrease).
            // 8. Handle potential errors (e.g., no children to collapse).
        }

        /// Expands the collapsed children of any leaves within the specified range.
        /// - Parameter range: An NSRange specified in UTF-16 offsets relative to the visible content.
        /// - Throws: `TendrilTreeError.invalidRange` or `TendrilTreeError.cannotExpand` if conditions aren't met.
        func expand(range: NSRange) throws {
            // Implementation:
            // 1. Iterate through leaves (`leaf`) overlapping the range.
            // 2. If `leaf.collapsedChildren != nil`:
            //    a. Get the `collapsedTree = leaf.collapsedChildren`.
            //    b. Set `leaf.collapsedChildren = nil`.
            //    c. Determine the insertion offset (`insertionOffset`) immediately after `leaf`.
            //    d. Insert the `collapsedTree` back into the main tree at `insertionOffset`. This requires a new internal insertion mechanism capable of inserting a Node subtree (see Section 5.2).
            //    e. Update `self.length` (will increase by the visible length of the `collapsedTree`).
            //    f. Handle potential errors.
        }
    }

    // Add new Error cases
    public enum TendrilTreeError: Error, LocalizedError {
        case invalidInsertOffset
        case invalidDeleteRange
        case invalidQueryOffset // Added for depth()
        case invalidRange // General purpose range error for outliner ops
        case cannotCollapse // e.g., no children, node already collapsed
        case cannotExpand // e.g., node not collapsed

        public var errorDescription: String? {
            // ... update descriptions
        }
    }
    ```

**5. New/Modified Internal Methods & Logic (`Node.swift`, `Leaf.swift`, etc.):**

*   **5.1. `Node.parse`:**
    *   Modify `Node.parse(paragraphs: C)`:
        *   For each input string `line`:
            *   Determine the `indentation` level by counting leading tabs (see Section 7).
            *   Remove the leading tabs from the `line`.
            *   Create the `Leaf` using `Leaf(processedLine, indentation: detectedIndentation)`.
    *   The existing `Node.parse(content:)` wrapper should work correctly if the internal `parse(paragraphs:)` is updated.

*   **5.2. Subtree Insertion (for `expand`):**
    *   A mechanism to insert an existing `Node` subtree is needed.
    *   **Option A:** Create `Node.insert(subtree: Node, at offset: Int) -> Node`. This would mirror `insert(content:at:)` but work with nodes. It would likely use `split` and `join`.
    *   **Option B:** Enhance `Node.join` to be smarter or create a specific join variant for this purpose.
    *   **Chosen Approach (Simpler):** Use existing `split` and `join`. The `expand` implementation will:
        1.  Find the `insertionOffset`.
        2.  `let (left, right) = root.split(at: insertionOffset)`
        3.  `let tempRoot = Node.join(left, collapsedTree)`
        4.  `root = Node.join(tempRoot, right)`
        5.  Ensure `split` and `join` correctly handle/propagate node properties (weight, height, etc.) and trigger balancing. `Node.join` already returns `parent.balance()`, which is good. `split` needs review to ensure it doesn't corrupt state.

*   **5.3. Iterating Leaves in Range:**
    *   Implement a helper method, possibly on `Node`, to efficiently find all `Leaf` nodes overlapping a given UTF-16 range.
    *   `func leaves(inRange range: NSRange) -> [Leaf]` (or an iterator).
    *   This will likely involve recursive descent, pruning branches that are entirely outside the range based on `weight`.

*   **5.4. Finding Leaf at Offset:**
    *   Enhance `Node.nodeAt(offset: Int)` or `nodeWithRemainderAt` to specifically return `Leaf` nodes or handle cases where the offset points exactly between leaves (which shouldn't happen if offsets correspond to positions *within* content). Add error handling or clear return types (`Leaf?`).

*   **5.5. `Leaf.splitNode` (for `insert`):**
    *   Modify `private func splitNode(leftContent: String, rightContent: String) -> Node` inside `Leaf`.
    *   When a `Leaf` is split into `newLeft` (created Leaf) and `self` (modified Leaf, becomes right part):
        *   `newLeft` should **inherit** the `indentation` and `collapsedChildren` from the original leaf.
        *   `self` (now the right part) should have its `indentation` set (likely inheriting from `newLeft`?) and `collapsedChildren` set to `nil`.
        *   Need to decide indentation inheritance on split: Does the second part keep the same indent or reset/follow different logic? Let's specify: **The second part (`self`) also inherits the original indentation.**
        *   Update weights correctly for both new leaves and the returned parent node.

*   **5.6. `Node.cutLeaf` (for `delete`):**
    *   Modify `private func cutLeaf(at location: Int) -> (content: String?, node: Node?)`
    *   Change return type to include indentation and collapsed state:
        `-> (leafData: (content: String, indentation: Int, collapsedChildren: Node?)?, node: Node?)`
    *   When a leaf is cut, return its `content`, `indentation`, and `collapsedChildren`.
    *   The caller (e.g., `deleteFromBoth`) needs to handle this `leafData`. When it re-inserts the `content` into the preceding leaf, it must now also potentially merge or handle the `indentation` and `collapsedChildren`. This merge logic needs care: If merging `cutContent` into `targetLeaf`, the `cutContent`'s indentation is lost. The `targetLeaf` should probably **keep its original `indentation` and `collapsedChildren`**. The `collapsedChildren` from the cut leaf are effectively discarded along with the leaf itself.

*   **5.7. Caching (`resetCache`):**
    *   Ensure `resetCache()` is called appropriately in all new/modified methods that change tree structure *or* properties affecting cached values (like `string` or `height`). This includes `indent`, `outdent`, `collapse`, `expand`.
    *   The `string` cache (`cacheString`) is significantly impacted by indentation and collapsing (see Section 6.1).

**6. Modified Existing Methods Behavior:**

*   **6.1. `string` Property (`Node.string`, `TendrilTree.string`):**
    *   `Node.string`: Needs to be recalculated when accessed after cache reset.
        *   When traversing, if it encounters a `Leaf`:
            *   Prepend `String(repeating: "\t", count: leaf.indentation)` to `leaf.content`.
            *   If `leaf.collapsedChildren != nil`, **do not** include the string representation of the `collapsedChildren` subtree. Optionally, append a visual indicator like ` "..."` before the leaf's `\n` if desired for debugging/representation, but this should not affect length calculations.
    *   `TendrilTree.string`: Relies on `root.string`. The final `dropLast()` (removing the trailing `\n` from the *last* visible leaf) remains correct.
    *   `TendrilTree.length`: Should reflect the length of the string *including* the virtual leading tabs, but *excluding* any content in `collapsedChildren`. This means `Node.weight` (which excludes tabs and collapsed content) is no longer sufficient on its own to calculate the total visible length.
        *   **Recalculation:** `length` might need to be recalculated by traversing the visible tree after modifications like indent/outdent/collapse/expand, summing `leaf.content.utf16Length + leaf.indentation` for each visible leaf. Alternatively, maintain `length` incrementally, which is complex but more performant.
        *   **Decision:** For simplicity initially, recalculate `length` after complex operations (`collapse`, `expand`, potentially `indent`/`outdent` if done naively). A more optimized approach can be added later. Let `Node.weight` continue to represent *only* the UTF-16 length of the content *string* in the left subtree (excluding tabs, excluding collapsed). `TendrilTree.length` becomes the source of truth for the *visible* length including virtual tabs.

*   **6.2. `insert` Operation (`Node.insert`, `Leaf.insert`):**
    *   `Leaf.insert(line: String, at offset: Int)`:
        *   The `offset` is relative to the `Leaf.content` (without virtual tabs).
        *   If the insertion causes a split (`splitNode` is called): Ensure `indentation` and `collapsedChildren` are handled as per Section 5.5.
    *   `Node.insert(content insertion: String, at offset: Int)`:
        *   The `offset` is relative to the `TendrilTree`'s visible length (including virtual tabs). Must be translated to an internal offset within a specific leaf, excluding tabs.
        *   When splitting the `insertion` into lines:
            *   Use `Node.parse` to handle the lines being inserted *en masse* (middle lines). This will correctly parse their indentation.
            *   The first/last lines inserted directly into existing leaves need special handling: they should typically inherit the indentation of the line they are inserted into or adjacent to.
            *   Requires careful offset mapping between the public (tab-inclusive) offset and the internal (tab-exclusive) offsets within leaves.
    *   `TendrilTree.insert`: Update `length` calculation to account for added content *and* its indentation.

*   **6.3. `delete` Operation (`Node+Deletion.swift`, `Leaf.deleteFromLeaf`):**
    *   `TendrilTree.delete`: The `range` is relative to the visible length (including virtual tabs). This needs translation to internal ranges/offsets. Length update needs to account for removed tabs as well as content.
    *   `Leaf.deleteFromLeaf`:
        *   `location` and `length` are relative to `Leaf.content` (without tabs).
        *   If the deletion removes the final `\n` of the leaf *and* `self.collapsedChildren != nil`:
            *   Set `self.collapsedChildren = nil`. The collapsed content is implicitly deleted with the line it was attached to.
            *   The main `TendrilTree.delete` operation needs to know the total length reduction, which now includes the length of the (now invisible) collapsed children that were discarded. This is complex. **Alternative:** Don't discard immediately. If the deletion causes this leaf to merge with the next (`cutLeaf` logic), the `collapsedChildren` might need to be transferred or handled differently.
            *   **Revised Simpler Logic:** When `\n` is deleted from a leaf with `collapsedChildren`, simply set `collapsedChildren = nil`. The length update in `TendrilTree` only accounts for the change in the *visible* text range initially. If this causes structural changes later (balancing, merging), the `length` needs correct recalculation or incremental updates.
    *   `Node.deleteFromBoth`: When using `cutLeaf`, ensure the `leafData` (including indentation, collapsedChildren) is retrieved (as per 5.6) and handled correctly during the subsequent `insert` call. As noted in 5.6, the simplest approach is often to let the target leaf keep its properties and discard those from the cut leaf during the merge.

**7. Behavior Clarifications & Considerations:**

*   **Indentation Character:** Assume `\t` (Tab) for indentation. The `indentation` property counts the number of tabs. Conversion to/from spaces would happen at a higher UI layer if needed.
*   **Maximum Indentation:** No explicit maximum enforced at this level, but outdenting stops at 0.
*   **Range Operations (`indent`, `outdent`, `collapse`, `expand`):** Specify that they affect leaves *overlapping* the `NSRange`. The primary target for `collapse` is the *first* leaf overlapping the range.
*   **Performance:**
    *   Range operations require finding leaves in the range (O(log N + k)).
    *   `collapse`/`expand` involve deletion/insertion/parsing/joining, potentially affecting large subtrees (can be O(M log N) or worse if parsing/string manipulation dominates, where M is size of collapsed/expanded content). AVL balancing helps keep main operations logarithmic relative to total nodes.
    *   `length` recalculation could be O(N) if done naively by traversal.
*   **Error Handling:** Add specific error cases (`TendrilTreeError`) for outliner operations failing (e.g., `cannotCollapse`, `cannotExpand`, `invalidQueryOffset`, `invalidRange`).
*   **Undo/Redo:** This spec doesn't cover undo. Implementing undo would require storing inverse operations or snapshots, significantly increasing complexity.

**8. API Summary (`TendrilTree`):**

*   **Properties:**
    *   `string: String` (Read-only, includes virtual tabs, excludes collapsed content)
    *   `length: Int` (Read-only, UTF-16 length of `string`)
*   **Initializers:**
    *   `init()`
    *   `init(content: String)` (Parses indentation)
*   **Basic Methods:**
    *   `insert(content: String, at offset: Int) throws` (Handles indentation)
    *   `delete(range: NSRange) throws` (Handles indentation, collapsed children)
*   **Outliner Methods:**
    *   `depth(at offset: Int) throws -> Int`
    *   `indent(depth: Int, range: NSRange) throws`
    *   `collapse(range: NSRange) throws`
    *   `expand(range: NSRange) throws`

This spec provides a comprehensive blueprint for the required changes. Implementation will require careful handling of offsets, invariants, and edge cases, particularly around the interaction between visible length (with tabs), node weights (without tabs/collapsed), and the `collapsedChildren` subtrees.