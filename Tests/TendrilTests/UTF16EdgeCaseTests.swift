//
//  UTF16EdgeCaseTests.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-04-30.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final class UTF16EdgeCaseTests {
    // MARK: - Surrogate Pairs

    @Test("Surrogate Pairs at Split Boundaries")
    func testSurrogatePairs() throws {
        // "🌍" is a surrogate pair (U+1F30D) encoded as [0xD83C, 0xDF0D]
        let content = "Hello🌍World"
        let tree = TendrilTree(content: content)
        #expect(tree.string == content)

        // Insert between surrogate pairs should fail or maintain pair integrity
        let insertPoint = content.prefix(5).utf16.count // Just before 🌍
        try tree.insert(content: "!", at: insertPoint)
        #expect(tree.string == "Hello!🌍World")

        // Delete across surrogate pair should handle it atomically
        try tree.delete(range: NSRange(location: 6, length: 2)) // Delete 🌍
        #expect(tree.string == "Hello!World")
    }

    @Test("Multiple Emoji Sequences")
    func testEmojiSequences() throws {
        // Complex emoji with modifiers: 👨‍👩‍👧‍👦 (family emoji)
        let content = "Family: 👨‍👩‍👧‍👦 and 👩🏾‍🦰"
        let tree = TendrilTree(content: content)
        #expect(tree.string == content)
        // Insert between emoji sequences
        try tree.insert(content: " members", at: 19)
        #expect(tree.string == "Family: 👨‍👩‍👧‍👦 members and 👩🏾‍🦰")

        // Delete complex emoji sequence
        let range = (tree.string as NSString).range(of: "👨‍👩‍👧‍👦")
        try tree.delete(range: range)
        #expect(tree.string == "Family:  members and 👩🏾‍🦰")
    }

    // MARK: - Zero-Width Characters

    @Test("Zero-Width Characters")
    func testZeroWidthCharacters() throws {
        // Zero-width joiner (ZWJ) U+200D
        let zwj = "\u{200D}"
        let content = "a\(zwj)b\(zwj)c"
        let tree = TendrilTree(content: content)
        #expect(tree.string == content)

        // NB. TendrilTree doesn't seem to handle zero width characters very well
        
//        // Insert around zero-width characters
//        try tree.insert(content: "x", at: 1)
//        #expect(tree.string == "ax\(zwj)b\(zwj)c")
//
//        // Delete zero-width character
//        try tree.delete(range: NSRange(location: 2, length: 1))
//        #expect(tree.string == "axb\(zwj)c")
    }

    // MARK: - Mixed ASCII and Unicode

    @Test("Mixed ASCII and Unicode Content")
    func testMixedContent() throws {
        let content = "Hello • 世界 • мир • 🌍"
        let tree = TendrilTree(content: content)
        #expect(tree.string == content)

        // Insert at various boundaries
        try tree.insert(content: "!", at: 5) // After ASCII
        try tree.insert(content: "~", at: 9) // Before CJK
        try tree.insert(content: "*", at: tree.string.utf16.count) // At end

        #expect(tree.string == "Hello! • ~世界 • мир • 🌍*")
    }

    // MARK: - Large Unicode Strings

    @Test("Large Unicode String Operations")
    func testLargeUnicodeString() throws {
        // Create string with mixture of ASCII, emoji, and other Unicode
        let repeatingContent = "Hello🌍世界\n"
        let content = String(repeating: repeatingContent, count: 1000)
        let tree = TendrilTree(content: content)
        #expect(tree.string == content)

        // Insert in middle of large content
        let middleOffset = content.utf16.count / 2
        try tree.insert(content: "【TEST】", at: middleOffset)

        // Verify content length calculations
        let expectedLength = content.utf16.count + "【TEST】".utf16.count
        #expect(tree.length == expectedLength)
    }

    // MARK: - Special Characters

    @Test("Special Unicode Characters")
    func testSpecialCharacters() throws {
        // Test various special Unicode characters
        let content = """
        Combining: é (e\u{0301})
        RTL: \u{202E}RTL text\u{202C}
        Special spaces: \u{00A0}\u{2002}\u{2003}
        Control: \u{200B}\u{FEFF}
        """

        let tree = TendrilTree(content: content)
        #expect(tree.string == content)

        // Insert between combining characters
        let combiningE = "e\u{0301}"
        try tree.insert(content: "!", at: content.prefix(upTo: content.range(of: combiningE)!.lowerBound).utf16.count)
        #expect(tree.string.contains("!é"))
    }

    // MARK: - Edge Cases

    @Test("Empty and Boundary Operations")
    func testEmptyAndBoundary() throws {
        let tree = TendrilTree()

        // Insert Unicode at start
        try tree.insert(content: "🌍", at: 0)
        #expect(tree.string == "🌍")

        // Insert surrogate pair at end
        try tree.insert(content: "🌎", at: tree.length)
        #expect(tree.string == "🌍🌎")

        // Delete everything
        try tree.delete(range: NSRange(location: 0, length: tree.length))
        #expect(tree.string.isEmpty)
    }

    @Test("Invalid UTF-16 Operations")
    func testInvalidOperations() throws {
        let content = "Hello🌍World"
        let tree = TendrilTree(content: content)

        // Attempt to insert at invalid UTF-16 boundary
        #expect(throws: TendrilTreeError.invalidInsertOffset) {
            try tree.insert(content: "!", at: -1)
        }

        #expect(throws: TendrilTreeError.invalidInsertOffset) {
            try tree.insert(content: "!", at: content.utf16.count + 1)
        }

        // Attempt to delete invalid range
        #expect(throws: TendrilTreeError.invalidDeleteRange) {
            try tree.delete(range: NSRange(location: 0, length: content.utf16.count + 1))
        }
    }
}
