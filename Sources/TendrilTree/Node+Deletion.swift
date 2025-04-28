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
        
        if isLeaf {
            /// Deletion is localized to this leaf
            return deleteFromLeaf(location: location, length: length)
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
        if let (removedContent, subtree) = self.right?.cutLeaf(at: 0), let removedContent {
            self.right = subtree
            self.left = self.left?.insert(content: removedContent, at: location)
            self.weight += removedContent.utf16Length
        }
        
        if self.right == nil {
            return self.left
        }
        
        return self.balance()
    }
    
    private func deleteFromLeaf(location: Int, length: Int) -> Node? {
        guard let content else {
            fatalError("deleteLeaf: leaf node has no content")
        }
        if location == 0 && length >= weight {
            return nil
        }

        let prefixIndex = content.charIndex(utf16Index: location)
        let prefix = content.prefix(upTo: prefixIndex ?? content.startIndex)
        let suffixIndex = content.charIndex(utf16Index: location + length)
        let suffix = content.suffix(from: suffixIndex ?? content.endIndex)
        if !suffix.isEmpty || !prefix.isEmpty {
            self.content = String(prefix + suffix)
            self.weight = self.content!.utf16Length
            /// NB: if the suffix is deleted it can remove the trailing newline,
            ///    breaking the invariant that each Node contains a whole paragraph.
            return self
        } else {
            /// delete the whole node
            return nil
        }
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
    
    private func cutLeaf(at location: Int) -> (content: String?, node: Node?) {
        if let content = self.content {
            return (content, nil)
        }
        
        resetCache()
        
        if location < weight {
            let (removedContent, newLeft) = left?.cutLeaf(at: location) ?? (nil, nil)
            self.left = newLeft
            self.weight -= removedContent?.utf16Length ?? 0
            
            if left == nil {
                return (removedContent, right)
            }
            if right == nil {
                return (removedContent, left)
            }
            return (removedContent, self.balance())
        } else {
            let (removedContent, newRight) = right?.cutLeaf(at: location - weight) ?? (nil, nil)
            self.right = newRight
            self.weight -= removedContent?.utf16Length ?? 0

            if left == nil {
                return (removedContent, right)
            }
            if right == nil {
                return (removedContent, left)
            }
            return (removedContent, self.balance())
        }
    }
}
