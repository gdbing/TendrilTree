//
//  Serialization.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-02.
//
//  - `fileString` is `string` with intact '\t' indentation, to be written to a file
//  - The `parse` static method efficiently builds a balanced tree from an ordered
//    collection of paragraph strings (assumed to end in '\n').
//  - `fileString` should return the exact same string as is `parse`d to create a tree
//

extension TendrilTree {
    public var fileString: String {
        return String(root.fileString.dropLast())
    }
    public var fileLength: Int { fileString.utf16.count }
    
    public func depth(at offset: Int) throws -> Int {
        guard offset >= 0 && offset <= length else {
            throw TendrilTreeError.invalidQueryOffset
        }
        // find the leaf and return its indentation
        guard let leafNode = root.nodeAt(offset: offset),
              let leaf = leafNode as? Leaf else {
            throw TendrilTreeError.invalidQueryOffset
        }
        return leaf.indentation
    }
}

extension Node {
    var fileString: String {
        if let leaf = self as? Leaf {
            return String(repeating:"\t", count:leaf.indentation) + leaf.string
        } else {
            return left!.fileString + right!.fileString
        }
    }
}

// MARK: - Parse

extension Node {
    static func parse(_ content: any StringProtocol) -> (node: Node, length: Int)? {
        assert(content.last == "\n")
        if let (root, length) = Node.parse(paragraphs: (content).splitIntoLines()) {
            return (root, length)
        }
        return nil
    }
    
    /// Since paragraphs are already ordered we can insert them "middle out", without doing any balancing
    static func parse<C: Collection>(paragraphs: C) -> (node: Node, length: Int)? where C.Element == String {
        guard !paragraphs.isEmpty else { return nil }

        if paragraphs.count == 1 {
            let content = paragraphs.first!
            let leaf = Leaf(content)
            return (leaf, leaf.weight)
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


