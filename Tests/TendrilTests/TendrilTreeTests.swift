import Foundation
import Testing
@testable import TendrilTree

let prefixes = [ "Hello\n", "Hello", "Hell\nOh", "He\nEll\nOh\n", "", "\n", "\n\n\n" ]
let suffixes = [ "World\n", "World", "Whirl\nEd", "\nWere\ned\n", "", "\n", "\n\n\n" ]

@Suite final class ParsingTests {
    @Test("Parsing", arguments: [ "", "abcd", "Hello, World\n", "Hello\nWorld!\n", "abc\ndef\ng\nhijkl\nmnop" ])
    func testParse(content: String) throws {
        let tendrilTree = TendrilTree(content: content)
        #expect(tendrilTree.string == content)
        tendrilTree.verifyInvariants()
    }
}

// MARK: - Node

@Test func testNodeAtEnd() {
    var node: Node = Leaf("abcd")
    node = node.insert(content: "zzz\n", at: 0)
    node = node.insert(content: "xxx\n", at: 0)
    #expect(node.string == "xxx\nzzz\nabcd")
    let nodeAt = node.leafAt(offset: 4)
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
