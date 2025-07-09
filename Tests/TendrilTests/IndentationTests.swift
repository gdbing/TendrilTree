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
        var leaves = tree.root.leavesAt(start: 8, end: 8)
        #expect(leaves.count == 1)
        leaves = tree.root.leavesAt(start: 0, end: "abc\nefg\nhijk".count)
        #expect(leaves.count == 3)
        leaves = tree.root.leavesAt(start: "abc".count, end: "abc\nefg\n".count)
        #expect(leaves.count == 3)
        leaves = tree.root.leavesAt(start: "abc\n".count, end: "abc\nefg".count)
        #expect(leaves.count == 1)
        leaves = tree.root.leavesAt(start: "abc".count, end: "abc".count)
        #expect(leaves.count == 1)
        leaves = tree.root.leavesAt(start: "abc".count, end: "abc\n".count)
        #expect(leaves.count == 2)
        leaves = tree.root.leavesAt(start: "abc\n".count, end: "abc\n".count)
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

    @Test func testInsertNewline() throws {
        let tree = TendrilTree(content: "ab\tcd")
        try tree.insert(content: "\n", at: 2)
        #expect(tree.string == "ab\ncd")
        #expect(tree.fileString == "ab\n\tcd")
    }

    @Test func testCallback() throws {
        let tree = TendrilTree()
        try tree.insert(content: "abc", at: 0) { insertion, range in
            #expect(insertion == "abc")
            #expect(range.location == 0)
            #expect(range.length == 0)
        }
        try tree.insert(content: "\n", at: 3) { insertion, range in
            #expect(insertion == "\n")
            #expect(range.location == 3)
            #expect(range.length == 0)
        }
        try tree.insert(content: "def", at: 4) { insertion, range in
            #expect(insertion == "def")
            #expect(range.location == 4)
            #expect(range.length == 0)
        }
        try tree.delete(range: NSRange(location: 0, length: "abc\ndef".count)) { insertion, range in
            #expect(insertion == "")
            #expect(range.location == 0)
            #expect(range.length == "abc\ndef".count)
        }
    }

    @Test func testCallback_withTabs() throws {
        let tree = TendrilTree()
        try tree.insert(content: "abc\n\tdef\n\t\tghi", at: 0) { insertion, range in
            #expect(insertion == "abc\ndef\nghi")
            #expect(range.location == 0)
            #expect(range.length == 0)
        }
        try tree.delete(range: NSRange(location: 0, length: "abc\ndef\nghi".count)) { insertion, range in
            #expect(insertion == "")
            #expect(range.location == 0)
            #expect(range.length == "abc\ndef\nghi".count)
        }
    }

    @Test func testCallback_insertNewlineChangesIndentation() throws {
        let tree = TendrilTree(content: "ab\t\tcd")
        try tree.insert(content: "\n", at: 2) { insertion, range in
            #expect(insertion == "\n")
            #expect(range.location == 2)
            #expect(range.length == 2)
        }
    }

    @Test func testCallback_deletionChangesIndentation() throws {
        let tree = TendrilTree(content: "ab\t\tcd")
        try tree.delete(range: NSRange(location: 0, length: 2)) { insertion, range in
            #expect(insertion == "")
            #expect(range.location == 0)
            #expect(range.length == 4)
        }
        #expect(tree.string == "cd")
    }

    @Test func testCallback_insertTabs() throws {
        let tree = TendrilTree(content: "abcd")
        try tree.insert(content: "\t\t", at: 4) { insertion, range in
            #expect(insertion == "\t\t")
            #expect(range.location == 4)
            #expect(range.length == 0)
        }
        try tree.insert(content: "\t\t", at: 2) { insertion, range in
            #expect(insertion == "\t\t")
            #expect(range.location == 2)
            #expect(range.length == 0)
        }
        try tree.insert(content: "\t\t", at: 0) { insertion, range in
            #expect(insertion == "")
            #expect(range.location == 0)
            #expect(range.length == 0)
        }
    }

    @Test func testCallback_insertMultipleLines() throws {
        let tree = TendrilTree()
        try tree.insert(content: "\t\t\tabc\n\tdef\n\t\tghi\t", at: 0) { insertion, range in
            #expect(insertion == "abc\ndef\nghi\t")
            #expect(range.location == 0)
            #expect(range.length == 0)
        }
        try tree.insert(content: "\n\t\n\t\n\t", at: "abc\ndef\nghi".count) { insertion, range in
            #expect(insertion == "\n\n\n")
            #expect(range.location == "abc\ndef\nghi".count)
            #expect(range.length == 1)
        }

    }
}
