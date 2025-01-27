import Foundation
import Testing
@testable import TendrilTree


@Test("Parsing", arguments: [ "", "abcd", "Hello, World\n", "Hello\nWorld!\n", "abc\ndef\ng\nhijkl\nmnop" ])
func testParse(content: String) throws {
    let tendrilTree = TendrilTree(content: content)
    #expect(tendrilTree.string == content)
}

// MARK: - Insert

let prefixes = [ "Hello\n", "Hello", "Hell\nOh", "He\nEll\nOh\n", "", "\n", "\n\n\n" ]
let suffixes = [ "World\n", "World", "Whirl\nEd", "\nWere\ned\n", "", "\n", "\n\n\n" ]

@Suite struct InsertionTests {
    @Test("Insert Empty String", arguments: prefixes, suffixes)
    func testInsertEmptyString(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: "", at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + suffix)
    }

    @Test("Insert ABC", arguments: prefixes, suffixes)
    func testInsertABC(prefix: String, suffix: String) throws {
        let content = "abc"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Insert newline", arguments: prefixes, suffixes)
    func testInsertNewline(prefix: String, suffix: String) throws {
        let content = "\n"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Insert Paragraph", arguments: prefixes, suffixes)
    func testInsertParagraph(prefix: String, suffix: String) throws {
        let content = "abc\n"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Insert Multiple Paragraphs", arguments: prefixes, suffixes)
    func testInsertMultipleParagraph(prefix: String, suffix: String) throws {
        let content = "abc\ndefg\nhijk"
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Insert Large Content", arguments: prefixes, suffixes)
    func testInsertLargeContent(prefix: String, suffix: String) throws {
        let content = String(repeating: "LongContent-", count: 1000)
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Insert Large Content (Multiple Paragraphs)", arguments: prefixes, suffixes)
    func testInsertLargeContent_multipleParagraphs(prefix: String, suffix: String) throws {
        let content = String(repeating: "LongContent-", count: 1000)
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: content, at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Inserting at boundaries (beginning and end)", arguments: prefixes, suffixes)
    func testInsertionAtBoundaries(prefix: String, suffix: String) throws {
        let content = "Content"
        let tendrilTree = TendrilTree(content: content)
        try tendrilTree.insert(content: prefix, at: 0)
        #expect(tendrilTree.string == prefix + content)

        try tendrilTree.insert(content: suffix, at: (prefix + content).utf16Length)
        #expect(tendrilTree.string == prefix + content + suffix)
    }

    @Test("Out of bounds insertion throws error")
    func testOutOfBoundsInsert() {
        let content = "Bounds Check"
        let tendrilTree = TendrilTree(content: content)
        #expect(throws: TendrilTreeError.invalidInsertOffset) {
            try tendrilTree.insert(content: "!", at: content.utf16Length + 1)
        }
    }
}
// MARK: - Delete

@Test("Delete Prefix", arguments: prefixes, suffixes)
func testDeletePrefix(prefix: String, suffix: String) throws {
    let tendrilTree = TendrilTree(content: prefix + suffix)
    try tendrilTree.delete(range: NSRange(location: 0, length: prefix.utf16Length))
    #expect(tendrilTree.string == suffix)
}

@Test("Delete Suffix", arguments: prefixes, suffixes)
func testDeleteSuffix(prefix: String, suffix: String) throws {
    let tendrilTree = TendrilTree(content: prefix + suffix)
    try tendrilTree.delete(range: NSRange(location: prefix.utf16Length, length: suffix.utf16Length))
    #expect(tendrilTree.string == prefix)
}

@Test func testSpecific() throws {
    let prefix = "Hello"
    let suffix = "\nWere\ned\n"
    let tendrilTree = TendrilTree(content: prefix + suffix)
    try tendrilTree.delete(range: NSRange(location: prefix.utf16Length, length: suffix.utf16Length))
    #expect(tendrilTree.string == prefix)
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
}

@Test("Delete Zero Length", arguments: prefixes, suffixes)
func testDeleteZeroLength(prefix: String, suffix: String) throws {
    let tendrilTree = TendrilTree(content: prefix + suffix)
    try tendrilTree.delete(range: NSRange(location: 0, length: 0))
    try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length / 3, length: 0))
    try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length / 2, length: 0))
    try tendrilTree.delete(range: NSRange(location: (prefix + suffix).utf16Length, length: 0))
    #expect(tendrilTree.string == prefix + suffix)
}

@Test("Delete Whole Length", arguments: prefixes, suffixes)
func testDeleteWholeLength(prefix: String, suffix: String) throws {
    let tendrilTree = TendrilTree(content: prefix + suffix)
    try tendrilTree.delete(range: NSRange(location: 0, length: (prefix + suffix).utf16Length))
    #expect(tendrilTree.string.isEmpty)
}

@Test("Delete a whole line")
func testDeleteWholeLine() throws {
    let tendrilTree = TendrilTree(content: "Line 1\nLine 2\nLine 3")
    try tendrilTree.delete(range: NSRange(location: 0, length: 7)) // Delete "Line 1\n"
    #expect(tendrilTree.string == "Line 2\nLine 3")
}

@Test("Out of bounds deletion throws error")
func testOutOfBoundsDelete() {
    let tendrilTree = TendrilTree(content: "Hello World")
    #expect(throws: TendrilTreeError.invalidDeleteRange) {
        try tendrilTree.delete(range: NSRange(location: 50, length: 3))
    }
}

// MARK: - Node

@Test func testNodeAtEnd() {
    let node = Node("abcd")
    node.insert(content: "zzz\n", at: 0)
    node.insert(content: "xxx\n", at: 0)
    #expect(node.toString() == "xxx\nzzz\nabcd")
    let nodeAt = node.nodeAt(offset: 4)
    #expect(nodeAt?.toString() == "zzz\n")
}

