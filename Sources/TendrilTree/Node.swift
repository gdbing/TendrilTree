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
    internal func balance() {
        let balanceFactor = (left?.height ?? 0) - (right?.height ?? 0)
        if balanceFactor > 1 {
            if let left, (left.left?.height ?? 0) < (left.right?.height ?? 0) {
                left.leftRotate()
            }
            rightRotate()
            right?.balance()
        } else if balanceFactor < -1 {
            if let right, (right.right?.height ?? 0) < (right.left?.height ?? 0) {
                right.rightRotate()
            }
            leftRotate()
            left?.balance()
        }
        if balanceFactor > 2 || balanceFactor < -2 {
            balance()
        }
    }

    /// NB: rotate should never involve leafs, don't worry about content
    private func leftRotate() {
        let newLeft = Node()
        newLeft.weight = self.weight
        newLeft.left = left
        newLeft.right = self.right!.left
        self.left = newLeft

        self.weight += self.right!.weight
        self.right = self.right!.right
    }

    private func rightRotate() {
        let newRight = Node()
        newRight.left = self.left!.right
        newRight.weight = self.weight - self.left!.weight
        newRight.right = self.right
        self.right = newRight

        self.weight = left!.weight
        self.left = left!.left
    }
}
