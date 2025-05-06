# Outliner Application Specification

This document specifies the behavior of the core operations within the outliner application, particularly focusing on how they interact with collapsed nodes. The application operates on a plain text document where each line/paragraph represents a node in a hierarchical tree structure, with indentation defining parent-child relationships.

## Core Concepts

* **Node:** Each line or paragraph in the plain text document represents a node in the outline tree.
* **Hierarchy:** Established by indentation. A node's parent is the first node **above it** that has **less indentation**. This means indentation can be of any length and doesn't need to follow strict levels.
* **Collapsed Node:** A node marked as collapsed hides all its direct and indirect children from the visible `content` output. The node itself remains visible.
* **Visible Content:** The string representation of the outline, excluding the content and subsequent children of collapsed nodes. The `content` API provides this.
* **Range:** Refers to a range within the **visible content** string. Operations using a range must translate this back to the underlying node and offset structure.

## 1. Collapse Operation

`collapse(range: NSRange)`

This operation marks one or more nodes as collapsed, hiding their descendants from the visible content. The range should map to one or more full nodes based on the visible content.

* **Behavior:** When a range corresponding to one or more nodes is targeted, these nodes are marked as collapsed.
* **Effect on Children:** When a node is collapsed, all its children and their descendants are hidden in the visible content (`content` API). They are not deleted from the underlying data structure.
* **Collapsing a node that has collapsed children:** The node itself is marked as collapsed. Its already collapsed children remain collapsed in their own right within the hidden structure. The visible outcome is the same – the node's descendants are hidden.
* **Collapsing a child node:** Collapsing a child node only hides its descendants. It does not affect the collapsed state of its parent or siblings.
* **Range Interpretation:** The `range` parameter specifies the section of the **visible content** that the user is targeting for collapse. The application should identify the full nodes that are entirely or partially contained within this range and apply the collapse action to them. A common interaction is clicking a disclosure indicator next to a node; this action should map to collapsing the corresponding node regardless of the exact range. For a range-based API, if the range starts within a node, that node should be a candidate for collapsing. If the range spans multiple nodes, all nodes fully or partially within the range (from start of the first node in the range to the end of the last) should be collapsed.

## 2. Expand Operation

`expand(range: NSRange)`

This operation reveals the hidden children of one or more collapsed nodes. The range should map to one or more collapsed nodes based on the visible content.

* **Behavior:** When a range corresponding to one or more collapsed nodes is targeted, these nodes are marked as not collapsed.
* **Effect on Children:** Expanding a node makes its direct children visible in the `content` output. If those children are themselves collapsed, their descendants will remain hidden.
* **Expanding a non-collapsed node:** This operation should have no effect.
* **Expanding a child node:** Expanding a child node only makes its direct children visible (if they were hidden due to the child being collapsed). It does not affect the collapsed state of its parent or siblings.
* **Range Interpretation:** Similar to `collapse`, the `range` parameter specifies the section of the **visible content**. The application should identify the collapsed nodes that are entirely or partially contained within this range and expand them. If the range starts within a collapsed node, that node should be expanded. If the range spans multiple collapsed nodes, all collapsed nodes fully or partially within the range should be expanded.

## 3. Insert Operation

`insert(content: String, atOffset: Int)`

This operation inserts text into the document at a specific offset within the **visible content**. Its behavior is modified by the presence of collapsed nodes, particularly when inserting newline characters.

* **Inserting text *within* a collapsed node:**
    * The `content` is inserted into the text of the target node at the specified offset within its visible content.
    * The collapsed state of the node is unaffected.
    * The hidden children of the node are unaffected.
* **Inserting non-newline text immediately before or after a collapsed node (in the visible content):**
    * The `content` is inserted at the specified offset in the adjacent node's content.
    * The collapsed state of the neighboring collapsed node is unaffected.
* **Inserting a newline (`\n`) *at the end* of a line (node) that is currently collapsed (via visible content offset):**
    * The collapsed node remains collapsed.
    * A new, empty node is created immediately after the collapsed node in the underlying tree structure.
    * This new node is inserted at the same indentation level as the collapsed node.
    * The cursor/insertion point moves to the beginning of this new node in the visible content.
* **Inserting a newline (`\n`) immediately *before* a line (node) that is currently collapsed (via visible content offset):**
    * **If inserted at the very beginning of the visible line content:** A new, empty node is created immediately before the collapsed node in the underlying tree structure. This new node is inserted at the same indentation level as the collapsed node. The collapsed node remains collapsed.
    * **If inserted in the middle of the visible line content:** The current node (which is immediately before the collapsed node in the visible content) is split into two nodes at the insertion point. The original node's collapsed children (if any) remain children of the *first* (top) resulting node. The collapsed node that was originally after the insertion point now follows the second (bottom) resulting node. The collapsed state of the following node is unaffected.

## 4. Delete Operation

`delete(range: NSRange)`

This operation deletes a range of text from the document based on a range within the **visible content**. Its behavior is significantly impacted by collapsed nodes when the deletion range crosses node boundaries or affects a collapsed node directly.

* **Deleting text *within* a collapsed node (via visible content range):**
    * The text is deleted from the node's content.
    * The collapsed state of the node is unaffected.
    * The hidden children of the node are unaffected.
* **Deleting the entire line of a collapsed node (by deleting its visible content and the trailing newline, or the node itself if it's the last in the document, via visible content range):**
    * The underlying collapsed node is deleted from the tree structure.
    * All of its hidden children are also deleted from the tree structure.
* **Deleting *only the visible content* of a collapsed node (up to the point corresponding to the newline in the visible content range):**
    * The node's content is deleted, resulting in an empty line.
    * The node remains in the tree structure.
    * The node remains collapsed.
    * Its hidden children are retained as children of the now-empty collapsed node.
* **Deleting a range that starts in a node *before* a collapsed node and ends *within* the collapsed node (via visible content range):**
    * The text within the specified range (spanning across the boundary in the visible content) is deleted.
    * The node before and the collapsed node are effectively merged at the point of deletion in the underlying structure if the deletion removes the newline separating them.
    * The collapsed state of the node is unaffected.
    * The hidden children of the collapsed node are unaffected.
* **Deleting a range that starts *within* a collapsed node and ends in a node located *after* the collapsed node (via visible content range):**
    * The text within the specified range (spanning across the boundary in the visible content) is deleted.
    * The collapsed node and the node after it are effectively merged in the underlying structure if the deletion removes the newline separating them.
    * The underlying collapsed node itself is deleted from the tree structure as its visible representation is part of the deleted range.
    * Crucially, all of the collapsed node's hidden children are also deleted from the tree structure.
* **Deleting a range that *fully encompasses* one or more collapsed nodes (starts before, ends after, via visible content range):**
    * All nodes (collapsed or not) and the text within the specified range are deleted from the underlying tree structure.
    * For each collapsed node fully encompassed by the range, the node and all of its hidden children are deleted from the tree structure.

## 5. Indent Operation

`indent(depth: Int, range: NSRange)`

This operation changes the indentation level of one or more nodes based on an `NSRange` in the **visible content**. The `depth` parameter specifies the change in indentation level (positive for indenting, negative for outdenting). The application must determine the new string-based indentation prefix for each affected node.

* **Indenting/Outdenting a non-collapsed node (via visible content range):** The node's indentation is changed based on the `depth`. Its children (if any and not collapsed) maintain their relative indentation to the parent based on the hierarchy rule.
* **Indenting/Outdenting a collapsed node (via visible content range):**
    * The collapsed node's indentation is changed based on the `depth`.
    * Its hidden children must also have their indentation adjusted to maintain their hierarchical relationship. If the parent node's indentation string changes from `P_old` to `P_new`, a child that had indentation `C_old` should have its new indentation `C_new` calculated such that the difference in indentation whitespace between `C_new` and `P_new` is the same as the difference between `C_old` and `P_old`. This ensures their relative level is preserved even when hidden.
* **Indenting/Outdenting a range that includes both collapsed and non-collapsed nodes (via visible content range):** The indentation rule for each node within the range (as described above) should apply. The hierarchy of nodes *outside* the indented range should not be affected unless an outdent causes a node to become a sibling of a former ancestor. The hierarchy rules based on indentation must be re-evaluated for the affected nodes and their neighbors after the indentation change.

This comprehensive specification covers the behavior of your outliner's operations concerning collapsed nodes and the indentation-based hierarchy. You can use this to write detailed unit tests and guide your implementation. Let me know if you'd like to refine any specific point further!