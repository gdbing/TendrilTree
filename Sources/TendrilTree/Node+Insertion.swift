//
//  Node+Insertion.swift
//  TendrilTree
//
//  Implements the insertion logic for Nodes.
//
//  Key Operations & Invariant Maintenance:
//
//  - Operates on UTF-16 offsets.
//  - **Paragraph Invariant Maintenance:** Insertion preserves the invariant that
//    leaves contain whole paragraphs ending in '\n'.
//      - **Leaf Splitting:** If an insertion introduces a '\n' the leaf node is
//        converted into an internal node with two new leaf children (`splitNode`)
//        to maintain the paragraph invariant.
//  - **Input Content:** This `Node.insert` method assumes the input `content` string
//    does not contain internal newlines that would require splitting across multiple
//    paragraphs *within this single call*. Multi-line input is handled by the
//    `TendrilTree` wrapper.
//  - **Balancing & Caching:** Standard AVL balancing and cache invalidation (see
//    Node.swift) are applied after mutations. `resetCache()` is called before
//    potential structural changes.
//

import Foundation

extension Node {
    private var isLeaf: Bool {
        return content != nil
    }
    
    internal func insert(content: String, at offset: Int) -> Node {
        if isLeaf {
            return insertIntoLeaf(content, at: offset)
        } else {
            return insertIntoBranch(content, at: offset)
        }
        
    }
    
    @inlinable
    internal func insertIntoBranch(_ insertion: String, at offset: Int) -> Node {
        resetCache()
        
        if offset < weight {
            if let left {
                self.left = left.insert(content: insertion, at: offset)
                self.weight += insertion.utf16Length
            } else {
                fatalError("insertIntoBranch: missing left child")
            }
        } else {
            if let right {
                self.right = right.insert(content: insertion, at: offset - weight)
            } else {
                fatalError("insertIntoBranch: missing right child")
            }
        }
        return self.balance()
    }
    
    @inlinable
    internal func insertIntoLeaf(_ insertion: String, at offset: Int) -> Node {
        guard let content = self.content, let offsetIndex = content.charIndex(utf16Index: offset) else {
            fatalError("insertIntoLeaf: missing text or offset out of bounds")
        }
        
        let prefix = content.prefix(upTo: offsetIndex)        
        if prefix.hasSuffix("\n") {
            // appending under the last paragraph
            return splitNode(leftContent: String(prefix), rightContent: insertion)
        }
        
        if insertion.hasSuffix("\n") {
            return splitNode(leftContent: prefix + insertion, rightContent: String(content.suffix(from: offsetIndex)))
        }
        
        self.content = content.prefix(upTo: offsetIndex) + insertion + String(content.suffix(from: offsetIndex))
        self.weight += insertion.utf16Length
        return self
    }
    
    
    @inlinable
    internal func splitNode(leftContent: String, rightContent: String) -> Node {
        guard leftContent.utf16Length > 0 else {
            self.content = rightContent
            self.weight = rightContent.utf16Length
            return self
        }
        
        guard rightContent.utf16Length > 0 else {
            self.content = leftContent
            self.weight = leftContent.utf16Length
            return self
        }
        
        let left = Node()
        left.content = leftContent
        left.weight = leftContent.utf16Length
        
        let right = Node()
        right.content = rightContent
        right.weight = rightContent.utf16Length
        
        self.left = left
        self.right = right
        self.content = nil
        self.weight = leftContent.utf16Length
        
        return self
    }
}
