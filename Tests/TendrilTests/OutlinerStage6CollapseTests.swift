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
        let fileContent = "A\n\tB\n\t\tC\n\tD\nE"
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
        let fileContent = "A\n\tB\n\tC\nD"
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
        let fileContent = "Parent Leaf\n\tChild B\n\tChild C\nSibling D"
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
        let fileContent = "Parent Leaf\n\tChild Leaf\nSibling Leaf"
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
        let fileContent = "A\n\tB\n\tC\nD"
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

    // A
    //   B
    //     C
    //   D
    // E
    @Test("testCollapse_RangeInsideNestedChild")
    func testCollapse_RangeInsideNestedChild() throws {
        let fileContent = "A\n\tB\n\t\tC\n\tD\nE"
        let tree = TendrilTree(content: fileContent)
        #expect(tree.string == "A\nB\nC\nD\nE")

        // Range within "C"
        let locC = tree.string.range(of: "C\n")!.lowerBound.utf16Offset(in: tree.string)
        let collapseRange = NSRange(location: locC, length: 1)

        try tree.collapse(range: collapseRange)

        #expect(tree.string == "A\nB\nD\nE")
        let leafA = findLeaf(in: tree, contentPrefix: "B\n")
        #expect(leafA?.collapsedChildren?.fileString == "\tC\n")
        tree.verifyInvariants()
    }

    @Test("testCollapse_CursorAtStartOfChild")
    func testCollapse_CursorAtStartOfChild() throws {
        let fileContent = "A\n\tB\n\tC\nD"
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
        let fileContent = "A\n\tB\n\tC\n\tD\nE"
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
        let fileContent = "A\nB\nC"
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
        let fileContent = "A\n\tB\nC" // B is child of A, C is sibling of A. B itself is childless.
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
        let fileContent = "A\n\tB\nC"
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
        let tree = TendrilTree(content: "A\nB")
        let originalString = tree.string

        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.collapse(range: NSRange(location: 100, length: 1))
        }
        #expect(tree.string == originalString) // State unchanged
        tree.verifyInvariants()
    }

    @Test("testCollapse_InvalidRange_NegativeLocation")
    func testCollapse_InvalidRange_NegativeLocation() throws {
        let tree = TendrilTree(content: "A\nB")
        let originalString = tree.string
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.collapse(range: NSRange(location: -1, length: 1))
        }
        #expect(tree.string == originalString)
        tree.verifyInvariants()
    }

    @Test("testCollapse_InvalidRange_NegativeLength")
    func testCollapse_InvalidRange_NegativeLength() throws {
        let tree = TendrilTree(content: "A\nB")
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
        let fileContent = "A\n\tB\n\tC\nD"
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
        let fileContent = "P1\n\tC1A\nP2\n\tC2A\nE"
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

    // P1
    //   P2
    //     C1
    //   C2
    // E
    @Test("testCollapse_RangeSpansNestedParents_HighestAffectedCollapses")
    func testCollapse_RangeSpansNestedParents_HighestAffectedCollapses() throws {
        let fileContent = "P1\n\tP2\n\t\tC1\n\tC2\nE"
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
        #expect(leafP1?.collapsedChildren?.fileString == "\tP2\n\tC2\n")
        #expect((leafP1?.collapsedChildren?.left as? Leaf)?.collapsedChildren != nil)
        #expect((leafP1?.collapsedChildren?.left as? Leaf)?.collapsedChildren?.fileString == "\tC1\n")

        tree.verifyInvariants()
    }


    // MARK: - V. Boundary Cases

    @Test("testCollapse_CollapseFirstNodeWithChildren")
    func testCollapse_CollapseFirstNodeWithChildren() throws {
        let fileContent = "A\n\tB\nC"
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
        let fileContent = "X\nParent\n\tChild" // Parent is last node with children
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
        let fileContent = "A\n\tB\n\t\tC"
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
        #expect(throws: TendrilTreeError.cannotCollapse) { // Or cannotCollapse, depending on empty tree interpretation
             try tree.collapse(range: NSRange(location: 0, length: 0))
        }
        #expect(tree.string.isEmpty)
        tree.verifyInvariants() // Should still hold for an empty tree
    }

    @Test("testCollapse_TreeWithSingleRootLeaf_NoChildren")
    func testCollapse_TreeWithSingleRootLeaf_NoChildren() throws {
        let tree = TendrilTree(content: "Root")
        #expect(throws: TendrilTreeError.cannotCollapse) {
            try tree.collapse(range: NSRange(location: 0, length: 0))
        }
        #expect(tree.string == "Root")
        tree.verifyInvariants()
    }

    // MARK: - VI. State Verification Details

    @Test("testCollapse_CollapsedSubtree_CorrectContentAndIndentation")
    func testCollapse_CollapsedSubtree_CorrectContentAndIndentation() throws {
        let fileContent = "A\n\tB Item\n\t\tC Nested\n\tD Item\nE"
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
}
