//
//  NodeTests.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-04-30.
//

import Testing
@testable import TendrilTree

@Suite final class NodeTests {
    // MARK: - Basic Node Construction

    @Test("Empty Node Construction")
    func testEmptyNodeConstruction() {
        let node = Node()
        #expect(node.weight == 0)
        #expect(node.left == nil)
        #expect(node.right == nil)
        #expect(node.height == 1)
        #expect(node.string.isEmpty)
    }

    @Test("Empty Leaf Construction")
    func testEmptyLeafConstruction() {
        let leaf = Leaf("\n")
        #expect(leaf.weight == 1)
        #expect(leaf.left == nil)
        #expect(leaf.right == nil)
        #expect(leaf.height == 1)
        #expect(leaf.content == "\n")
        leaf.verifyInvariants()
    }

    @Test("Single Line Leaf Construction")
    func testSingleLineLeafConstruction() {
        let content = "Hello, World!\n"
        let leaf = Leaf(content)
        #expect(leaf.weight == content.utf16Length)
        #expect(leaf.content == content)
        #expect(leaf.isLeaf)
        leaf.verifyInvariants()
    }

    // MARK: - Tree Structure

    @Test("Basic Tree Structure")
    func testBasicTreeStructure() {
        let leftLeaf = Leaf("First line\n")
        let rightLeaf = Leaf("Second line\n")

        let parent = Node()
        parent.left = leftLeaf
        parent.right = rightLeaf
        parent.weight = leftLeaf.weight

        #expect(!parent.isLeaf)
        #expect(parent.left?.isLeaf == true)
        #expect(parent.right?.isLeaf == true)
        #expect(parent.weight == leftLeaf.weight)
        #expect(parent.height == 2)
        parent.verifyInvariants()
    }

    @Test("Tree Structure After Parse")
    func testTreeStructureAfterParse() {
        let content = """
        First line
        Second line
        Third line
        Fourth line
        
        """

        let (root, length) = Node.parse(content)!
        #expect(length == content.utf16Length)
        #expect(!root.isLeaf)
        #expect(root.string == content)
        root.verifyInvariants()
    }

    // MARK: - Weight Calculations

    @Test("Weight Calculations")
    func testWeightCalculations() {
        let leftContent = "Left\n"
        let rightContent = "Right\n"
        let left = Leaf(leftContent)
        let right = Leaf(rightContent)

        let parent = Node()
        parent.left = left
        parent.right = right
        parent.weight = leftContent.utf16Length

        #expect(parent.weight == leftContent.utf16Length)
        #expect(parent.string.utf16Length == leftContent.utf16Length + rightContent.utf16Length)
        parent.verifyInvariants()
    }

    @Test("Weight Updates After Insertion")
    func testWeightUpdatesAfterInsertion() {
        var node = Node.parse("Initial\n")!.node
        #expect(node.weight == "Initial\n".utf16.count)
        
        node = node.insert(content: "Middle\n", at: 0)
        #expect(node.weight == "Middle\n".utf16.count)
        node.verifyInvariants()
    }

    // MARK: - Height Calculations

    @Test("Height Calculations")
    func testHeightCalculations() {
        // Create a tree with 3 levels
        let leaf1 = Leaf("1\n")
        let leaf2 = Leaf("2\n")
        let leaf3 = Leaf("3\n")
        let leaf4 = Leaf("4\n")

        let intermediate1 = Node()
        intermediate1.left = leaf1
        intermediate1.right = leaf2
        intermediate1.weight = leaf1.weight

        let intermediate2 = Node()
        intermediate2.left = leaf3
        intermediate2.right = leaf4
        intermediate2.weight = leaf3.weight

        let root = Node()
        root.left = intermediate1
        root.right = intermediate2
        root.weight = intermediate1.weight + intermediate1.right!.weight

        #expect(leaf1.height == 1)
        #expect(intermediate1.height == 2)
        #expect(root.height == 3)
        root.verifyInvariants()
    }

    // MARK: - Cache Behavior

    @Test("Cache Invalidation")
    func testCacheInvalidation() {
        let node = Node.parse("Cache\ntest\n")!.node

        // Access string to populate cache
        let _ = node.string
        #expect(node.cacheString != nil)

        // Modify tree
        let _ = node.insert(content: "New content\n", at: 0)
        #expect(node.cacheString == nil)
    }

    @Test("Height Cache")
    func testHeightCache() {
        let node = Node.parse("Height\ncache\ntest\n")!.node

        // Access height to populate cache
        let initialHeight = node.height
        #expect(node.cacheHeight == initialHeight)

        // Modify tree
        node.resetCache()
        #expect(node.cacheHeight == nil)
    }

    // MARK: - Invalid States

//    @Test("Invalid Leaf Content")
//    func testInvalidLeafContent() {
//        // Leaf without newline should fail verification
//        let leaf = Leaf("Invalid content")
//        #expect(throws: "content contains newlines") {
//            leaf.verifyLeafInvariants()
//        }
//
//        // Leaf with internal newlines should fail verification
//        let leafWithNewlines = Leaf("First\nSecond\n")
//        #expect(throws: "content contains newlines") {
//            leafWithNewlines.verifyLeafInvariants()
//        }
//    }
//
//    @Test("Invalid Branch Structure")
//    func testInvalidBranchStructure() {
//        let node = Node()
//        node.left = Leaf("Left\n")
//        // Missing right child should fail verification
//        #expect(throws: "right branch missing") {
//            node.verifyInvariants()
//        }
//    }

    // MARK: - Balance Verification

    @Test("Balance Factors")
    func testBalanceFactors() {
        let content = """
        Line 1
        Line 2
        Line 3
        Line 4
        Line 5
        Line 6
        Line 7
        
        """

        let node = Node.parse(content)!.node
        verifyBalanceFactors(node)
        node.verifyInvariants()
    }

    private func verifyBalanceFactors(_ node: Node) {
        guard !node.isLeaf else { return }

        let leftHeight = node.left?.height ?? 0
        let rightHeight = node.right?.height ?? 0
        let balanceFactor = leftHeight - rightHeight

        #expect(balanceFactor >= -1 && balanceFactor <= 1)

        if let left = node.left {
            verifyBalanceFactors(left)
        }
        if let right = node.right {
            verifyBalanceFactors(right)
        }
    }
}
