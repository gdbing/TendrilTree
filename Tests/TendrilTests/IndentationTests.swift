//
//  IndentationTests.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-21.
//

import Foundation
import Testing

@testable import TendrilTree

@Suite final actor IndentationTests {
    @Test func testIndentNewline() {
        let tree = TendrilTree(content: "abc\n")
        #expect(tree.fileString == "abc\n")
        try! tree.indent(range: NSRange(location: 4, length: 0))
        #expect(tree.fileString == "abc\n\t")
        #expect(try! tree.indentation(at: 0) == 0)
        #expect(try! tree.indentation(at: 4) == 1)
    }

    @Test func testIndentNewline2() {
        let tree = TendrilTree(content: "\tabc")
        #expect(tree.fileString == "\tabc")
        try! tree.insert(content: "\n", at: 3)
        #expect(tree.fileString == "\tabc\n\t")
        #expect(try! tree.indentation(at: 0) == 1)
        #expect(try! tree.indentation(at: 4) == 1)
    }

    @Test func testLeavesAt() {
        let tree = TendrilTree(content: "abc\nefg\nhijk")
        let leaves = tree.root.leavesAt(start: 8, end: 8)
        #expect(leaves.count == 1)
    }

    @Test func testRangeOfLeavesAt() {
        let tree = TendrilTree(content: "abc\nefg\nhijk")
        var range = try! tree.rangeOfLine(at: 0)
        #expect(range.location == 0)
        #expect(range.length == 4)
        range = try! tree.rangeOfLine(at: 4)
        #expect(range.location == 4)
        #expect(range.length == 4)
        range = try! tree.rangeOfLine(at: 5)
        #expect(range.location == 4)
        #expect(range.length == 4)
        range = try! tree.rangeOfLine(at: 12)
        #expect(range.location == 8)
        #expect(range.length == 5)  // NB extra trailing newline which is trimmed from tree.string
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.rangeOfLine(at: 13)
        }
    }

    @Test func testInsertTabs() throws {
        let tree = TendrilTree(content: "")
        try tree.insert(content: "\t\t\t", at: 0)
        #expect(tree.string == "")
        #expect(tree.fileString == "\t\t\t")
        try tree.insert(content: "\tabcd", at: 0)
        #expect(tree.string == "abcd")
        #expect(tree.fileString == "\t\t\t\tabcd")
        try tree.insert(content: "\t\t", at: 0)
        #expect(tree.string == "abcd")
        #expect(tree.fileString == "\t\t\t\t\t\tabcd")
        try tree.insert(content: "\t", at: 2)
        #expect(tree.string == "ab\tcd")
        #expect(tree.fileString == "\t\t\t\t\t\tab\tcd")
    }

    @Test func testDeleteIndentation() throws {
        let tree = TendrilTree(content: "\t\t\t\t\t\tab\tcd")
        #expect(tree.string == "ab\tcd")
        #expect(tree.fileString == "\t\t\t\t\t\tab\tcd")
        #expect(tree.fileString.count == 11)
        #expect((tree.root as? Leaf)?.indentation == 6)
        try tree.delete(range: NSRange(location: 0, length: 2))
        #expect(tree.string == "cd")
        #expect(tree.fileString == "\t\t\t\t\t\t\tcd")
        #expect(tree.fileString.count == 9)
        #expect((tree.root as? Leaf)?.indentation == 7)

    }

    @Test func testInsertTabs_multiline() throws {
        let tree = TendrilTree(content: "")
        try tree.insert(content: "abc\n\tdef\n\t\tghi", at: 0)
        #expect(tree.string == "abc\ndef\nghi")
        #expect(tree.fileString == "abc\n\tdef\n\t\tghi")
    }

    // MARK: - Tab Conversion Utility Tests

    @Test func testConvertLeadingTabsToIndentation_emptyString() {
        let result = TendrilTree.convertLeadingTabsToIndentation("")
        #expect(result.content == "")
        #expect(result.indentation == 0)
    }

    @Test func testConvertLeadingTabsToIndentation_noTabs() {
        let result = TendrilTree.convertLeadingTabsToIndentation("hello world")
        #expect(result.content == "hello world")
        #expect(result.indentation == 0)
    }

    @Test func testConvertLeadingTabsToIndentation_onlyTabs() {
        let result = TendrilTree.convertLeadingTabsToIndentation("\t\t\t")
        #expect(result.content == "")
        #expect(result.indentation == 3)
    }

    @Test func testConvertLeadingTabsToIndentation_tabsAndContent() {
        let result = TendrilTree.convertLeadingTabsToIndentation("\t\t\thello world")
        #expect(result.content == "hello world")
        #expect(result.indentation == 3)
    }

    @Test func testConvertLeadingTabsToIndentation_tabsInMiddle() {
        let result = TendrilTree.convertLeadingTabsToIndentation("\t\thello\tworld")
        #expect(result.content == "hello\tworld")
        #expect(result.indentation == 2)
    }

    @Test func testProcessMultilineInsert() {
        let result = TendrilTree.processMultilineInsert("abc\n\tdef\n\t\tghi")
        #expect(result.count == 3)
        #expect(result[0].content == "abc\n")
        #expect(result[0].indentation == 0)
        #expect(result[1].content == "def\n")
        #expect(result[1].indentation == 1)
        #expect(result[2].content == "ghi")
        #expect(result[2].indentation == 2)
    }

    @Test func testProcessMultilineInsert_noNewlines() {
        let result = TendrilTree.processMultilineInsert("\t\thello")
        #expect(result.count == 1)
        #expect(result[0].content == "hello")
        #expect(result[0].indentation == 2)
    }
}
