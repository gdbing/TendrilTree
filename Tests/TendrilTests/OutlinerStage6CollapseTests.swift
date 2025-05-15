//
//  OutlinerStage5Tests.swift
//  TendrilTree
//
//  Created by Gemini Pro 2.5 on 2025-05-10.
//

import Foundation
import Testing
@testable import TendrilTree

// Helper to find a Leaf node by its content prefix in the visible tree
private func findLeaf(in tree: TendrilTree, contentPrefix: String) -> Leaf? {
    var targetLeaf: Leaf?

    func R(_ node: Node?) {
        guard let Rnode = node else { return }
        if targetLeaf != nil { return } // Found, stop searching

        if let leaf = Rnode as? Leaf {
            if leaf.content.hasPrefix(contentPrefix) {
                targetLeaf = leaf
            }
        } else {
            // Order of traversal can matter if prefixes are not unique,
            // but for these tests, prefixes should be distinct enough.
            if let left = Rnode.left { R(left) }
            if targetLeaf != nil { return } // Check after left traversal
            if let right = Rnode.right { R(right) }
        }
    }
    R(tree.root)
    return targetLeaf
}

// Helper to get NSRange from a substring in a larger string
extension String {
    func nsRange(of substring: String) -> NSRange? {
        if let range = self.range(of: substring) {
            return NSRange(range, in: self)
        }
        return nil
    }
}


@Suite final class OutlinerStage6CollapseTests {

    // MARK: - I. Basic Collapse Scenarios (Single Parent)

    @Test("testCollapse_RangeInsideParent_SimpleChildren")
    func testCollapse_RangeInsideParent_SimpleChildren() throws {
        let fileContent = "A\n\tB\n\tC\nD"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD")
        #expect(tree.fileString == fileContent.trimmingCharacters(in: .newlines))


        // Range within "A"
        let collapseRange = NSRange(location: 0, length: 1) // "A"

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nD")
        #expect(tree.length == "A\nD".utf16Length)
        #expect(tree.fileString == "A\nD") // Assuming A and D have indent 0
        #expect(tree.fileLength == "A\nD".utf16Length)

        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA != nil)
        #expect(leafA?.collapsedChildren != nil)
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n")

        let collapsedLeaves = leafA?.collapsedChildren?.leavesAt(start: 0, end: leafA!.collapsedChildren!.fileString.utf16Length) ?? []
        #expect(collapsedLeaves.count == 2)
        if collapsedLeaves.count == 2 {
            #expect(collapsedLeaves[0].content == "B\n")
            #expect(collapsedLeaves[0].indentation == 1)
            #expect(collapsedLeaves[1].content == "C\n")
            #expect(collapsedLeaves[1].indentation == 1)
        }
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeInsideParent_NestedChildren")
    func testCollapse_RangeInsideParent_NestedChildren() throws {
        let fileContent = "A\n\tB\n\t\tC\n\tD\nE\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD\nE")

        // Range within "A"
        let collapseRange = NSRange(location: 0, length: 1)

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nE")
        #expect(tree.fileString == "A\nE")

        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA != nil)
        #expect(leafA?.collapsedChildren != nil)
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\t\tC\n\tD\n")

        let collapsedLeaves = leafA?.collapsedChildren?.leavesAt(start: 0, end: leafA!.collapsedChildren!.fileString.utf16Length) ?? []
        #expect(collapsedLeaves.count == 3)
        if collapsedLeaves.count == 3 {
            #expect(collapsedLeaves[0].content == "B\n"); #expect(collapsedLeaves[0].indentation == 1)
            #expect(collapsedLeaves[1].content == "C\n"); #expect(collapsedLeaves[1].indentation == 2)
            #expect(collapsedLeaves[2].content == "D\n"); #expect(collapsedLeaves[2].indentation == 1)
        }
        tree.verifyInvariants()
    }

    @Test("testCollapse_CursorAtStartOfParent")
    func testCollapse_CursorAtStartOfParent() throws {
        let fileContent = "A\n\tB\n\tC\nD\n"
        let tree = TendrilTree(content: fileContent)

        let collapseRange = NSRange(location: 0, length: 0) // Cursor at start of A

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nD")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeExactlySpansParent")
    func testCollapse_RangeExactlySpansParent() throws {
        let fileContent = "Parent Leaf\n\tChild B\n\tChild C\nSibling D\n"
        let tree = TendrilTree(content: fileContent)

        let collapseRange = tree.string.nsRange(of: "Parent Leaf\n")!

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "Parent Leaf\nSibling D")
        let leafParent = findLeaf(in: tree, contentPrefix: "Parent Leaf\n")
        #expect(leafParent?.collapsedChildren?.fileString == "\tChild B\n\tChild C\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangePartiallyOverlapsParentStart")
    func testCollapse_RangePartiallyOverlapsParentStart() throws {
        let fileContent = "Parent Leaf\n\tChild Leaf\nSibling Leaf\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "Parent Leaf\nChild Leaf\nSibling Leaf")

        // Range covers "Parent Le"
        let collapseRange = tree.string.nsRange(of: "Parent Le")!

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "Parent Leaf\nSibling Leaf")
        let leafParent = findLeaf(in: tree, contentPrefix: "Parent Leaf\n")
        #expect(leafParent != nil)
        #expect(leafParent?.collapsedChildren != nil)
        #expect(leafParent?.collapsedChildren?.fileString == "\tChild Leaf\n")
        tree.verifyInvariants()
    }


    // MARK: - II. Target Identification Scenarios (Range within Child)

    @Test("testCollapse_RangeInsideDirectChild")
    func testCollapse_RangeInsideDirectChild() throws {
        let fileContent = "A\n\tB\n\tC\nD\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD")

        // Range within "B"
        let locB = tree.string.range(of: "B\n")!.lowerBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locB, length: 1) // Range on 'B'

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nD")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeInsideNestedChild")
    func testCollapse_RangeInsideNestedChild() throws {
        let fileContent = "A\n\tB\n\t\tC\n\tD\nE\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD\nE")

        // Range within "C"
        let locC = tree.string.range(of: "C\n")!.lowerBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locC, length: 1)

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nE")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\t\tC\n\tD\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_CursorAtStartOfChild")
    func testCollapse_CursorAtStartOfChild() throws {
        let fileContent = "A\n\tB\n\tC\nD\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD")

        let locBStart = tree.string.range(of: "B\n")!.lowerBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locBStart, length: 0)

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nD")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeSpanningMultipleChildrenOfSameParent")
    func testCollapse_RangeSpanningMultipleChildrenOfSameParent() throws {
        let fileContent = "A\n\tB\n\tC\n\tD\nE\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD\nE")

        // Range covers part of "B", all of "C", part of "D"
        let locB = tree.string.range(of: "B\n")!.lowerBound.utf16Offset(in: tree.string)
        let locDEnd = tree.string.range(of: "D\n")!.upperBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locB + 0, length: (locDEnd - locB) - 0)


        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nE")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n\tD\n")
        tree.verifyInvariants()
    }

    // MARK: - III. No-Op / Error Scenarios

    @Test("testCollapse_TargetHasNoChildren")
    func testCollapse_TargetHasNoChildren() throws {
        let fileContent = "A\nB\nC\n"
        let tree = TendrilTree(content: fileContent)
        let originalString = tree.string
        let originalFileString = tree.fileString

        // Range targets "A"
        let collapseRange = NSRange(location: 0, length: 1)

        #expect(throws: TendrilTreeError.cannotCollapse) {
            try tree.collapse(range: collapseRange)
        }

        #expect(tree.string == originalString)
        #expect(tree.fileString == originalFileString)
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren == nil)
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeInsideChildlessLeaf_ClimbsToParent")
    func testCollapse_RangeInsideChildlessLeaf_ClimbsToParent() throws {
        let fileContent = "A\n\tB\nC\n" // B is child of A, C is sibling of A. B itself is childless.
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC")

        // Range targets "B"
        let locB = tree.string.range(of: "B\n")!.lowerBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locB, length: 1)

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nC")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren != nil)
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_TargetAlreadyCollapsed_IsError")
    func testCollapse_TargetAlreadyCollapsed_IsError() throws {
        let fileContent = "A\n\tB\nC\n"
        let tree = TendrilTree(content: fileContent)

        // First collapse A
        try tree.collapse(range: NSRange(location: 0, length: 1))
        #expect(tree.string == "A\nC")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren != nil)
        let originalCollapsedContent = leafA?.collapsedChildren?.fileString

        // Attempt to collapse A again
        #expect(throws: TendrilTreeError.cannotCollapse) {
            try tree.collapse(range: NSRange(location: 0, length: 1))
        }

        #expect(tree.string == "A\nC") // State unchanged
        #expect(leafA?.collapsedChildren?.fileString == originalCollapsedContent) // Collapsed content unchanged
        tree.verifyInvariants()
    }


    @Test("testCollapse_InvalidRange_OutOfBounds")
    func testCollapse_InvalidRange_OutOfBounds() throws {
        let tree = TendrilTree(content: "A\nB\n")
        let originalString = tree.string

        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.collapse(range: NSRange(location: 100, length: 1))
        }
        #expect(tree.string == originalString) // State unchanged
        tree.verifyInvariants()
    }

    @Test("testCollapse_InvalidRange_NegativeLocation")
    func testCollapse_InvalidRange_NegativeLocation() throws {
        let tree = TendrilTree(content: "A\nB\n")
        let originalString = tree.string
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.collapse(range: NSRange(location: -1, length: 1))
        }
        #expect(tree.string == originalString)
        tree.verifyInvariants()
    }

    @Test("testCollapse_InvalidRange_NegativeLength")
    func testCollapse_InvalidRange_NegativeLength() throws {
        let tree = TendrilTree(content: "A\nB\n")
        let originalString = tree.string
        // NSRange with negative length is typically invalid at Foundation level,
        // but TendrilTree might have its own checks or rely on system behavior.
        // Assuming TendrilTree considers negative length an invalid range.
        #expect(throws: TendrilTreeError.invalidRange) {
             try tree.collapse(range: NSRange(location: 0, length: -1))
        }
        #expect(tree.string == originalString)
        tree.verifyInvariants()
    }


    // MARK: - IV. Multi-Parent / Complex Range Scenarios

    @Test("testCollapse_RangeSpansParentAndItsChildren")
    func testCollapse_RangeSpansParentAndItsChildren() throws {
        let fileContent = "A\n\tB\n\tC\nD\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD")

        // Range covering part of "A", all of "B", part of "C"
        // Visible: "A\nB\nC\nD"
        // Range: from 'A' to within 'C'. e.g. "A\nB\nC"
        let rangeToCover = "A\nB\nC"
        let collapseRange = NSRange(location: 0, length: rangeToCover.utf16Length)


        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nD")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeSpansMultipleDistinctParents")
    func testCollapse_RangeSpansMultipleDistinctParents() throws {
        let fileContent = "P1\n\tC1A\nP2\n\tC2A\nE\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "P1\nC1A\nP2\nC2A\nE")

        // Range covering end of C1A and start of P2.
        // Visible string: P1\nC1A\nP2\nC2A\nE
        // Range from within C1A to within P2. e.g. "1A\nP2"
        let locC1AStart = tree.string.range(of: "C1A\n")!.lowerBound.utf16Offset(in: tree.string)
        let locP2End = tree.string.range(of: "P2\n")!.upperBound.utf16Offset(in: tree.string)

        let collapseRange = NSRange(location: locC1AStart + 1, length: (locP2End - (locC1AStart + 1)))


        try tree.collapse(range: collapseRange)

        #expect(tree.string == "P1\nP2\nE")
        let leafP1 = findLeaf(in: tree, contentPrefix: "P1\n")
        #expect(leafP1?.collapsedChildren?.fileString == "\tC1A\n")
        let leafP2 = findLeaf(in: tree, contentPrefix: "P2\n")
        #expect(leafP2?.collapsedChildren?.fileString == "\tC2A\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_RangeSpansNestedParents_HighestAffectedCollapses")
    func testCollapse_RangeSpansNestedParents_HighestAffectedCollapses() throws {
        let fileContent = "P1\n\tP2\n\t\tC1\n\tC2\nE\n"
        // P1 is parent of P2, C2. P2 is parent of C1.
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "P1\nP2\nC1\nC2\nE")

        // Range covers P2 and C1
        // Visible: P1 P2 C1 C2 E
        let locP2Start = tree.string.range(of: "P2\n")!.lowerBound.utf16Offset(in: tree.string)
        let locC1End = tree.string.range(of: "C1\n")!.upperBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locP2Start, length: locC1End - locP2Start)

        try tree.collapse(range: collapseRange)

        // Expected: P1 collapses (hiding P2, C1, C2) because the range touches its descendants.
        #expect(tree.string == "P1\nE")
        let leafP1 = findLeaf(in: tree, contentPrefix: "P1\n")
        #expect(leafP1?.collapsedChildren != nil)
        #expect(leafP1?.collapsedChildren?.fileString == "\tP2\n\t\tC1\n\tC2\n")

        // P2 within P1's collapsed children should not have its *own* collapsedChildren set by *this* operation.
        // (It might have been pre-collapsed, which should be preserved, but this op doesn't cause it to collapse itself)
        let collapsedP1Children = leafP1?.collapsedChildren
        #expect(collapsedP1Children != nil)
        var p2InCollapsed: Leaf? = nil
        func findP2InNode(_ node: Node?) {
            guard let n = node else { return }
            if let leaf = n as? Leaf, leaf.content.hasPrefix("P2\n") {
                p2InCollapsed = leaf
                return
            }
            if p2InCollapsed == nil { findP2InNode(n.left) }
            if p2InCollapsed == nil { findP2InNode(n.right) }
        }
        findP2InNode(collapsedP1Children)

        #expect(p2InCollapsed != nil, "P2 should be found within P1's collapsed children")
        // If P2 was not pre-collapsed, its collapsedChildren should be nil.
        // If it was pre-collapsed, this test doesn't set up that state, so expect nil.
        #expect(p2InCollapsed?.collapsedChildren == nil)

        tree.verifyInvariants()
    }


    // MARK: - V. Boundary Cases

    @Test("testCollapse_CollapseFirstNodeWithChildren")
    func testCollapse_CollapseFirstNodeWithChildren() throws {
        let fileContent = "A\n\tB\nC\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC")

        try tree.collapse(range: NSRange(location: 0, length: 1)) // Target A

        #expect(tree.string == "A\nC")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_CollapseLastNodeWithChildren")
    func testCollapse_CollapseLastNodeWithChildren() throws {
        let fileContent = "X\nParent\n\tChild\n" // Parent is last node with children
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "X\nParent\nChild")

        // Target "Parent"
        let locParent = tree.string.range(of: "Parent\n")!.lowerBound.utf16Offset(in: tree.string)
        try tree.collapse(range: NSRange(location: locParent, length: "Parent".utf16Length))

        #expect(tree.string == "X\nParent")
        let leafParent = findLeaf(in: tree, contentPrefix: "Parent\n")
        #expect(leafParent?.collapsedChildren?.fileString == "\tChild\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_CollapseEverythingExceptRoot")
    func testCollapse_CollapseEverythingExceptRoot() throws {
        let fileContent = "A\n\tB\n\t\tC\n"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC")

        try tree.collapse(range: NSRange(location: 0, length: 1)) // Target A

        #expect(tree.string == "A")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tB\n\t\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_EmptyTree")
    func testCollapse_EmptyTree() throws {
        let tree = TendrilTree() // Empty
        #expect(throws: TendrilTreeError.invalidRange) { // Or cannotCollapse, depending on empty tree interpretation
             try tree.collapse(range: NSRange(location: 0, length: 0))
        }
        #expect(tree.string.isEmpty)
        tree.verifyInvariants() // Should still hold for an empty tree
    }

    @Test("testCollapse_TreeWithSingleRootLeaf_NoChildren")
    func testCollapse_TreeWithSingleRootLeaf_NoChildren() throws {
        let tree = TendrilTree(content: "Root\n")
        #expect(throws: TendrilTreeError.cannotCollapse) {
            try tree.collapse(range: NSRange(location: 0, length: 0))
        }
        #expect(tree.string == "Root")
        tree.verifyInvariants()
    }


    // MARK: - VI. State Verification Details

    @Test("testCollapse_CollapsedSubtree_CorrectContentAndIndentation")
    func testCollapse_CollapsedSubtree_CorrectContentAndIndentation() throws {
        let fileContent = "A\n\tB Item\n\t\tC Nested\n\tD Item\nE\n"
        let tree = TendrilTree(content: fileContent)

        try tree.collapse(range: NSRange(location: 0, length: 1)) // Target A

        #expect(tree.string == "A\nE")
        let leafA = findLeaf(in: tree, contentPrefix: "A\n")
        #expect(leafA != nil)
        let collapsedRoot = leafA?.collapsedChildren
        #expect(collapsedRoot != nil)

        #expect(collapsedRoot?.fileString == "\tB Item\n\t\tC Nested\n\tD Item\n")

        let collapsedLeaves = collapsedRoot?.leavesAt(start: 0, end: collapsedRoot!.fileString.utf16Length) ?? []
        #expect(collapsedLeaves.count == 3)
        if collapsedLeaves.count == 3 {
            #expect(collapsedLeaves[0].content == "B Item\n")
            #expect(collapsedLeaves[0].indentation == 1)
            #expect(collapsedLeaves[1].content == "C Nested\n")
            #expect(collapsedLeaves[1].indentation == 2)
            #expect(collapsedLeaves[2].content == "D Item\n")
            #expect(collapsedLeaves[2].indentation == 1)
        }
        tree.verifyInvariants()
    }

    @Test("testCollapse_WeightUpdate_Correctness")
    func testCollapse_WeightUpdate_Correctness() throws {
        // A (vis len 2)
        //   B (vis len 2)
        //   C (vis len 2)
        // D (vis len 2)
        //   E (vis len 2)
        // Total initial visible string: A\nB\nC\nD\nE (length 9)
        // File string: A\n\tB\n\tC\nD\n\tE\n
        let fileContent = "A\n\tB\n\tC\nD\n\tE\n"
        let tree = TendrilTree(content: fileContent)
        // tree.root structure (example, depends on parse):
        //      Node_ABCDE (w depends on left side of split)
        //      /     \
        //   Node_ABC   Node_DE
        //   /   \      /   \
        //  A   Node_BC D     E
        //      /  \
        //     B    C
        //
        // After parsing "A\n\tB\n\tC\nD\n\tE\n", tree.root.string = "A\nB\nC\nD\nE\n"
        // tree.string = "A\nB\nC\nD\nE"
        //
        // Let's verify weights manually based on a plausible parse:
        // Leaves: A(2), B(2), C(2), D(2), E(2) (content length including \n)
        // Node_BC: left=B, right=C. weight=B.weight=2
        // Node_ABC: left=A, right=Node_BC. weight=A.weight=2
        // Node_DE: left=D, right=E. weight=D.weight=2
        // Root: left=Node_ABC, right=Node_DE. weight=Node_ABC.string.utf16Length = A(2)+B(2)+C(2) = 6
        // This matches general weight logic.

        let originalRootWeight = tree.root.weight
        // For "A\nB\nC\nD\nE\n", Node.parse makes:
        // C is mid. Left = [A,B], Right = [D,E]
        // Root (C)
        //  L: Node(A,B) w=A.len=2
        //  R: Node(D,E) w=D.len=2
        // Root has left child (A,B) and right child (C). And C has left child (D,E)
        // My mistake, Node.parse creates a tree with Leaf(C) as root, Left child is tree of [A,B], Right is tree of [D,E]
        // A\nB\nC\nD\nE\n
        // Leaf A, indent 0, content "A\n"
        // Leaf B, indent 1, content "B\n"
        // Leaf C, indent 1, content "C\n"
        // Leaf D, indent 0, content "D\n"
        // Leaf E, indent 1, content "E\n"
        //
        // Tree Structure (from parse):
        //                Node (root, representing C)
        //               /         \
        // Node (A,B)           Node (D,E)
        //    /    \              /    \
        // Leaf A  Leaf B      Leaf D  Leaf E
        //
        // Actually, TendrilTree's parser builds it like this:
        // Input: A\n\tB\n\tC\nD\n\tE\n -> visible internal: A\nB\nC\nD\nE\n
        // Leaves parsed: A(i0), B(i1), C(i1), D(i0), E(i1)
        // Mid is C. Root=C. L=[A,B], R=[D,E]
        // Root(Leaf C, i1).left = Node_AB. Node_AB.mid=A. Node_AB = (Leaf A, i0).left=nil, (Leaf A,i0).right=(Leaf B,i1)
        // This parse logic seems off. Let's use a simpler tree structure for weight testing.

        // Let's use a tree that will be:
        //    Node1
        //    /   \
        //   A     Node2
        //         /   \
        //        D     X
        // A\n D\n\tCHILD_OF_D\n X\n
        // For this, let content be: "A\nP\n\tC1\n\tC2\nS\n" -> visible "A\nP\nC1\nC2\nS"
        // A = "A\n" (i0)
        // P = "P\n" (i0)
        // C1= "C1\n"(i1)
        // C2= "C2\n"(i1)
        // S = "S\n" (i0)
        // Parse: [A, P, C1, C2, S]. Mid = C1.
        // Root = Leaf(C1). Left Tree for [A,P]. Right Tree for [C2,S]
        // LeftTree([A,P]): Mid = A. Root=Leaf(A). Left=nil. Right=Leaf(P). Node(A,P).weight = A.content.len
        // Root(C1).left = Node(A,P). Root(C1).weight = Node(A,P).string.len = (A.len+P.len)
        // This is complex. The weight test should focus on an actual operation.

        // Given: P\n\tC1\n\tC2\nS\n
        let tree2 = TendrilTree(content: "P\n\tC1\n\tC2\nS\n")
        // Visible: P\nC1\nC2\nS
        // P.content = "P\n" (len 2)
        // C1.content = "C1\n" (len 3)
        // C2.content = "C2\n" (len 3)
        // S.content = "S\n" (len 2)
        // tree2.root.string (internal, with all newlines) = P\nC1\nC2\nS\n
        // tree2.length = ("P\nC1\nC2\nS").utf16Length = 2+3+3+2 = 10

        // Let's find P
        let leafP_before = findLeaf(in: tree2, contentPrefix: "P\n")!
        #expect(leafP_before.indentation == 0)
        let initialWeightOfParentP = leafP_before.weight // P itself, weight is P.content.utf16Length
        // Find root node of P, C1, C2 subtree if P is collapsed
        // For P\n\tC1\n\tC2\nS\n, the common ancestor of P, C1, C2 might be high up.
        // Let's check root weight:
        let originalRootWeight2 = tree2.root.weight

        // Collapse P (range on P)
        try tree2.collapse(range: NSRange(location: 0, length: "P".utf16Length))
        // Visible: P\nS
        // tree2.length = ("P\nS").utf16Length = 2+2 = 4

        #expect(tree2.string == "P\nS")
        #expect(tree2.length == 4)

        // Check leaf P's weight (it's visible, so its weight is its own content)
        let leafP_after = findLeaf(in: tree2, contentPrefix: "P\n")!
        #expect(leafP_after.weight == "P\n".utf16Length)

        // The tree structure changed.
        // The original `tree2.root` might have changed instance or its children.
        // The key is that `tree.verifyInvariants()` includes `node.weight == node.left?.calculateWeight()`.
        // `calculateWeight()` sums content lengths. So this check is inherent in `verifyInvariants`.
        tree2.verifyInvariants() // This will check weights recursively.
    }
}
