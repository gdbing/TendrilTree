//
//  OutlinerStage5Tests.swift
//  TendrilTree
//
//  Created by Gemini Pro 2.5 on 2025-05-05.
//

import Foundation
import Testing
@testable import TendrilTree

// Helper to create a simple dummy Node tree for collapsed content
private func createDummyNodeTree(content: String = "Collapsed Child\n") -> Node? {
    return Node.parse(content)?.node
}

// Helper to recursively collect all Leaf nodes from a Node tree.
private func collectLeaves(from node: Node?) -> [Leaf] {
    guard let node = node else { return [] }
    var result = [Leaf]()
    func traverse(_ n: Node) {
        if let leaf = n as? Leaf {
            result.append(leaf)
        } else {
            if let left = n.left { traverse(left) }
            if let right = n.right { traverse(right) }
        }
    }
    traverse(node)
    return result
}

@Suite final class OutlinerStage5Tests {

    // MARK: - Initialization Tests

    @Test("Leaf initializer with nil collapsedChildren")
    func testLeafInitNilCollapsed() {
        let leaf = Leaf("Content\n", indentation: 1, collapsedChildren: nil)
        #expect(leaf.content == "Content\n")
        #expect(leaf.indentation == 1)
        #expect(leaf.collapsedChildren == nil)
        #expect(leaf.weight == "Content\n".utf16Length)
    }

    @Test("Leaf initializer with existing collapsedChildren Node")
    func testLeafInitWithCollapsed() {
        let collapsedNode = createDummyNodeTree(content: "Hidden1\nHidden2\n")
        #expect(collapsedNode != nil)

        let leaf = Leaf("Parent\n", indentation: 0, collapsedChildren: collapsedNode)
        #expect(leaf.content == "Parent\n")
        #expect(leaf.indentation == 0)
        #expect(leaf.collapsedChildren === collapsedNode, "Leaf should hold the provided collapsed node reference") // Check identity
        #expect(leaf.weight == "Parent\n".utf16Length, "Weight should only reflect visible content")
    }

    @Test("TendrilTree initialization ignores collapsedChildren for length")
    func testTreeInitIgnoresCollapsedLength() {
        // Create a node structure manually for testing init
        let collapsedNode = createDummyNodeTree(content: "Hidden\n")! // Length 7
        let leaf1 = Leaf("Visible1\n", indentation: 0, collapsedChildren: collapsedNode) // Visible length 9
        let leaf2 = Leaf("Visible2\n", indentation: 0) // Visible length 9

        let root = Node()
        root.left = leaf1
        root.right = leaf2
        root.weight = leaf1.weight // Weight based only on visible length of left

        // Simulate creating a tree from this root (bypass normal parsing for this test)
        let tree = TendrilTree()
        tree.root = root
        tree.length = leaf1.content.utf16Length + leaf2.content.utf16Length - 1 // Explicitly set expected visible length

        #expect(tree.string == "Visible1\nVisible2", "String should only contain visible content")
        #expect(tree.length == 17, "Tree length should only count visible characters") // "Visible1\nVisible2".utf16Length = 17
        #expect(tree.root.weight == 9, "Root weight should be based on visible length of left leaf")
        tree.verifyInvariants()
    }

    // MARK: - Preservation During Insert/Split

    @Test("Insert splitting leaf: Left inherits collapsed, Right gets nil")
    func testSplitPreservesCollapsedOnLeft() throws {
        let collapsedNode = createDummyNodeTree(content: "Hidden\n")
        let tree = TendrilTree()
        let parentLeaf = Leaf("ParentContent\n", indentation: 1, collapsedChildren: collapsedNode)
        tree.root = parentLeaf // Manually set root for controlled test
        tree.length = parentLeaf.content.utf16Length - 1 // Adjust length

        #expect(tree.string == "ParentContent")
        #expect(tree.length == 13)
        #expect(tree.root is Leaf)
        #expect((tree.root as? Leaf)?.collapsedChildren === collapsedNode)

        // Insert "X\n" in the middle, causing a split
        try tree.insert(content: "X\n", at: 6) // Offset within "ParentContent\n"

        #expect(tree.string == "ParentX\nContent")
        #expect(tree.length == 15) // "ParentX\nContent".utf16Length

        // Root should now be an internal node
        #expect(!(tree.root is Leaf))

        // Verify the split leaves
        let leaves = collectLeaves(from: tree.root)
        #expect(leaves.count == 2)

        let leftLeaf = leaves[0]
        let rightLeaf = leaves[1]

        #expect(leftLeaf.content == "ParentX\n")
        #expect(leftLeaf.indentation == 1)
        #expect(leftLeaf.collapsedChildren === collapsedNode, "New left leaf should inherit collapsedChildren")

        #expect(rightLeaf.content == "Content\n")
        #expect(rightLeaf.indentation == 1)
        #expect(rightLeaf.collapsedChildren == nil, "Modified right leaf should have nil collapsedChildren")

        // Verify weights reflect visible content only
        #expect(leftLeaf.weight == "ParentX\n".utf16Length)
        #expect(rightLeaf.weight == "Content\n".utf16Length)
        #expect(tree.root.weight == leftLeaf.weight, "Root weight should be weight of left (visible) part")

        tree.verifyInvariants()
    }

    @Test("Insert without splitting preserves collapsedChildren")
    func testInsertNoSplitPreservesCollapsed() throws {
        let collapsedNode = createDummyNodeTree(content: "Hidden\n")
        let tree = TendrilTree()
        let parentLeaf = Leaf("Parent\n", indentation: 1, collapsedChildren: collapsedNode)
        tree.root = parentLeaf
        tree.length = parentLeaf.content.utf16Length - 1

        // Insert "More" without a newline, should not split
        try tree.insert(content: "More", at: 6) // Insert after "Parent"

        #expect(tree.string == "ParentMore")
        #expect(tree.length == 10)

        // Should still be a single leaf
        #expect(tree.root is Leaf)
        let leaf = tree.root as! Leaf
        #expect(leaf.content == "ParentMore\n")
        #expect(leaf.indentation == 1)
        #expect(leaf.collapsedChildren === collapsedNode, "Leaf should retain collapsedChildren after non-splitting insert")
        #expect(leaf.weight == 11) // "ParentMore\n".utf16Length

        tree.verifyInvariants()
    }


    // MARK: - Preservation During Delete/Merge

    @Test("Delete merging leaves: Target leaf keeps its collapsedChildren (Case 1: Target has children)")
    func testDeleteMergePreservesTargetCollapsed_TargetHas() throws {
        let collapsedNode = createDummyNodeTree(content: "TargetHidden\n")
        let leaf1 = Leaf("Target\n", indentation: 0, collapsedChildren: collapsedNode)
        let leaf2 = Leaf("Source\n", indentation: 1, collapsedChildren: nil) // Source has different indent and no children

        let tree = TendrilTree()
        tree.root = Node.join(leaf1, leaf2)! // Manual join
        tree.length = (leaf1.content + leaf2.content).utf16Length - 1

        #expect(tree.string == "Target\nSource")
        #expect(tree.length == 13)

        // Delete the newline separating them (at offset 6)
        try tree.delete(range: NSRange(location: 6, length: 1))

        #expect(tree.string == "TargetSource")
        #expect(tree.length == 12)

        // Should merge into one leaf
        #expect(tree.root is Leaf)
        let mergedLeaf = tree.root as! Leaf
        #expect(mergedLeaf.content == "TargetSource\n")
        #expect(mergedLeaf.collapsedChildren == nil, "Merged leaf should retain source's collapsedChildren (nil) discarding target's")

        tree.verifyInvariants()
    }

    @Test("Delete merging leaves: Target leaf keeps its collapsedChildren (Case 2: Source has children)")
    func testDeleteMergePreservesTargetCollapsed_SourceHas() throws {
        let collapsedNode = createDummyNodeTree(content: "SourceHidden\n")
        let leaf1 = Leaf("Target\n", indentation: 0, collapsedChildren: nil) // Target has no children
        let leaf2 = Leaf("Source\n", indentation: 1, collapsedChildren: collapsedNode) // Source has children

        let tree = TendrilTree()
        tree.root = Node.join(leaf1, leaf2)!
        tree.length = (leaf1.content + leaf2.content).utf16Length - 1

        #expect(tree.string == "Target\nSource")

        // Delete the newline separating them (at offset 6)
        try tree.delete(range: NSRange(location: 6, length: 1))

        #expect(tree.string == "TargetSource")

        // Should merge into one leaf
        #expect(tree.root is Leaf)
        let mergedLeaf = tree.root as! Leaf
        #expect(mergedLeaf.content == "TargetSource\n")
        #expect(mergedLeaf.indentation == 0) // Indentation from target
        #expect(mergedLeaf.collapsedChildren === collapsedNode, "Merged leaf should retain collapsedChildren from the source leaf")

        tree.verifyInvariants()
    }

    @Test("Delete merging leaves: Target leaf keeps its collapsedChildren (Case 3: Both have children)")
    func testDeleteMergePreservesTargetCollapsed_BothHave() throws {
        let collapsedNode1 = createDummyNodeTree(content: "TargetHidden\n")
        let collapsedNode2 = createDummyNodeTree(content: "SourceHidden\n")
        let leaf1 = Leaf("Target\n", indentation: 0, collapsedChildren: collapsedNode1)
        let leaf2 = Leaf("Source\n", indentation: 1, collapsedChildren: collapsedNode2)

        let tree = TendrilTree()
        tree.root = Node.join(leaf1, leaf2)!
        tree.length = (leaf1.content + leaf2.content).utf16Length - 1

        #expect(tree.string == "Target\nSource")

        // Delete the newline separating them (at offset 6)
        try tree.delete(range: NSRange(location: 6, length: 1))

        #expect(tree.string == "TargetSource")

        // Should merge into one leaf
        #expect(tree.root is Leaf)
        let mergedLeaf = tree.root as! Leaf
        #expect(mergedLeaf.content == "TargetSource\n")
        #expect(mergedLeaf.indentation == 0) // Indentation from target
        #expect(mergedLeaf.collapsedChildren === collapsedNode2, "Merged leaf should retain source's collapsedChildren, discarding target's")

        tree.verifyInvariants()
    }


    // MARK: - Deleting Final Newline Tests

    @Test("Deleting final newline clears collapsedChildren")
    func testDeleteFinalNewlineClearsCollapsed() throws {
        let collapsedNode = createDummyNodeTree(content: "Hidden\n")!
        let tree = TendrilTree()
        let leaf = Leaf("Parent\n", indentation: 0, collapsedChildren: collapsedNode)
        tree.root = leaf
        tree.length = leaf.content.utf16Length - 1

        #expect(tree.string == "Parent")
        #expect(tree.length == 6)
        #expect((tree.root as? Leaf)?.collapsedChildren != nil)
        
        tree.root = Node.join(leaf, Leaf("abcd\n"))!
        tree.length = tree.string.utf16Length
        #expect(tree.string == "Parent\nabcd")
        #expect(tree.length == 11)

        // Delete the final '\n' (at offset 6)
        try tree.delete(range: NSRange(location: 6, length: 1))

        #expect(tree.string == "Parentabcd") // Visible string unchanged
        #expect(tree.length == 10)        // Length unchanged (trailing newline isn't counted)

        // Root should still be the same leaf instance, but modified
        #expect(tree.root === leaf, "Root should be the same leaf instance")
        #expect(leaf.content == "Parentabcd\n", "Internal content should still end in newline after deleting user-visible newline")
        #expect(leaf.collapsedChildren == nil, "collapsedChildren should become nil when final newline is deleted")
        #expect(leaf.weight == "Parentabcd\n".utf16Length, "Weight should reflect visible content") // Weight remains based on "Parent\n"

        tree.verifyInvariants()
    }

    // MARK: - String and Length Tests (Ignoring Collapsed)

    @Test("Node.string ignores collapsedChildren")
    func testNodeStringIgnoresCollapsed() {
        let collapsedNode = createDummyNodeTree(content: "Hidden1\nHidden2\n")!
        let leaf1 = Leaf("Visible1\n", indentation: 0, collapsedChildren: collapsedNode)
        let leaf2 = Leaf("Visible2\n", indentation: 0)

        let root = Node.join(leaf1, leaf2)!

        // Directly check the node's string property
        #expect(root.string == "Visible1\nVisible2\n", "Node's internal string should not include collapsed content")
    }

    @Test("TendrilTree.string ignores collapsedChildren")
    func testTreeStringIgnoresCollapsed() {
        let collapsedNode = createDummyNodeTree(content: "Hidden1\nHidden2\n")!
        let leaf1 = Leaf("Visible1\n", indentation: 0, collapsedChildren: collapsedNode)
        let leaf2 = Leaf("Visible2\n", indentation: 0)

        let tree = TendrilTree()
        tree.root = Node.join(leaf1, leaf2)!
        tree.length = (leaf1.content + leaf2.content).utf16Length - 1

        #expect(tree.string == "Visible1\nVisible2", "Tree's string property should not include collapsed content")
    }

    @Test("TendrilTree.length ignores collapsedChildren")
    func testTreeLengthIgnoresCollapsed() {
        let collapsedNode = createDummyNodeTree(content: "VeryLongHiddenContentThatWouldChangeLength\n")!
        let leaf1 = Leaf("Visible1\n", indentation: 0, collapsedChildren: collapsedNode)
        let leaf2 = Leaf("Visible2\n", indentation: 0)

        let tree = TendrilTree()
        tree.root = Node.join(leaf1, leaf2)!
        let expectedVisibleLength = (leaf1.content + leaf2.content).utf16Length - 1 // -1 for trailing newline
        tree.length = expectedVisibleLength // Manually set expected length

        #expect(tree.length == 17, "Tree length should only count visible characters (Visible1\\nVisible2)")
        #expect(tree.length != (leaf1.content + leaf2.content + collapsedNode.string).utf16Length - 1, "Tree length should not include collapsed content")
        tree.verifyInvariants()
    }

    @Test("Node.weight ignores collapsedChildren")
    func testNodeWeightIgnoresCollapsed() {
         let collapsedNode = createDummyNodeTree(content: "HiddenContent\n")! // Length 14
         let leaf1 = Leaf("VisibleLeft\n", indentation: 0, collapsedChildren: collapsedNode) // Visible Length 12
         let leaf2 = Leaf("VisibleRight\n", indentation: 0) // Visible Length 13

         let root = Node.join(leaf1, leaf2)!

         // Root's weight should be the weight of its left child (leaf1), which only counts visible content
         let expectedWeight = leaf1.content.utf16Length
         #expect(root.weight == expectedWeight, "Root weight should ignore collapsed children in left subtree")
         #expect(root.weight == 12)
         let tree = TendrilTree(); tree.root = root; tree.length = (leaf1.content + leaf2.content).utf16Length - 1
         tree.verifyInvariants()
    }
}
