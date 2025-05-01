//
//  BalanceTests.swift
//  TendrilTree
//
//  Created by Gemini Pro 2.5 on 2025-05-01.
//

import Testing
@testable import TendrilTree
import Foundation // For NSRange if needed directly, though usually through TendrilTree API

@Suite final class BalanceTests {

    // Helper to create content with N lines
    private func generateContent(lines: Int, prefix: String = "Line") -> String {
        return (1...lines).map { "\(prefix) \($0)\n" }.joined()
    }

    // MARK: - Insertion Induced Balancing (Standard AVL Cases)

    @Test("Balance after Left-Left Insertion (Right Rotation)")
    func testBalanceLL() throws {
        // Setup: Create a state where inserting at the beginning triggers LL imbalance
        // Initial: B\nC\n -> Node(Leaf(B), Leaf(C)) - Height 2
        // Insert A: Node(Node(Leaf(A), Leaf(B)), Leaf(C)) -> Left Height 2, Right Height 1. Balanced.
        // Need more height. Start with C\nD\n. Insert B. Insert A.
        let tree = TendrilTree(content: "C\nD") // Height 2: Node(Leaf(C), Leaf(D))
        try tree.insert(content: "B\n", at: 0)    // Height 3: Node(Node(Leaf(B), Leaf(C)), Leaf(D)) - L:2, R:1 -> Balanced

        // Act: Insert A - this should make Root's left child (Node(B,C)) height 2, right child (D) height 1.
        // The Root's left child (B,C) has left child (A) height 1, right child (B) height 1.
        // This insertion (A) makes the path Left-Left longer.
        // It makes Node(Node(Leaf(A), Leaf(B)), Leaf(C)) height 3. The root becomes Node(LeftChildHeight3, Leaf(D)Height1) -> Imbalance!
        // Expected: Right rotation at the root.
        try tree.insert(content: "A\n", at: 0)

        // Assert
        #expect(tree.string == "A\nB\nC\nD")
        #expect(tree.root.height <= 3) // Rotation should keep height minimal
        tree.verifyInvariants() // Checks balance implicitly
    }

    @Test("Balance after Left-Right Insertion (Left-Right Rotation)")
    func testBalanceLR() throws {
        // Setup: Need a state where insertion into the left child's *right* subtree causes imbalance.
        // Start: A\nC\n -> Node(Leaf(A), Leaf(C)) Height 2
        let tree = TendrilTree(content: "A\nC\n")

        // Act: Insert B between A and C.
        // Insert B\n at utf16 offset of "A\n" (which is 2)
        // This goes to the right child (C). C.insert(B, at: 0) -> splits C into Node(Leaf(B), Leaf(C))
        // Root becomes Node(Leaf(A), Node(Leaf(B), Leaf(C))). Right height 2, Left height 1. Balanced.
        // Okay, need more height initially.
        // Start with A\nD\n. Insert C. Insert B.
        let tree2 = TendrilTree(content: "A\nD\n") // Node(Leaf(A), Leaf(D)) H=2
        try tree2.insert(content: "C\n", at: tree2.length) // Node(Leaf(A), Node(Leaf(C), Leaf(D))) R=2, L=1 H=3

        // Act: Insert B between A and C. Offset = "A\n".utf16Length = 2
        // Goes left -> Leaf(A).insert(B, at: 2) -> impossible offset.
        // Hmm, let's rethink the setup for LR.
        // We need Root.left.right path longer.
        // Start with: C\n A\n (Parsed: Node(Leaf(C), Leaf(A)))
        let tree3 = TendrilTree(content: "C\nA\n") // H=2
        // Insert B between C and A. Offset = "C\n".utf16Length
        try tree3.insert(content: "B\n", at: tree3.string.range(of: "A")!.lowerBound.utf16Offset(in: tree3.string))
        // Tree should be: Node(Leaf(C), Node(Leaf(B), Leaf(A))) - R=2, L=1. H=3 Balanced.

        // Need more height...
        // Try: E\nA\n (Node(Leaf(E), Leaf(A))) H=2
        let tree4 = TendrilTree(content: "E\nA\n")
        // Insert C between E and A. Offset = "E\n".utf16Length
         try tree4.insert(content: "C\n", at: tree4.string.range(of: "A")!.lowerBound.utf16Offset(in: tree4.string))
        // Tree: Node(Leaf(E), Node(Leaf(C), Leaf(A))) R=2, L=1. H=3 Balanced.
        // Insert B between A and C. Offset = "E\nC\n".utf16Length
        let offsetB = tree4.string.range(of: "A")!.lowerBound.utf16Offset(in: tree4.string)
        try tree4.insert(content: "B\n", at: offsetB)
        // Target node is Node(C,A). Offset relative to it is "C\n".utf16Length = 2.
        // Goes right -> Leaf(A).insert(B, at:0) -> Node(Leaf(B), Leaf(A))
        // Node(C,A) becomes Node(Leaf(C), Node(Leaf(B), Leaf(A))) H=3
        // Root becomes Node(Leaf(E), Node(Leaf(C), Node(Leaf(B), Leaf(A)))) R=3, L=1 -> Imbalance! LR case.
        // Expected: Left rotate Node(C, Node(B,A)) -> Node(Node(C,B), Leaf(A)). Then Right rotate root.

        // Assert
        #expect(tree4.string == "E\nC\nB\nA\n")
        tree4.verifyInvariants()
    }

    // Note: Right-Right (RR) and Right-Left (RL) are mirrors of LL and LR.
    // It's good practice to test them explicitly too.

    @Test("Balance after Right-Right Insertion (Left Rotation)")
    func testBalanceRR() throws {
        let tree = TendrilTree(content: "A\nB\n") // H=2
        try tree.insert(content: "C\n", at: tree.length) // H=3, Balanced Node(Leaf(A), Node(Leaf(B), Leaf(C))) L=1, R=2

        // Act: Insert D at the end. Creates RR imbalance.
        try tree.insert(content: "D\n", at: tree.length)
        // Node(Leaf(B), Leaf(C)).insert(D, at:"B\n".len) -> Node(Leaf(B), Node(Leaf(C),Leaf(D))) H=3
        // Root: Node(Leaf(A), Node(Leaf(B), Node(Leaf(C),Leaf(D)))) L=1, R=3 -> Imbalance! RR
        // Expect Left Rotation at root.

        // Assert
        #expect(tree.string == "A\nB\nC\nD\n")
        tree.verifyInvariants()
    }

    @Test("Balance after Right-Left Insertion (Right-Left Rotation)")
    func testBalanceRL() throws {
        let tree = TendrilTree(content: "A\nD\n") // H=2
        try tree.insert(content: "B\n", at: tree.string.range(of: "D")!.lowerBound.utf16Offset(in: tree.string)) // Insert B between A and D. Node(Leaf(A), Node(Leaf(B), Leaf(D))) L=1, R=2 H=3 Balanced

        // Act: Insert C between B and D. Offset = "A\nB\n".utf16Length
        let offsetC = tree.string.range(of: "D")!.lowerBound.utf16Offset(in: tree.string)
        try tree.insert(content: "C\n", at: offsetC)
        // Node(B,D).insert(C, at:"B\n".len) -> Node(Leaf(B), Node(Leaf(C), Leaf(D))) L=1, R=2 H=3
        // Root: Node(Leaf(A), Node(Leaf(B), Node(Leaf(C), Leaf(D)))) L=1, R=3 -> Imbalance! RL case.
        // Expected: Right rotate Node(B, Node(C,D)) -> Node(Node(B,C), Leaf(D)). Then Left rotate root.

        // Assert
        #expect(tree.string == "A\nB\nC\nD\n")
        tree.verifyInvariants()
    }

    // MARK: - Deletion Induced Balancing

    @Test("Balance after Deleting Leaf - Simple Case")
    func testBalanceAfterDeleteSimple() throws {
        // Setup: A tree where deleting one leaf causes simple imbalance
        // A B C D E -> Balanced H=3
        let content = generateContent(lines: 5) // A\nB\nC\nD\nE\n
        let tree = TendrilTree(content: content)
        let initialHeight = tree.root.height // Should be 3

        // Act: Delete E. This should shorten the right side.
        // Structure likely Node(Node(A,B), Node(Node(C,D), E))? Let's trace parse.
        // [A B C D E] mid=C. L=[A B] R=[C D E]
        // L: [A B] mid=A. L=[A] R=[B] -> Node(A,B) H=2
        // R: [C D E] mid=D. L=[C] R=[D E]
        // R.R: [D E] mid=D. L=[D] R=[E] -> Node(D,E) H=2
        // R: Node(C, Node(D,E)) H=3
        // Root: Node(Node(A,B), Node(C, Node(D,E))) L=2, R=3 -> H=4 (Hmm, parse might make it H=3) Let's assume H=3 balanced.

        // Act: Delete E\n. Offset = "A\nB\nC\nD\n".utf16Length
        let lineLen = "Line 1\n".utf16Length
        try tree.delete(range: NSRange(location: 4 * lineLen, length: lineLen)) // Delete "Line 5\n"

        // Assert: Should rebalance, likely via rotation(s). Height might stay 3 or drop to 2.
        #expect(tree.string == generateContent(lines: 4))
        #expect(tree.root.height <= initialHeight) // Height should not increase
        tree.verifyInvariants() // Checks balance
    }

    @Test("Balance after Deleting Multiple Leaves (Large Imbalance)")
    func testBalanceAfterDeleteLarge() throws {
        // Setup: Create a reasonably large tree
        let totalLines = 30
        let deleteLines = 20
        let keepLines = totalLines - deleteLines
        let content = generateContent(lines: totalLines)
        let tree = TendrilTree(content: content)
        let initialHeight = tree.root.height

        // Act: Delete a large chunk from the beginning, causing significant imbalance
        let deletionLength = generateContent(lines: deleteLines).utf16.count
        try tree.delete(range: NSRange(location: 0, length: deletionLength))

        // Assert: The tree must rebalance correctly.
        let expectedContent = generateContent(lines: keepLines, prefix: "Line\(deleteLines + 1)") // Lines 21-30 remain
        let expectedContentManual = (deleteLines + 1...totalLines).map { "Line \($0)\n" }.joined()
        #expect(tree.string == expectedContentManual)
        #expect(tree.root.height < initialHeight) // Height should significantly decrease
        tree.verifyInvariants()
    }

    @Test("Balance after Deleting from Right Side")
    func testBalanceAfterDeleteRight() throws {
        let totalLines = 8
        let deleteCount = 3
        let content = generateContent(lines: totalLines)
        let tree = TendrilTree(content: content)
        let initialHeight = tree.root.height

        let lineLen = "Line 1\n".utf16Length
        let startOffset = (totalLines - deleteCount) * lineLen
        let deletionLength = deleteCount * lineLen

        // Act: Delete last 3 lines
        try tree.delete(range: NSRange(location: startOffset, length: deletionLength))

        // Assert
        let expectedContent = generateContent(lines: totalLines - deleteCount)
        #expect(tree.string == expectedContent)
        #expect(tree.root.height <= initialHeight)
        tree.verifyInvariants()
    }

    // MARK: - Join Induced Balancing

    @Test("Balance after Joining Trees of Very Different Heights")
    func testBalanceJoinDifferentHeights() throws {
        // Setup: Create two trees, one tall, one short
        // Use generateContent which creates the internal representation directly
        let tallContent = generateContent(lines: 20)
        let shortContent = generateContent(lines: 1, prefix: "Short") // "Short 1\n"

        // Parse directly into Nodes using the internal representation
        guard let (tallNode, tallLen) = Node.parse(tallContent),
              let (shortNode, shortLen) = Node.parse(shortContent) else {
            Issue.record("Failed to parse nodes for join test")
            return
        }
        #expect(tallLen == tallContent.utf16Length)
        #expect(shortLen == shortContent.utf16Length)


        let tallHeight = tallNode.height
        let shortHeight = shortNode.height
        #expect(tallHeight > shortHeight + 1) // Ensure significant height difference

        // Act: Join them using the static Node.join (which calls balance internally)
        guard let joinedNode = Node.join(tallNode, shortNode) else {
            Issue.record("Join resulted in nil node")
            return
        }

        // Assert: The resulting node should be balanced and its internal string correct
        let expectedInternalString = tallContent + shortContent
        #expect(joinedNode.string == expectedInternalString) // Compare internal strings
        #expect(joinedNode.height <= tallHeight + 1)

        // Verify invariants on the joined node directly
        joinedNode.verifyInvariants()
    }

    @Test("Balance after Joining Short then Tall")
    func testBalanceJoinShortTall() throws {
        // Setup: Use internal representations
        let tallContent = generateContent(lines: 20, prefix: "Tall")
        let shortContent = generateContent(lines: 1, prefix: "Short")

        guard let (tallNode, _) = Node.parse(tallContent),
              let (shortNode, _) = Node.parse(shortContent) else {
            Issue.record("Failed to parse nodes for join test")
            return
        }

        let tallHeight = tallNode.height
        let shortHeight = shortNode.height
        #expect(tallHeight > shortHeight + 1)

        // Act: Join short then tall
        guard let joinedNode = Node.join(shortNode, tallNode) else {
            Issue.record("Join resulted in nil node")
            return
        }

        // Assert: Compare internal strings
        let expectedInternalString = shortContent + tallContent
        #expect(joinedNode.string == expectedInternalString)
        #expect(joinedNode.height <= tallHeight + 1)
        joinedNode.verifyInvariants()
    }

    @Test("Balance after Joining Two Tall Trees")
    func testBalanceJoinTallTall() throws {
        // Setup: Use internal representations
        let content1 = generateContent(lines: 15, prefix: "Tree1")
        let content2 = generateContent(lines: 18, prefix: "Tree2")

        guard let (node1, _) = Node.parse(content1),
              let (node2, _) = Node.parse(content2) else {
             Issue.record("Failed to parse nodes for join test")
            return
        }

        let h1 = node1.height
        let h2 = node2.height

        // Act
        guard let joinedNode = Node.join(node1, node2) else {
             Issue.record("Join resulted in nil node")
            return
        }

        // Assert: Compare internal strings
        let expectedInternalString = content1 + content2
        #expect(joinedNode.string == expectedInternalString)
        #expect(joinedNode.height <= max(h1, h2) + 1) // Join might increase height by 1
        joinedNode.verifyInvariants()
    }

    // MARK: - Split Interaction (via Join)

    @Test("Balance after Split and Join")
    func testBalanceSplitJoin() throws {
        // Setup: Create a tree
        let totalLines = 50
        let content = generateContent(lines: totalLines) // Internal representation
        let tree = TendrilTree(content: String(content.dropLast())) // User string init
        let originalHeight = tree.root.height
        #expect(tree.root.string == content) // Verify internal string

        // Calculate a *valid* split offset based on line boundaries.
        // Split after the first third of the lines.
        let linesToSplitAfter = totalLines / 3
        guard linesToSplitAfter > 0 else {
             Issue.record("Not enough lines to perform a meaningful split test")
             return
        }
        // Calculate the UTF-16 length of the first `linesToSplitAfter` lines (internal representation)
        let splitOffset = generateContent(lines: linesToSplitAfter).utf16Length
        #expect(splitOffset > 0)
        #expect(splitOffset < content.utf16Length) // Ensure it's not splitting at start/end

        // Act: Split the root node directly (using the valid offset)
        let (leftPart, rightPart) = tree.root.split(at: splitOffset)

        // Ensure split parts are non-nil for a valid mid-split
        guard let left = leftPart, let right = rightPart else {
            Issue.record("Split resulted in one or both parts being nil unexpectedly")
            return
        }

        // Act: Join the parts back together
        guard let rejoinedNode = Node.join(left, right) else {
            Issue.record("Rejoin resulted in nil node")
            return
        }

        // Assert: The rejoined node should match the original internal content and be balanced
        #expect(rejoinedNode.string == content) // Compare internal strings
        // Height might be slightly different due to rebalancing, but should be optimal
        #expect(rejoinedNode.height <= originalHeight + 1) // Allow for minor height diff from optimal rebalance
        rejoinedNode.verifyInvariants() // Verify invariants directly on the node
    }
}
