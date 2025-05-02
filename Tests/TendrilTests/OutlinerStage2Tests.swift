//
//  OutlinerStage2Tests.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-05-02.
//


import Foundation
import Testing
@testable import TendrilTree

// Helper: Recursively collect all Leaf nodes from a Node tree.
private func collectLeaves(from node: Node) -> [Leaf] {
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

@Suite final class OutlinerStage2Tests {
    
    // Test 1:
    // When an insertion splits a Leaf, both the new left leaf and the (modified) right leaf
    // must keep the original leaf’s indentation.
    @Test("Insertion preserves indentation on leaf split")
    func testInsertSplittingPreservesIndentation() throws {
        // Create a tree with one paragraph that has two leading tabs.
        // The parser will remove the virtual tabs, store content "HelloWorld\n"
        // and record indentation == 2.
        let input = "\t\tHelloWorld"
        let tree = TendrilTree(content: input)
        // Verify initial visible string and (internal) weight.
        #expect(tree.string == "HelloWorld")
        let leavesBefore = collectLeaves(from: tree.root)
        #expect(leavesBefore.count == 1)
        #expect(leavesBefore[0].indentation == 2)
        
        // Let’s now insert an extra paragraph break in the middle.
        // Our insert will insert "X\n" into the text.
        // According to our modified Leaf.insert:
        // If the text to insert ends with "\n" (and prefix does not already end with "\n"),
        // then a split is performed.
        // We choose an offset inside the leaf (for example, after 5 UTF‑16 code units).
        try tree.insert(content: "X\n", at: 5)
        // The resulting visible text should be "HelloX\nWorld\n"
        #expect(tree.string == "HelloX\nWorld")
        
        // Now verify that each resulting leaf retains the original indentation (2)
        let leavesAfter = collectLeaves(from: tree.root)
        #expect(leavesAfter.count == 2)
        for leaf in leavesAfter {
            #expect(leaf.indentation == 2, "Every split leaf should inherit indentation 2")
        }
    }
    
    // Test 2:
    // When deletion causes two leaves to merge (via the cutLeaf/merge mechanism),
    // the merged leaf should inherit the indentation of the first (preceding) leaf.
    @Test("Deletion merges leaves preserving left leaf indentation")
    func testDeleteMergesPreserveIndentation() throws {
        // Create a tree with two lines that have different indentation.
        // For example, the first line starts with two tabs and the second line starts with three tabs.
        // (Remember that the parser removes the literal tabs so that the visible content is without them.)
        let input = "\t\tHello\n\t\t\tWorld"
        let tree = TendrilTree(content: input)
        // Expected visible string is "Hello\nWorld\n".
        #expect(tree.string == "Hello\nWorld")
        let leavesBefore = collectLeaves(from: tree.root)
        #expect(leavesBefore.count == 2)
        #expect(leavesBefore[0].indentation == 2)
        #expect(leavesBefore[1].indentation == 3)
        
        // Now simulate a deletion that removes the newline at the end of the first paragraph.
        // For our visible string "Hello\nWorld\n" the newline after "Hello" is at offset 5 (after "Hello").
        // Remove one UTF-16 code unit (the newline) so that the two paragraphs merge.
        try tree.delete(range: NSRange(location: 5, length: 1))
        // Now we expect the merged paragraph visible string to be "HelloWorld\n"
        #expect(tree.string == "HelloWorld")
        let leavesAfter = collectLeaves(from: tree.root)
        #expect(leavesAfter.count == 1, "Expected the two leaves to merge into a single leaf")
        // According to the spec, the merged leaf should inherit the first leaf’s indentation (2)
        #expect(leavesAfter[0].indentation == 2, "Merged leaf should keep indentation of the first leaf")
    }
    
    // Test 3:
    // Insertions at the document boundaries
    @Test("Insertion at beginning and end preserves indentation")
    func testInsertAtDocumentBoundaries() throws {
        // Create a tree whose only paragraph has one tab leading (indentation==1)
        let input = "\tStart"
        let tree = TendrilTree(content: input)
        #expect(tree.string == "Start")
        let leavesBefore = collectLeaves(from: tree.root)
        #expect(leavesBefore.count == 1)
        #expect(leavesBefore[0].indentation == 1)
        
        // Insert some text at the very beginning of the document.
        try tree.insert(content: "Pre\n", at: 0)
        // Expect that the inserted leaf’s indentation is not automatically set,
        // but the merge/insertion when the block is added into an existing leaf
        // should keep the indentation of the leaf in which the insertion occurred.
        // For this simple test we simply check that the overall visible string is as expected.
        #expect(tree.string == "Pre\nStart")
        // In the new tree, the first leaf (if split) should have the same indentation as the original “Pre” insertion
        // or if the inserted content was merged into the first leaf,
        // the resulting leaf (with content "PreStart\n") should have the original indentation (1)
        let leavesAfterBegin = collectLeaves(from: tree.root)
        for leaf in leavesAfterBegin {
            // We assume that any affected leaf remains with indentation==1.
            #expect(leaf.indentation == 1, "Leaf should retain its original indentation of 1")
        }
        
        // Now insert at the end.
        let currentLength = tree.length
        try tree.insert(content: "\nPost", at: currentLength)
        // The visible string should now be "Pre\nStart\n\nPost"
        #expect(tree.string == "Pre\nStart\nPost")
        // Check that the new leaf(s) inserted preserve the indentation;
        // i.e. the new paragraph following the insertion point should inherit the indentation of the leaf at the boundary.
        let leavesAfterEnd = collectLeaves(from: tree.root)
        // For this test we are mainly checking that no unexpected change of indentation has occurred.
        for leaf in leavesAfterEnd {
            #expect(leaf.indentation == 1, "All leaves should continue to have indentation 1")
        }
    }
    
    // Test 4:
    // Verify that Node.weight reflects only the total visible content length (i.e. it ignores the virtual indentation).
    @Test("Node.weight remains based solely on content length (excluding indentation)")
    func testNodeWeightExcludesIndentation() throws {
        // Create a tree with two lines. Each line originally had some leading tabs.
        let input = "\t\tAlpha\n\tBeta\n"
        // Expected visible content is "Alpha\nBeta\n"
        let tree = TendrilTree(content: input)
        #expect(tree.string == "Alpha\nBeta\n")
        
        // Collect individual leaf nodes.
        let leaves = collectLeaves(from: tree.root)
        
        // Verify each leaf's weight is based only on visible content.
        for leaf in leaves {
            let expectedWeight = leaf.content.utf16.count
            #expect(leaf.weight == expectedWeight, "Leaf weight should equal its pure content length without accounting for indentation")
        }
        
        // Verify that the root's weight matches the content length of the left-most subtree's leaf nodes' content.
        // (It will reflect the total length of just the left subtree without counting additional characters in `right`. In this case, "Alpha\n".)
        let leftWeight = leaves.first?.content.utf16.count ?? 0
        #expect(tree.root.weight == leftWeight, "Root's weight should equal the length of its left subtree's content, excluding indentation.")
    }
}
