//
//  OutlinerStage1Tests.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-05-01.
//
// Tests for Stage 1 – Outliner indentation data model & parsing
//
// Requirements tested:
//   • Leaf(content:indentation:) initializer stores content without tab characters
//     and the correct indentation level.
//   • Node.parse(content:) detects and counts leading "\t" characters, removes them
//     from the stored Leaf.content, and sets Leaf.indentation accordingly.
//   • Parsing of lines with no leading tabs (indentation level zero) works correctly.
//   • Parsing of empty input or input having only newlines results in valid (empty) leaves.
//   • The Node.string (and thus TendrilTree.string) property returns the raw content
//     with no added (virtual) indentation prefixes (handled later in Stage 3).
//   • Node.weight (and TendrilTree.length) reflects only the sum of the Leaf.content lengths,
//     not including any virtual tab characters.
//

 import Foundation
 import Testing
 @testable import TendrilTree

 @Suite final class OutlinerStage1Tests {
     
     @Test
     func testIndentationWeight() {
         let tree = TendrilTree(content: "\tone\n\ttwo")
         #expect(tree.string == "one\ntwo")
         #expect(tree.root.weight == 4)
         #expect(tree.root.left?.string == "one\n")
         #expect(tree.root.left?.weight == 4)
     }

     // Test that the new Leaf initializer accepts and stores an indentation value
     @Test("Leaf initializer stores content and indentation")
     func testLeafInitializer() {
         // (Assumes you have added an initializer like: init(_ content: String, indentation: Int = 0))
         let leaf = Leaf("Hello\n", indentation: 3)
         #expect(leaf.content == "Hello\n", "Expected stored content to have no leading tabs")
         #expect(leaf.indentation == 3, "Indentation property should equal the given value")
     }

     // Test that Node.parse correctly detects and removes leading tabs from each line
     @Test("Node.parse detects leading tabs and sets indentation")
     func testNodeParsingWithIndentation() {
         // Each line’s leading tabs should be counted and stripped from the content.
         // For example, the first line begins with two tabs, the second with one, the third with none.
         let input = "\t\tHello\n\tWorld\nNo Indent\n"
         guard let (node, _) = Node.parse(input) else {
             Issue.record("Node.parse failed for input")
             return
         }
         let leaves = collectLeaves(from: node)
         #expect(leaves.count == 3, "Expected three leaves from three paragraphs")

         #expect(leaves[0].indentation == 2, "Expected first line indentation to be 2")
         #expect(leaves[0].content == "Hello\n", "Expected leading tabs removed from first line")

         #expect(leaves[1].indentation == 1, "Expected second line indentation to be 1")
         #expect(leaves[1].content == "World\n", "Expected leading tabs removed from second line")

         #expect(leaves[2].indentation == 0, "Expected third line indentation to be 0")
         #expect(leaves[2].content == "No Indent\n", "Expected content unchanged when no tabs")
     }

     // Test that parsing works correctly when there is no indentation
     @Test("Parsing handles lines with no indentation correctly")
     func testNodeParsingNoIndent() {
         let input = "Line1\nLine2\n"
         guard let (node, _) = Node.parse(input) else {
             Issue.record("Node.parse failed for input with no indentation")
             return
         }
         let leaves = collectLeaves(from: node)
         for leaf in leaves {
             #expect(leaf.indentation == 0, "Expected no indentation on any leaf")
         }
     }

     // Test that parsing empty input or input with only newlines results in valid leaves
     @Test("Parsing handles empty input or input with only newlines")
     func testNodeParsingEmptyInput() {
         let input = "\n\n"
         guard let (node, _) = Node.parse(input) else {
             Issue.record("Node.parse failed for input with only newlines")
             return
         }
         let leaves = collectLeaves(from: node)
         // In our design each newline represents a paragraph.
         #expect(leaves.count == 2, "Expected two paragraphs for two newlines")
         for leaf in leaves {
             #expect(leaf.content == "\n", "Each empty paragraph should contain just the newline")
             #expect(leaf.indentation == 0, "Empty lines should have zero indentation")
         }
     }

     // (Initial) Test that the visible string output excludes any (virtual) indentation prefixes.
     @Test("Node.string returns content without indentation prefixes")
     func testNodeStringExcludesIndentation() {
         let input = "\tHello\n"  // Should be stored as indentation 1 and content "Hello\n"
         guard let (node, _) = Node.parse(input) else {
             Issue.record("Node.parse failed for simple input")
             return
         }
         // Stage 3 will add visual indentation – for now, the string should show only the content.
         #expect(node.string == "Hello\n", "Node.string should not include virtual tab characters")
     }

     // (Initial) Test that the Node.weight is based solely on the Leaf.content length,
     // that is, the weight does not include any virtual tabs from indentation.
     @Test("Node.weight reflects only Leaf.content length, excluding indentation")
     func testNodeWeightExcludesIndentation() {
         let input = "\t\tHello\n"  // "Hello\n" length is 6, even though indentation is 2.
         guard let (node, _) = Node.parse(input) else {
             Issue.record("Node.parse failed for input")
             return
         }
         let leaves = collectLeaves(from: node)
         guard let leaf = leaves.first else {
             Issue.record("No leaf retrieved")
             return
         }
         let contentLength = leaf.content.utf16.count
         #expect(leaf.weight == contentLength, "Leaf weight should equal pure content length")
         #expect(node.weight == contentLength, "Node weight should sum only visible content lengths")
     }

     // Helper function to collect all Leaf nodes from a Node sub-tree
     private func collectLeaves(from node: Node) -> [Leaf] {
         var result: [Leaf] = []
         func traverse(_ current: Node) {
             if let leaf = current as? Leaf {
                 result.append(leaf)
             } else {
                 if let left = current.left { traverse(left) }
                 if let right = current.right { traverse(right) }
             }
         }
         traverse(node)
         return result
     }
 }