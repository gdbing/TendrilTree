//
//  FoldOperationTests.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-10.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final class FoldOperationTests {
    @Test func testEnumerate() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        var result = ""
        tree.root.enumerateLeaves() { leaf in
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect(content + "\n" == result)
        
        result = ""
        tree.root.enumerateLeaves(from: 5, to: "abcd\nefg\nhijk\nlmnop\nqrs\ntuv".count) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: 5) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            if leaf.content.contains("s") {
                return false
            } else {
                return true
            }
        }
        #expect("\tefg\n\t\thijk\n\tlmnop\nqrs\n" == result)
    }
    
    @Test func testEnumerateBackward() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        var result = ""
        tree.root.enumerateLeaves(direction: .backward) { leaf in
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("wxyz\ntuv\nqrs\n\tlmnop\n\t\thijk\n\tefg\nabcd\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: "abcd\nefg\nhijk\nlmnop\nqrs\nt".count, to: "abcd\nef".count) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("tuv\nqrs\n\tlmnop\n\t\thijk\n\tefg\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: "abcd\nefg\nhijk\nlmnop\nqrs\nt".count, direction: .backward) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            if leaf.content.contains("j") {
                return false
            } else {
                return true
            }
        }
        #expect("tuv\nqrs\n\tlmnop\n\t\thijk\n" == result)
    }

    @Test func testEnumerateOffset() throws {
        var offsets: [Int] = []
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        tree.root.enumerateLeaves { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [0,5,9,14,20,24,28])

        offsets = []
        tree.root.enumerateLeaves(direction: .backward) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [0,5,9,14,20,24,28].reversed())

        offsets = []
        tree.root.enumerateLeaves(from: 7) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [5,9,14,20,24,28])

        offsets = []
        tree.root.enumerateLeaves(from: 21, to: 8, direction: .backward) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [20, 14, 9, 5])
        
        offsets = []
    }
    
    @Test func testNextNode() throws {
        let content = "abcd\nefg\nhijk\nlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        #expect(tree.root.nextNode(from: 0)?.content == "efg\n")
        #expect(tree.root.nextNode(from: 5)?.content == "hijk\n")
        #expect(tree.root.nextNode(from: content.count)?.content == nil)
        #expect(tree.root.nextNode(from: content.count - 1)?.content == nil)
        #expect(tree.root.nextNode(from: content.count - 5)?.content == "wxyz\n")
    }
    
    @Test func testParentOfLeaf() throws {
        let content = "abcd\nefg\n"
                    + "\t" + "hijk\n"
                    + "\t\t" + "lmnop\n"
                    + "\t" + "qrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        #expect(tree.root.parentOfLeaf(at: 0)?.leaf.content == nil)
        #expect(tree.root.parentOfLeaf(at: "abcd\n".count)?.leaf.content == nil)
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\n".count)?.leaf.content == "efg\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\n".count)?.leaf.content == "hijk\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\nlmnop\n".count)?.leaf.content == "efg\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\nlmnop\nqrs\n".count)?.leaf.content == nil)
    }
    
    @Test func testChildrenOfLeaf() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        #expect(tree.root.childrenOfLeaf(at: 0)?.map { $0.content } == ["efg\n", "hijk\n", "lmnop\n"])
        #expect(tree.root.childrenOfLeaf(at: "abcd\n".count)?.map { $0.content } == ["hijk\n"])
        #expect(tree.root.childrenOfLeaf(at: "abcd\nefg\n".count)?.map { $0.content } == [])
    }
    
    // abcd
    //     efg
    //         hijk
    //     lmnop
    // qrs
    // tuv
    // wxyz
    @Test func testCollapse() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        var tree = TendrilTree(content: content)
        #expect(tree.string == "abcd\nefg\nhijk\nlmnop\nqrs\ntuv\nwxyz")
        tree.root = tree.root.collapse(range: NSRange(location: 0, length: 0))
        #expect(tree.string == "abcd\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "efg\nhijk\nlmnop\n")
        
        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\n".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\n".count)?.collapsedChildren?.string == "hijk\n")
        
        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\nef".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\nef".count)?.collapsedChildren?.string == "hijk\n")
        
        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\n".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\n".count)?.collapsedChildren?.string == "hijk\n")

        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\nhijk\nlmn".count, length: 0))
        #expect(tree.string == "abcd\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "efg\nhijk\nlmnop\n")

        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\nhijk\nlmnop\n".count, length: 0))
        #expect(tree.string == "abcd\nefg\nhijk\nlmnop\nqrs\ntuv\nwxyz")
    }
    
    @Test func testCollapseIntoCollapsed() throws {
        let content = "abcd\n\tefg"
        let tree = TendrilTree(content: content)
        tree.root = tree.root.collapseParent(at: 1)
        #expect(tree.string == "abcd")
        try tree.insert(content: "\nhijk", at: 4)
        try tree.indent(range: NSRange(location: 5, length: 0))
        #expect(tree.string == "abcd\nhijk")
        tree.root = tree.root.collapseParent(at: 1)
        #expect(tree.string == "abcd")
    }
    
    // abc
    //     defg
    // hijk
    //     lmnop
    //         qrs
    //     tuv
    //     wx
    // yz
    @Test func testCollapseMultipleParents() throws {
        let content = "abc\n\tdefg\nhijk\n\tlmnop\n\t\tqrs\n\ttuv\n\twx\nyz"
        var tree = TendrilTree(content: content)
        #expect(tree.string == "abc\ndefg\nhijk\nlmnop\nqrs\ntuv\nwx\nyz")
        tree.root = tree.root.collapse(range: NSRange(location: 0, length: content.count))
        #expect(tree.string == "abc\nhijk\nyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "defg\n")
        #expect(tree.root.leafAt(offset: 4)?.collapsedChildren?.string == "lmnop\ntuv\nwx\n")
        #expect(tree.root.leafAt(offset: 4)?.collapsedChildren?.leafAt(offset: 0)?.collapsedChildren?.string == "qrs\n")
        
        tree = TendrilTree(content: content)
        tree.root = tree.root.collapse(range: NSRange(location: "abcd\n".count, length: "defg\nhijk".count))
        #expect(tree.string == "abc\nhijk\nyz")

    }
}

extension Node {
    func collapse(range: NSRange) -> Node {
        var parentCandidates: [(leaf: Leaf, offset: Int)] = []
        
        // 1. Identify all leaves within the given range that are parents.
        //    Store their original start offsets.
        self.enumerateLeaves(from: range.location, to: range.upperBound) { leaf, offset -> Bool in
            // for each leaf
            // if it is a parent, store it as a candidate
            // if it has a parent, get and store that
            
            if let children = self.childrenOfLeaf(at: offset), !children.isEmpty {
                parentCandidates.append((leaf: leaf, offset: offset))
            } else if let parent = self.parentOfLeaf(at: offset) {
                parentCandidates.append(parent)
            }
            return true
        }
        var seenLeaves = Set<ObjectIdentifier>()
        parentCandidates = parentCandidates.filter {
            seenLeaves.insert(ObjectIdentifier($0.leaf)).inserted
        }
        parentCandidates.sort { $0.offset > $1.offset }
                    
        var currentRoot = self
        for candidate in parentCandidates {
            currentRoot = currentRoot.collapseParent(at: candidate.offset)
        }
        
        return currentRoot
    }
    
    func collapseParent(at offset: Int) -> Node {
        // Ensure we have a parent leaf and that it's not already collapsed
        guard let parent = leafAt(offset: offset),
              let children = childrenOfLeaf(at: offset) else {
            return self
        }
        
        let childrenWidth = children.reduce(into: 0) { widthAccumulator, childLeaf in
            widthAccumulator += childLeaf.weight
        }
        
        var splitPoint: Int?
        var currentOffset = offset
        var currentNode: Node? = self
        
        while let node = currentNode {
            if node is Leaf {
                splitPoint = offset + node.weight - currentOffset
                break
            } else if currentOffset < node.weight {
                currentNode = node.left
            } else {
                currentNode = node.right
                currentOffset -= node.weight
            }
        }
        guard let splitPoint else { return self }
        
        let (left, interim) = split(at: splitPoint)
        guard let interim else { return left ?? self }
        
        let (collapsedNode, right) = interim.split(at: childrenWidth)
        
        collapsedNode?.enumerateLeaves {
            $0.indentation -= parent.indentation
            return true
        }
        if let existingCollapsed = parent.collapsedChildren  {
            parent.collapsedChildren = Node.join(existingCollapsed, collapsedNode)
        } else {
            parent.collapsedChildren = collapsedNode
        }
        return Node.join(left, right) ?? self
    }
    
    func parentOfLeaf(at offset: Int) -> (leaf: Leaf, offset: Int)? {
        guard let leaf = leafAt(offset: offset), leaf.indentation > 0 else {
            return nil
        }
        let indentation = leaf.indentation
        var result: (Leaf, Int)?
        enumerateLeaves(from: offset, direction: .backward) { leaf, os in
            if leaf.indentation < indentation {
                result = (leaf, os)
                return false
            }
            return true
        }
        return result
    }
    
    func childrenOfLeaf(at offset: Int) -> [Leaf]? {
        var indentation: Int?
        var result: [Leaf] = []
        enumerateLeaves(from: offset) {
            if indentation == nil {
                indentation = $0.indentation
            } else if $0.indentation > indentation! {
                result.append($0)
            } else {
                return false
            }
            return true
        }
        return result
    }
        
    func nextNode(from offset: Int) -> Leaf? {
        var nodesCrawled = 0
        var result: Leaf?
        enumerateLeaves(from: offset) { leaf in
            nodesCrawled += 1
            if nodesCrawled == 2 {
                result = leaf
                return false
            }
            return true
        }
        return result
    }
    
    func prevNode(from offset: Int) -> Leaf? {
        var nodesCrawled = 0
        var result: Leaf?
        enumerateLeaves(from: offset, direction: .backward) { leaf in
            nodesCrawled += 1
            if nodesCrawled == 2 {
                result = leaf
                return false
            }
            return true
        }
        return result
    }

    enum TraversalDirection {
        case forward, backward
    }

    /// Traverses leaves starting at the given offset, optionally in reverse.
    /// Calls `visit` on each leaf. If `visit` returns false, traversal stops early.
    func enumerateLeaves(
        from start: Int? = nil,
        to end: Int? = nil,
        direction: TraversalDirection? = nil,
        visit: (Leaf) -> Bool
    ) {
        enumerateLeaves(from: start, to: end, direction: direction) { leaf, _ in visit(leaf) }
    }

    func enumerateLeaves(
        from start: Int? = nil,
        to end: Int? = nil,
        direction: TraversalDirection? = nil,
        visit: (Leaf, Int) -> Bool
    ) {
        let length = string.utf16.count + 1
        
        
        let direction = direction ?? ((direction == nil && start ?? 0 > end ?? Int.max) ? .backward : .forward)
        let start = start ?? (direction == .forward ? 0 : length)
        let end = end ?? (direction == .forward ? length : 0)
        
        var nodeStack = [Node]()
        var currentNode: Node? = self
        var offset = 0
        
        if direction == .forward {
            seekStart: while let node = currentNode {
                guard node as? Leaf == nil else { break seekStart }
                
                if offset + node.weight > start {
                    nodeStack.append(node)
                    currentNode = node.left
                } else {
                    offset += node.weight
                    currentNode = node.right
                }
            }
            
            visitLeaves: while let node = currentNode {
                guard offset <= end else { return }
                
                if let leaf = node as? Leaf {
                    if !visit(leaf, offset) { return }
                    offset += node.weight
                    currentNode = nodeStack.popLast()?.right
                } else {
                    nodeStack.append(node)
                    currentNode = node.left
                }
            }
        } else {
            seekStart: while let node = currentNode {
                guard node as? Leaf == nil else { break seekStart }
                
                if offset + node.weight > start {
                    currentNode = node.left
                } else {
                    nodeStack.append(node)
                    offset += node.weight
                    currentNode = node.right
                }
            }

            offset += currentNode?.weight ?? 0
            
            visitLeaves: while let node = currentNode {
                guard offset > end else { return }
                
                if let leaf = node as? Leaf {
                    offset -= node.weight
                    if !visit(leaf, offset) { return }
                    currentNode = nodeStack.popLast()?.left
                } else {
                    nodeStack.append(node)
                    currentNode = node.right
                }
            }
        }
    }
}
