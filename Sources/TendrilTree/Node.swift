//
//  Node.swift
//

import Foundation

internal class Node {
    /// weight, left, and right are the bare minimum requirements of a rope node
    var weight: Int = 0
    var left: Node?
    var right: Node?

    var content: String?

    // MARK: - init

    init() { }
    init(_ content: String) {
        self.content = content
        self.weight = content.utf16Length
    }
    
    internal var cacheString: String?
    internal var cacheHeight: Int?
}

// MARK: - Utils

extension Node {
    var string: String {
        if let content {
            return content
        } else if cacheString == nil {
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
}

// MARK: - Parse

extension Node {
    /// Since paragraphs are already ordered we can insert them "middle out", without doing any balancing
    static func parse<C: Collection>(paragraphs: C) -> (node: Node, length: Int)? where C.Element == String {
        guard !paragraphs.isEmpty else { return nil }

        if paragraphs.count == 1 {
            let content = paragraphs.first!
            return (Node(content), content.utf16Length)
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
        if let cacheHeight {
            return cacheHeight
        }
        let leftHeight = left?.height ?? 0
        let rightHeight = right?.height ?? 0
        cacheHeight = max(leftHeight, rightHeight) + 1
        return cacheHeight!
    }

    /// Basic AVL balance function
    /// Called after every insertion or deletion
    /// Actually it's not basic, it's iterative, to handle large multi-leaf insertions or deletions
    internal func balance() -> Node {
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

    /// NB: rotate should never involve leafs, don't worry about content
    //     self                  right
    //  ┌────┴────┐           ┌────┴────┐
    // left     right   ->  self        y
    //         ┌──┴──┐     ┌──┴──┐
    //         x     y    left   x
    /// left, x, y are unchanged
    func leftRotate() -> Node {
        guard let right else { return self }
        self.right = right.left
        right.left = self
        
        right.cacheHeight = nil
        self.cacheHeight = nil
        
        right.weight += self.weight

        return right
    }
    
    //        self              left
    //     ┌────┴────┐       ┌────┴────┐
    //    left    right  ->  x        self
    //  ┌──┴──┐                     ┌──┴──┐
    //  x     y                     y    right
    /// right, x, y are unchanged
    func rightRotate() -> Node {
        guard let left else { return self }
        self.left = left.right
        left.right = self

        left.cacheHeight = nil
        self.cacheHeight = nil
        
        self.weight -= left.weight
        
        return left
    }
}
