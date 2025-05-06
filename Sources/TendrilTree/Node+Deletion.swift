//
//  Node+Deletion.swift
//  TendrilTree
//
//  Implements the deletion logic for Nodes.
//
//  Key Operations & Invariant Maintenance:
//
//  - Operates on UTF-16 offsets and lengths.
//  - Handles deletions spanning multiple nodes.
//  - **Paragraph Invariant Maintenance:** Deletion preserves the invariant that
//    leaves contain whole paragraphs ending in '\n'.
//      - If a deletion removes the trailing '\n' from the content represented by a
//        left subtree, content is pulled from the *next* logical leaf (using
//        `cutLeaf`) and appended to the affected leaf to restore the invariant
//        before balancing.
//  - **Node Removal:** Nodes become eligible for removal if their content or
//    subtree becomes empty.
//  - **Balancing & Caching:** Standard AVL balancing and cache invalidation (see
//    Node.swift) are applied after mutations. `resetCache()` is called before
//    potential structural changes.
//  - **Pre-condition:** Assumes the provided deletion range is valid (checked by
//    `TendrilTree`).
//

import Foundation

extension Node {
    // MARK: - Delete

    func delete(location: Int, length: Int) -> Node? {
        guard length > 0 else {
            return self
        }
        
        resetCache()
        
        if let leafSelf = self as? Leaf {
            /// Deletion is localized to this leaf
            return leafSelf.deleteFromLeaf(location: location, length: length)
        }
        
        if location >= weight {
            /// Deletion is localized to the right branch
            return deleteFromRight(location: location, length: length)
        }
        
        if location + length < weight {
            /// Deletion is localized to the left branch
            /// And does *not* include the rightmost trailing newline
            return deleteFromLeft(location: location, length: length)
        }
        
        return deleteFromBoth(location: location, length: length)
    }
    
    private func deleteFromBoth(location: Int, length: Int) -> Node? {
        /// calculate length of deletion from right branch before weight is mutated
        let rightDeletionLength = location + length - weight
        
        self.left = self.left?.delete(location: location, length: length)
        self.weight -= min(length, weight - location)
        
        if rightDeletionLength > 0 {
            /// Deletion is spread across both branches
            self.right = self.right?.delete(location: 0, length: rightDeletionLength)
        }
        
        if self.left == nil {
            return self.right
        }
        
        /// Trailing newline of left was deleted.
        /// Combine with next leaf to maintain the invariant that paragraphs aren't split between nodes.
        self.right = self.right?.cutLeaf(at: 0) { leaf in
            self.left = self.left?.insert(line: leaf.content, at: location)
            self.weight += leaf.content.utf16Length
            if let children = leaf.collapsedChildren, let leftLeaf = leafAt(offset: location) {
                leftLeaf.collapsedChildren = children
            }

        }
        
        if self.right == nil {
            return self.left
        }
        
        return self.balance()
    }
        
    private func deleteFromRight(location: Int, length: Int) -> Node? {
        if let right = self.right?.delete(location: location - weight, length: length) {
            self.right = right
            return self.balance()
        } else {
            return self.left
        }
    }
    
    private func deleteFromLeft(location: Int, length: Int) -> Node? {
        if let left = self.left?.delete(location: location, length: length) {
            self.left = left
            self.weight -= length
            return self.balance()
        } else {
            return self.right
        }
    }
    
    private func cutLeaf(at location: Int, onCut: (Leaf) -> Void) -> Node? {
        if let leafSelf = self as? Leaf {
            onCut(leafSelf)
            return nil
        }
        
        resetCache()
        
        if location < weight {
            self.left = left?.cutLeaf(at: location) { leaf in
                self.weight -= leaf.content.utf16Length
                onCut(leaf)
            }
            
            if left == nil {
                return right
            }
            if right == nil {
                return left
            }
            return self.balance()
        } else {
            self.right = right?.cutLeaf(at: location - weight) { leaf in
                self.weight -= leaf.content.utf16Length
                onCut(leaf)
            }

            if left == nil {
                return right
            }
            if right == nil {
                return left
            }
            return self.balance()
        }
    }
}

extension Leaf {
    fileprivate func deleteFromLeaf(location: Int, length: Int) -> Node? {
        if location == 0 && length >= weight {
            return nil
        }
        
        var newContent = ""
        if location > 0, let prefixIndex = content.charIndex(utf16Index: location) {
            newContent += content.prefix(upTo: prefixIndex)
        }
        if length + location < weight, let suffixIndex = content.charIndex(utf16Index: location + length) {
            newContent += content.suffix(from: suffixIndex)
        } else {
            /// NB: if the suffix is deleted it can remove the trailing newline,
            ///    breaking the invariant that each Node contains a whole paragraph.
            self.collapsedChildren = nil
        }
        self.content = newContent
        self.weight = self.content.utf16Length
        return self
    }

}
