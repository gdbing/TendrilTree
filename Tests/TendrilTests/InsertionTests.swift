//
//  InsertionTests.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-04-30.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final actor InsertionTests {
    @Test("Insert Empty String", arguments: prefixes, suffixes)
    func testInsertEmptyString(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: "", at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + suffix)
        tendrilTree.verifyInvariants()
    }
    
    @Test
    func testInserthw() throws {
        let prefix = "hello\n"
        let suffix = "world\n"
        let content = "abc"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert ABC", arguments: prefixes, suffixes)
    func testInsertABC(prefix: String, suffix: String) throws {
        let content = "abc"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert newline", arguments: prefixes, suffixes)
    func testInsertNewline(prefix: String, suffix: String) throws {
        let content = "\n"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert Paragraph", arguments: prefixes, suffixes)
    func testInsertParagraph(prefix: String, suffix: String) throws {
        let content = "abc\n"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert Multiple Paragraphs", arguments: prefixes, suffixes)
    func testInsertMultipleParagraph(prefix: String, suffix: String) throws {
        let content = "abc\ndefg\nhijk"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert Large Content", arguments: prefixes, suffixes)
    func testInsertLargeContent(prefix: String, suffix: String) throws {
        let content = String(repeating: "LongContent-", count: 1000)
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Insert Large Content (Multiple Paragraphs)", arguments: prefixes, suffixes)
    func testInsertLargeContent_multipleParagraphs(prefix: String, suffix: String) throws {
        let content = String(repeating: "LongContent\n", count: 1000)
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Inserting at boundaries (beginning and end)", arguments: prefixes, suffixes)
    func testInsertionAtBoundaries(prefix: String, suffix: String) throws {
        let content = "Content"
        let tendrilTree = TendrilTree(content: content)
        try tendrilTree.insert(content: prefix, at: 0)
        #expect(tendrilTree.string == prefix + content)

        try tendrilTree.insert(content: suffix, at: (prefix + content).utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
        tendrilTree.verifyInvariants()
    }

    @Test("Out of bounds insertion throws error")
    func testOutOfBoundsInsert() {
        let content = "Bounds Check"
        let tendrilTree = TendrilTree(content: content)
        #expect(throws: TendrilTreeError.invalidInsertOffset) {
            try tendrilTree.insert(content: "!", at: content.utf16Length + 1)
            tendrilTree.verifyInvariants()
        }
    }
}
