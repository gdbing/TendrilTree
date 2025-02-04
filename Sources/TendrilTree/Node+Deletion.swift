//
//  Node+Deletion.swift
//  TendrilTree
//

import Foundation

extension Node {
    // MARK: - Delete

    func delete(location: Int, length: Int) -> Node? {
        cacheString = nil
        
        guard content == nil else {
            /// Deletion is localized to this leaf
            return deleteFromLeaf(location: location, length: length)
        }
        guard location < weight else {
            /// Deletion is localized to the right branch
            return deleteFromRight(location: location, length: length)
        }

        guard location + length > weight else {
            /// Deletion is localized to the left branch
            /// possibly including a trailing newline
            return deleteFromLeft(location: location, length: length)
        }
        
        /// Deletion is spread across both branches
        /// definitely including trailing newline of left branch
        self.right = self.right?.delete(location: 0, length: location + length - weight)
        self.left = self.left?.delete(location: location, length: length)
        repairParagraphPair(at: location)
        self.weight -= (weight - location)
        
        if self.right == nil {
            return self.left
        }

        if self.left == nil {
            return self.right
        }
        
        self.balance()
        return self
    }
    
    @inlinable
    internal func deleteFromLeaf(location: Int, length: Int) -> Node? {
        guard let content else {
            fatalError("deleteLeaf: leaf node has no content")
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
        balance()
        return self
    }
    
    @inlinable
    internal func deleteFromLeft(location: Int, length: Int) -> Node? {
        self.left = self.left?.delete(location: location, length: length)
        if location + length >= self.weight { // last character of left branch is included in deleted range
            repairParagraphPair(at: location)
        }
        self.weight -= length

        if self.left == nil {
            return self.right
        }
        self.balance()
        return self
    }
    
    @inlinable
    internal func repairParagraphPair(at location: Int) {
        /// Maintain the invariant that paragraphs aren't split between nodes.
        /// If the newline is missing from the end of a node's content,
        /// then delete that whole node and reinsert its contents into the next node
        guard location < weight else { return }
        
        if let node = left?.nodeAt(offset: max(0, location - 1)),
           let content = node.content,
           self.right != nil {
            if content.last != "\n" {
                self.left = self.left?.delete(location: location - node.weight, length: node.weight)
                self.right?.insert(content: content, at: 0)
            }
        }
    }
}
