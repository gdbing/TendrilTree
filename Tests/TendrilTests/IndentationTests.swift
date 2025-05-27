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
        #expect(range.length == 5) // NB extra trailing newline which is trimmed from tree.string
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.rangeOfLine(at: 13)
        }
    }
}

