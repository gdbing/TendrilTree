//
//  DeletionTests.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-01.
//

import Foundation
import Testing
@testable import TendrilTree

// MARK: - Delete
@Suite final class DeletionTests {
    @Test("Delete Prefix", arguments: prefixes, suffixes)
    func testDeletePrefix(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.delete(range: NSRange(location: 0, length: prefix.utf16Length))
        #expect(tendrilTree.string == suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Delete Suffix", arguments: prefixes, suffixes)
    func testDeleteSuffix(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.delete(range: NSRange(location: prefix.utf16Length, length: suffix.utf16Length))
        #expect(tendrilTree.string == prefix)
        tendrilTree.verifyInvariants()
    }

    @Test("Delete Middle", arguments: prefixes, suffixes)
    func testDeleteMiddle(prefix: String, suffix: String) throws {
        let content = prefix + suffix
        let tendrilTree = TendrilTree(content: content)
        let nsRange = NSRange(location: content.utf16Length / 3, length: content.utf16Length / 3)
        try tendrilTree.delete(range: nsRange)
        let range = Range(nsRange, in: content)!
        var hollowContent = content
        hollowContent.removeSubrange(range)
        #expect(tendrilTree.string == hollowContent)
        tendrilTree.verifyInvariants()
    }

    @Test("Delete Zero Length", arguments: prefixes, suffixes)
    func testDeleteZeroLength(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.delete(range: NSRange(location: 0, length: 0))
        try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length / 3, length: 0))
        try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length / 2, length: 0))
        try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length, length: 0))
        #expect(tendrilTree.string == prefix + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Delete Whole Length", arguments: prefixes, suffixes)
    func testDeleteWholeLength(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.delete(range: NSRange(location: 0, length: (prefix + suffix).utf16Length))
        #expect(tendrilTree.string.isEmpty)
        tendrilTree.verifyInvariants()
    }

    @Test("Delete a whole line")
    func testDeleteWholeLine() throws {
        let tendrilTree = TendrilTree(content: "Line 1\nLine 2\nLine 3")
        try tendrilTree.delete(range: NSRange(location: 0, length: 7)) // Delete "Line 1\n"
        #expect(tendrilTree.string == "Line 2\nLine 3")
        tendrilTree.verifyInvariants()
    }

    @Test("Out of bounds deletion throws error")
    func testOutOfBoundsDelete() {
        let tendrilTree = TendrilTree(content: "Hello World")
        #expect(throws: TendrilTreeError.invalidDeleteRange) {
            try tendrilTree.delete(range: NSRange(location: 50, length: 3))
        }
    }
    
    @Test func testDeleteNewlineInMiddle() throws {
        let tendrilTree = TendrilTree(content: "a\nc\nd\nf")
        try tendrilTree.delete(range: NSRange(location: 3, length: 1))
        #expect(tendrilTree.string == "a\ncd\nf")
        tendrilTree.verifyInvariants()
    }
    
    @Test("Delete every span of 100 lines")
    func testDeleteEverySpanOf100Lines() throws {
        let content = String(repeating: "a\nbc\ndefgh\n\ni\nj\n\n\n\nklmnopqrstuv\nwxyz", count: 10)
        for i in 0...content.count-1 {
            for j in 1...(content.count-i) {
                let tendrilTree = TendrilTree(content: content)
                try tendrilTree.delete(range: NSRange(location: i, length: j))
                tendrilTree.verifyInvariants()
            }
        }
    }
}
