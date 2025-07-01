//
//  OutlinerStage7ExpandTests.swift
//  TendrilTree
//
//  Created by Gemini Pro 2.5 on 2025-06-28.
//

import Foundation
import Testing

@testable import TendrilTree

// Helper to find a Leaf node by its content prefix in the visible tree
private func findLeaf(in tree: TendrilTree, contentPrefix: String) -> Leaf? {
    var targetLeaf: Leaf?

    func R(_ node: Node?) {
        guard let Rnode = node else { return }
        if targetLeaf != nil { return }  // Found, stop searching

        if let leaf = Rnode as? Leaf {
            if leaf.content.hasPrefix(contentPrefix) {
                targetLeaf = leaf
            }
        } else {
            if let left = Rnode.left { R(left) }
            if targetLeaf != nil { return }
            if let right = Rnode.right { R(right) }
        }
    }
    R(tree.root)
    return targetLeaf
}

@Suite final class OutlinerStage7ExpandTests {

    // MARK: - I. Basic Expand Scenarios

    @Test("testExpand_RangeInsideCollapsedParent_Simple")
    func testExpand_RangeInsideCollapsedParent_Simple() throws {
        let fileContent = "A\n\tB\n\tC\nD"
        let tree = TendrilTree(content: fileContent)

        // 1. Collapse the parent "A"
        try tree.collapse(range: NSRange(location: 0, length: 1))
        #expect(tree.string == "A\nD")
        let leafA_collapsed = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA_collapsed?.collapsedChildren != nil)

        // 2. Expand "A"
        try tree.expand(range: NSRange(location: 0, length: 1))

        #expect(tree.string == "A\nB\nC\nD")
        #expect(tree.fileString == fileContent.trimmingCharacters(in: .newlines))

        let leafA_expanded = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA_expanded?.collapsedChildren == nil)

        tree.verifyInvariants()
    }

    @Test("testExpand_RangeInsideCollapsedParent_Nested")
    func testExpand_RangeInsideCollapsedParent_Nested() throws {
        let fileContent = "A\n\tB\n\t\tC\n\tD\nE"
        let tree = TendrilTree(content: fileContent)

        // 1. Collapse "A"
        try tree.collapse(range: NSRange(location: 0, length: 1))
        #expect(tree.string == "A\nE")

        // 2. Expand "A"
        try tree.expand(range: NSRange(location: 0, length: 1))

        #expect(tree.string == "A\nB\nC\nD\nE")
        #expect(tree.fileString == fileContent.trimmingCharacters(in: .newlines))

        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren == nil)

        tree.verifyInvariants()
    }

    @Test("testExpand_CursorAtStartOfCollapsedParent")
    func testExpand_CursorAtStartOfCollapsedParent() throws {
        let fileContent = "A\n\tB\nC"
        let tree = TendrilTree(content: fileContent)

        try tree.collapse(range: NSRange(location: 0, length: 1))
        #expect(tree.string == "A\nC")

        try tree.expand(range: NSRange(location: 0, length: 0))  // Cursor at start of "A"

        #expect(tree.string == "A\nB\nC")
        tree.verifyInvariants()
    }

    @Test("testExpand_RangeExactlySpansCollapsedParent")
    func testExpand_RangeExactlySpansCollapsedParent() throws {
        let fileContent = "Parent\n\tChild\nSibling"
        let tree = TendrilTree(content: fileContent)

        let parentRange = tree.string.nsRange(of: "Parent\n")!
        try tree.collapse(range: parentRange)
        #expect(tree.string == "Parent\nSibling")

        let collapsedParentRange = tree.string.nsRange(of: "Parent\n")!
        try tree.expand(range: collapsedParentRange)

        #expect(tree.string == "Parent\nChild\nSibling")
        tree.verifyInvariants()
    }

    // MARK: - II. Multi-Parent / Complex Range Scenarios

    @Test("testExpand_RangeSpansMultipleCollapsedParents")
    func testExpand_RangeSpansMultipleCollapsedParents() throws {
        let fileContent = "P1\n\tC1\nP2\n\tC2\nE"
        let tree = TendrilTree(content: fileContent)

        // Collapse P1 and P2
        try tree.collapse(range: tree.string.nsRange(of: "P1")!)
        try tree.collapse(range: tree.string.nsRange(of: "P2")!)
        #expect(tree.string == "P1\nP2\nE")

        // Expand both in one go
        let expandRange = NSRange(location: 0, length: tree.string.utf16Length)
        try tree.expand(range: expandRange)

        #expect(tree.string == "P1\nC1\nP2\nC2\nE")
        let leafP1 = findLeaf(in: tree, contentPrefix: "P1\n")
        let leafP2 = findLeaf(in: tree, contentPrefix: "P2\n")
        #expect(leafP1?.collapsedChildren == nil)
        #expect(leafP2?.collapsedChildren == nil)
        tree.verifyInvariants()
    }

    @Test("testExpand_RangeIncludesCollapsedAndNotCollapsedNodes")
    func testExpand_RangeIncludesCollapsedAndNotCollapsedNodes() throws {
        let fileContent = "P1\n\tC1\nP2\n\tC2\nP3"  // P3 is not a parent
        let tree = TendrilTree(content: fileContent)

        // Collapse only P1
        try tree.collapse(range: tree.string.nsRange(of: "P1")!)
        #expect(tree.string == "P1\nP2\nC2\nP3")

        // Range spans P1 (collapsed), P2 (not collapsed), and P3
        let expandRange = NSRange(location: 0, length: tree.string.utf16Length)
        try tree.expand(range: expandRange)

        // Only P1 should have expanded
        #expect(tree.string == "P1\nC1\nP2\nC2\nP3")
        tree.verifyInvariants()
    }

    // MARK: - III. No-Op / Error Scenarios

    @Test("testExpand_TargetNotCollapsed_IsNoOp")
    func testExpand_TargetNotCollapsed_IsNoOp() throws {
        let fileContent = "A\n\tB\nC"
        let tree = TendrilTree(content: fileContent)
        let originalString = tree.string
        let originalFileString = tree.fileString

        // Attempt to expand "A", which is not collapsed
        try tree.expand(range: NSRange(location: 0, length: 1))

        #expect(tree.string == originalString)
        #expect(tree.fileString == originalFileString)
        tree.verifyInvariants()
    }

    @Test("testExpand_TargetHasNoChildren_IsNoOp")
    func testExpand_TargetHasNoChildren_IsNoOp() throws {
        let fileContent = "A\nB\nC"
        let tree = TendrilTree(content: fileContent)
        let originalString = tree.string

        // Attempt to expand "B", which has no children and thus can't be collapsed/expanded
        let locB = tree.string.nsRange(of: "B\n")!
        try tree.expand(range: locB)

        #expect(tree.string == originalString)
        tree.verifyInvariants()
    }

    @Test("testExpand_InvalidRange_OutOfBounds")
    func testExpand_InvalidRange_OutOfBounds() throws {
        let tree = TendrilTree(content: "A\n\tB")
        try tree.collapse(range: NSRange(location: 0, length: 1))
        let originalString = tree.string

        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.expand(range: NSRange(location: 100, length: 1))
        }
        #expect(tree.string == originalString)
        tree.verifyInvariants()
    }

    @Test("testExpand_EmptyTree")
    func testExpand_EmptyTree() throws {
        let tree = TendrilTree()
        // No error should be thrown, it's just a no-op
        try tree.expand(range: NSRange(location: 0, length: 0))
        #expect(tree.string.isEmpty)
        tree.verifyInvariants()
    }

    // MARK: - IV. State Verification

    @Test("testExpand_StateAfterExpand_IsInvariantsMaintained")
    func testExpand_StateAfterExpand_IsInvariantsMaintained() throws {
        let fileContent = "Parent\n\tChild 1\n\t\tGrandchild\n\tChild 2\nSibling"
        let tree = TendrilTree(content: fileContent)

        // Collapse Parent
        try tree.collapse(range: tree.string.nsRange(of: "Parent")!)
        #expect(tree.string == "Parent\nSibling")

        // Expand Parent
        try tree.expand(range: tree.string.nsRange(of: "Parent")!)

        #expect(tree.string == "Parent\nChild 1\nGrandchild\nChild 2\nSibling")
        #expect(tree.fileString == fileContent.trimmingCharacters(in: .newlines))
        #expect(tree.length == tree.string.utf16Length)

        let parentLeaf = findLeaf(in: tree, contentPrefix: "Parent\n")
        #expect(parentLeaf?.collapsedChildren == nil)

        // Verify structure
        let child1Leaf = findLeaf(in: tree, contentPrefix: "Child 1\n")
        let grandchildLeaf = findLeaf(in: tree, contentPrefix: "Grandchild\n")
        let child2Leaf = findLeaf(in: tree, contentPrefix: "Child 2\n")

        #expect(child1Leaf?.indentation == 1)
        #expect(grandchildLeaf?.indentation == 2)
        #expect(child2Leaf?.indentation == 1)

        tree.verifyInvariants()
    }

    @Test("testExpand_PreservesNestedCollapsedState")
    func testExpand_PreservesNestedCollapsedState() throws {
        let fileContent = "P1\n\tP2\n\t\tC1\n\tC2\nE"
        let tree = TendrilTree(content: fileContent)

        // 1. Collapse P2 (the inner parent)
        try tree.collapse(range: tree.string.nsRange(of: "P2")!)
        #expect(tree.string == "P1\nP2\nC2\nE")

        // 2. Collapse P1 (the outer parent)
        try tree.collapse(range: tree.string.nsRange(of: "P1")!)
        #expect(tree.string == "P1\nE")

        // 3. Expand P1
        try tree.expand(range: tree.string.nsRange(of: "P1")!)

        // Expect P2 to be visible again, but still collapsed
        #expect(tree.string == "P1\nP2\nC2\nE")

        let leafP1 = findLeaf(in: tree, contentPrefix: "P1\n")
        #expect(leafP1?.collapsedChildren == nil)

        let leafP2 = findLeaf(in: tree, contentPrefix: "P2\n")
        #expect(leafP2 != nil)
        #expect(leafP2?.collapsedChildren != nil)  // P2's children should still be collapsed
        #expect(leafP2?.collapsedChildren?.fileString == "\tC1\n")

        tree.verifyInvariants()
    }
}
