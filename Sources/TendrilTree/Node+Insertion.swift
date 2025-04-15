//
//  Node+Insertion.swift
//  TendrilTree
//

import Foundation

extension Node {
    private var isLeaf: Bool {
        return content != nil
    }
    
    internal func insert(content: String, at offset: Int) {
        if isLeaf {
            insertIntoLeaf(content, at: offset)
        } else {
            insertIntoBranch(content, at: offset)
        }
        
    }
    
    @inlinable
    internal func insertIntoBranch(_ insertion: String, at offset: Int) {
        cacheString = nil
        cacheHeight = nil
        
        if offset < weight {
            if let left {
                left.insert(content: insertion, at: offset)
                self.weight += insertion.utf16Length
            } else {
                fatalError("insertIntoBranch: missing left child")
            }
        } else {
            if let right {
                right.insert(content: insertion, at: offset - weight)
            } else {
                fatalError("insertIntoBranch: missing right child")
            }
        }
        self.balance()
    }
    
    @inlinable
    internal func insertIntoLeaf(_ insertion: String, at offset: Int) {
        guard let content = self.content, let offsetIndex = content.charIndex(utf16Index: offset) else {
            fatalError("insertIntoLeaf: missing text or offset out of bounds")
        }
        
        let prefix = content.prefix(upTo: offsetIndex)        
        if prefix.hasSuffix("\n") {
            // appending under the last paragraph
            splitNode(leftContent: String(prefix), rightContent: insertion)
            return
        }
        
        if insertion.hasSuffix("\n") {
            splitNode(leftContent: prefix + insertion, rightContent: String(content.suffix(from: offsetIndex)))
            return
        }
        
        self.content = content.prefix(upTo: offsetIndex) + insertion + String(content.suffix(from: offsetIndex))
        self.weight += insertion.utf16Length
    }
    
    
    @inlinable
    internal func splitNode(leftContent: String, rightContent: String) {
        guard leftContent.utf16Length > 0 else {
            self.content = rightContent
            self.weight = rightContent.utf16Length
            return
        }
        
        guard rightContent.utf16Length > 0 else {
            self.content = leftContent
            self.weight = leftContent.utf16Length
            return
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
    }
}
