import Foundation
import Testing
@testable import TendrilTree

@Suite final class ParsingTests {
    @Test("Parsing", arguments: [ "", "abcd", "Hello, World\n", "Hello\nWorld!\n", "abc\ndef\ng\nhijkl\nmnop" ])
    func testParse(content: String) throws {
        let tendrilTree = TendrilTree(content: content)
        #expect(tendrilTree.string == content)
        tendrilTree.verifyInvariants()
    }
}
// MARK: - Insert

let prefixes = [ "Hello\n", "Hello", "Hell\nOh", "He\nEll\nOh\n", "", "\n", "\n\n\n" ]
let suffixes = [ "World\n", "World", "Whirl\nEd", "\nWere\ned\n", "", "\n", "\n\n\n" ]

@Suite final actor InsertionTests {
    @Test("Insert Empty String", arguments: prefixes, suffixes)
    func testInsertEmptyString(prefix: String, suffix: String) throws {
        let tendrilTree = TendrilTree(content: prefix + suffix)
        try tendrilTree.insert(content: "", at: prefix.utf16Length)
        #expect(tendrilTree.string == prefix + suffix)
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
// MARK: - Node

@Test func testNodeAtEnd() {
    var node: Node = Leaf("abcd")
    node = node.insert(content: "zzz\n", at: 0)
    node = node.insert(content: "xxx\n", at: 0)
    #expect(node.string == "xxx\nzzz\nabcd")
    let nodeAt = node.nodeAt(offset: 4)
    #expect(nodeAt?.string == "zzz\n")
}

extension TendrilTree {
    func verifyInvariants() {
        #expect(length == string.utf16Length)
        root.verifyInvariants()
    }
}

extension Node {
    func verifyInvariants() {
        if let leafSelf = self as? Leaf {
            leafSelf.verifyLeafInvariants()
            return
        }
        #expect(left != nil, "left branch missing")
        #expect(right != nil, "right branch missing")
        #expect(isBalanced())
        #expect(weight == left?.calculateWeight())
        left?.verifyInvariants()
        right?.verifyInvariants()
    }

    private func isBalanced() -> Bool {
        let heightDiff = (left?.height ?? 0) - (right?.height ?? 0)
        if heightDiff <= 1 && heightDiff >= -1 {
            return true
        }
        return false
    }

    private func calculateWeight() -> Int {
        if let leafSelf = self as? Leaf {
            return leafSelf.content.utf16Length
        }
        return (left?.calculateWeight() ?? 0) + (right?.calculateWeight() ?? 0)
    }
}

extension Leaf {
    func verifyLeafInvariants() {
        #expect(!content.dropLast().contains("\n"), "content contains newlines")
        #expect(content.last == "\n")
        #expect(left == nil, "leaf has children")
        #expect(right == nil, "leaf has children")
        #expect(weight == content.utf16Length, "weight doesn't match content length")
    }
}
