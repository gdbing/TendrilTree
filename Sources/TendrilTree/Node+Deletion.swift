//
//  Node+Deletion.swift
//  TendrilTree
//

import Foundation

extension Node {
    // MARK: - Delete

    func delete(location: Int, length: Int) -> Node? {
        guard length > 0 else {
            return self
        }
        
        cacheString = nil
        cacheHeight = nil
        
        if content != nil {
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
    
    @inlinable
    internal func deleteFromLeaf(location: Int, length: Int) -> Node? {
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
    
    @inlinable
    internal func deleteFromRight(location: Int, length: Int) -> Node? {
        self.right = self.right?.delete(location: location - weight, length: length)
        if self.right == nil {
            return self.left
        }
        return self.balance()
    }
    
    @inlinable
    internal func deleteFromLeft(location: Int, length: Int) -> Node? {
        self.left = self.left?.delete(location: location, length: length)
        self.weight -= length

        if self.left == nil {
            return self.right
        }
        return self.balance()
    }
    
    private func deleteLeaf(at location: Int) -> Node? {
        if content != nil { return nil }
        
        if location < weight {
            self.left = self.left?.deleteLeaf(at: location)
        } else {
            self.right = self.right?.deleteLeaf(at: location - weight)
        }
        
        if left == nil {
            return right
        }
        
        if right == nil {
            return left
        }
        
        return self
    }
    
    private func cutLeaf(at location: Int) -> (content: String?, node: Node?) {
        if let content = self.content {
            return (content, nil)
        }
        
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
