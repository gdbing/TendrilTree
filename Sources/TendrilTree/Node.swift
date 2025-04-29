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
//  - **Parsing:** The `parse` static method efficiently builds a balanced tree from
//    an ordered collection of paragraph strings (assumed to end in '\n').
//

import Foundation

class Node {
    /// weight, left, and right are the bare minimum requirements of a rope node
    var weight: Int = 0
    var left: Node?
    var right: Node?

    var isLeaf: Bool {
        return self is Leaf
    }
    
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

    func nodeAt(offset: Int) -> Node? {
        return nodeWithRemainderAt(offset: offset)?.node
    }

    private func nodeWithRemainderAt(offset:Int) -> (node: Node, remainder: Int)? {
        if left == nil && offset <= weight {
            return (self, offset)
        }

        if offset < weight {
            return left?.nodeWithRemainderAt(offset: offset)
        }

        return right?.nodeWithRemainderAt(offset: offset - weight)
    }
    
    func insert(content insertion: String, at offset: Int) -> Node {
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

}

// MARK: - Parse

extension Node {
    static func parse(_ content: any StringProtocol) -> (node: Node, length: Int)? {
        if let (root, length) = Node.parse(paragraphs: (content + "\n").splitIntoLines()) {
            return (root, length - 1)
        }
        return nil
    }
    
    /// Since paragraphs are already ordered we can insert them "middle out", without doing any balancing
    private static func parse<C: Collection>(paragraphs: C) -> (node: Node, length: Int)? where C.Element == String {
        guard !paragraphs.isEmpty else { return nil }

        if paragraphs.count == 1 {
            let content = paragraphs.first!
            return (Leaf(content), content.utf16Length)
        }

        let midIdx = paragraphs.index(paragraphs.startIndex, offsetBy: paragraphs.count / 2)
        let left = parse(paragraphs: paragraphs[..<midIdx])!
        let right = parse(paragraphs: paragraphs[midIdx...])!
        let node = Node()
        node.left = left.node
        node.right = right.node
        node.weight = left.length

        return (node, left.length + right.length)
    }
}


extension Node {
    // MARK: - Balance

    var height: Int {
        guard !isLeaf else {
            return 1
        }
        
        if let cacheHeight {
            return cacheHeight
        }
        
        cacheHeight = max(left!.height, right!.height) + 1
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
