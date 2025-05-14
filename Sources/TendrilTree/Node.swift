//
//  Node.swift
//
//  Defines the core Node class for the TendrilTree rope implementation.
//
//  Core Structure & Invariants:
//
//  - **Structure:** A binary tree where leaves hold content strings and internal
//    nodes provide structure.
//  - Nodes MUST have `left` and `right` children.
//  - `weight`: Stores the total UTF-16 length of all content in the *left* subtree.
//  - **UTF-16:** All lengths (`weight`) and offsets used in operations are based on
//    UTF-16 code units for platform compatibility (e.g., TextKit).
//  - **Balancing:** Uses iterative AVL balancing (`balance()`, `leftRotate()`,
//    `rightRotate()`) after insertions/deletions to maintain logarithmic height.
//  - **Caching:** `cacheHeight` and `cacheString` optimize common operations.
//    Caches MUST be invalidated (`resetCache()`) before structural or length changes.
//

import Foundation

class Node {
    /// weight, left, and right are the bare minimum requirements of a rope node
    var weight: Int = 0
    var left: Node?
    var right: Node?

    // MARK: - init

    init() { }
    
    var cacheString: String?
    var cacheHeight: Int?
    func resetCache() {
        cacheHeight = nil
        cacheString = nil
    }

    // MARK: - Utils

    var string: String {
        if cacheString == nil {
            cacheString = (left?.string ?? "") + (right?.string ?? "")
        }
        return cacheString!
    }

    func leafAt(offset: Int) -> Leaf? {
        if let leafSelf = (self as? Leaf) {
            return leafSelf
        } else if offset < weight {
            return left?.leafAt(offset: offset)
        } else {
            return right?.leafAt(offset: offset - weight)
        }
    }
    
    func leavesAt(start: Int, end: Int) -> [Leaf] {
        if let leafSelf = (self as? Leaf) {
            return [leafSelf]
        }
        
        var result = [Leaf]()
        if start < weight {
            result += left!.leavesAt(start: start, end: end)
        }
        if end >= weight {
            result += right!.leavesAt(start: 0, end: end - weight)
        }
        
        return result
    }

    // MARK: - Insert
    
    /// Inserts a block of text at the specified UTF-16 offset.
    ///
    /// Algorithm:
    /// 1. Splits the insertion content into lines
    /// 2. Handles first and last lines separately to maintain paragraph boundaries
    /// 3. Creates a subtree from remaining middle lines (if any)
    /// 4. Splits the tree at the insertion point and joins the pieces
    ///
    /// - Parameters:
    ///   - insertion: The text to insert
    ///   - offset: UTF-16 based insertion position
    /// - Returns: The new root node after insertion
    /// - Important: Maintains the invariant that leaves contain complete paragraphs ending in '\n'
    func insert(content insertion: String, at offset: Int) -> Node {
        resetCache()
        
        var lines = insertion.splitIntoLines()
        var newSelf = self
        if let lastLine = lines.last {
            newSelf = newSelf.insert(line: lastLine, at: offset)
            lines = lines.dropLast()
        }
        var newOffset = offset
        if let firstLine = lines.first { 
            newSelf = newSelf.insert(line: firstLine, at: offset)
            newOffset += firstLine.utf16Length
        }
        if let (subTree, _) = Node.parse(paragraphs: lines.dropFirst()) {
            newSelf = newSelf.insert(subTree: subTree, at: newOffset)
        }
        
        return newSelf
    }
    
    func insert(subTree: Node, at offset: Int) -> Node {
        let (leftTree, rightTree) = self.split(at: offset)
        let mergedLeft = Node.join(leftTree, subTree)
        return Node.join(mergedLeft, rightTree) ?? Leaf("\n")
    }
    
    func insert(line: String, at offset: Int) -> Node {
        resetCache()
        
        if offset < weight {
            if let left {
                self.left = left.insert(line: line, at: offset)
                self.weight += line.utf16Length
            } else {
                fatalError("insertIntoBranch: missing left child")
            }
        } else {
            if let right {
                self.right = right.insert(line: line, at: offset - weight)
            } else {
                fatalError("insertIntoBranch: missing right child")
            }
        }
        return self.balance()
    }
}

// MARK: - Balance
extension Node {
    var height: Int {
        guard !(self is Leaf) else {
            return 1
        }
        
        if let cacheHeight {
            return cacheHeight
        }
        
        cacheHeight = max(left?.height ?? 0, right?.height ?? 0) + 1
        return cacheHeight!
    }

    /// Basic AVL balance function
    /// Called after every insertion or deletion
    /// Actually it's not basic, it's iterative, to handle large multi-leaf insertions or deletions
    func balance() -> Node {
        guard let right, let left else {
            return self
        }
        let balanceFactor = left.height - right.height
        var root: Node = self
        if balanceFactor > 1 {
            if (left.left?.height ?? 0) < (left.right?.height ?? 0) {
                root.left = left.leftRotate()
            }
            root = rightRotate()
            root.right = root.right?.balance()
        } else if balanceFactor < -1 {
            if (right.right?.height ?? 0) < (right.left?.height ?? 0) {
                root.right = right.rightRotate()
            }
            root = leftRotate()
            root.left = root.left?.balance()
        }
        if balanceFactor > 2 || balanceFactor < -2 {
            root = root.balance()
        }
        return root
    }

    //     self                  right
    //  ┌────┴────┐           ┌────┴────┐
    // left     right   ->  self        y
    //         ┌──┴──┐     ┌──┴──┐
    //         x     y    left   x
    /// left, x, y are unchanged
    private func leftRotate() -> Node {
        guard let right else { return self }
        self.right = right.left
        right.left = self
        
        right.resetCache()
        self.resetCache()
        
        right.weight += self.weight

        return right
    }
    
    //        self              left
    //     ┌────┴────┐       ┌────┴────┐
    //    left    right  ->  x        self
    //  ┌──┴──┐                     ┌──┴──┐
    //  x     y                     y    right
    /// right, x, y are unchanged
    private func rightRotate() -> Node {
        guard let left else { return self }
        self.left = left.right
        left.right = self

        left.resetCache()
        self.resetCache()
        
        self.weight -= left.weight
        
        return left
    }
}
