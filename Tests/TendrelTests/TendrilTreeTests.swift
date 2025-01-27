import Foundation
import Testing
@testable import TendrilTree

@Test func testParse() throws {
    let content = "Hello\nWorld!\n"
    let tendrilTree = TendrilTree(content: content)
    #expect(tendrilTree.string == content)
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

// Test inserting into an empty rope
@Test func testInsertionIntoEmptyRope() throws {
    let content = "Hello\nWorld!\n"
    let tendrilTree = TendrilTree()
    try tendrilTree.insert(content: content, at: 0)
    #expect(tendrilTree.string == content)
}

// Test appending to existing content
@Test func testAppendToRope() throws {
    let tendrilTree = TendrilTree(content: "Hello")
    try tendrilTree.insert(content: " World", at: 5)
    #expect(tendrilTree.string == "Hello World")
}

// Test inserting in the middle of the content
@Test func testInsertionInMiddle() throws {
    let tendrilTree = TendrilTree(content: "Hello World")
    try tendrilTree.insert(content: ",", at: 5)
    #expect(tendrilTree.string == "Hello, World")
}

// Test inserting at boundaries (beginning and end)
@Test func testInsertionAtBoundaries() throws {
    let tendrilTree = TendrilTree(content: "Hello")
    try tendrilTree.insert(content: "Start ", at: 0)
    #expect(tendrilTree.string == "Start Hello")

    try tendrilTree.insert(content: " End", at: "Start Hello".utf16Length)
    #expect(tendrilTree.string == "Start Hello End")
}

// Test deleting a portion of content
@Test func testDeleteContent() throws {
    let tendrilTree = TendrilTree(content: "Hello World")
    try tendrilTree.delete(range: NSRange(location: 5, length: 1))
    #expect(tendrilTree.string == "HelloWorld")
}

// Test deleting a whole line
@Test func testDeleteWholeLine() throws {
    let tendrilTree = TendrilTree(content: "Line 1\nLine 2\nLine 3")
    try tendrilTree.delete(range: NSRange(location: 0, length: 7)) // Delete "Line 1\n"
    #expect(tendrilTree.string == "Line 2\nLine 3")
}

// Test deleting across line boundaries
@Test func testDeleteAcrossLines() throws {
    let tendrilTree = TendrilTree(content: "Line 1\nLine 2\nLine 3")
    try tendrilTree.delete(range: NSRange(location: 5, length: 8)) // Delete across "1\nLine 2"
    #expect(tendrilTree.string == "Line \nLine 3")
}

// Test edge case of deleting at the start of the tendrilTree
@Test func testDeleteAtStart() throws {
    let tendrilTree = TendrilTree(content: "Text To Delete")
    try tendrilTree.delete(range: NSRange(location: 0, length: 5)) // Remove "Text "
    #expect(tendrilTree.string == "To Delete")
}

// Test inserting large content
@Test func testInsertLargeContent() throws {
    let tendrilTree = TendrilTree(content: "Short")
    let longText = String(repeating: "LongContent-", count: 1000)
    try tendrilTree.insert(content: longText, at: 5)
    #expect(tendrilTree.string == "Short" + longText)
}

@Test func testNodeAtEnd() {
    let node = Node("abcd")
    node.insert(content: "zzz\n", at: 0)
    node.insert(content: "xxx\n", at: 0)
    #expect(node.toString() == "xxx\nzzz\nabcd")
    let nodeAt = node.nodeAt(offset: 4)
    #expect(nodeAt?.toString() == "zzz\n")
}

// Test out-of-bounds insert
@Test func testOutOfBoundsInsert() {
    let content = "Bounds Check"
    let tendrilTree = TendrilTree(content: content)
    #expect(throws: TendrilTreeError.invalidInsertOffset) {
        try tendrilTree.insert(content: "!", at: content.utf16Length + 1)
    }
}

// Test invalid delete (out of bounds)
@Test func testOutOfBoundsDelete() {
    let tendrilTree = TendrilTree(content: "Hello World")
    #expect(throws: TendrilTreeError.invalidDeleteRange) {
        try tendrilTree.delete(range: NSRange(location: 50, length: 3))
    }
}

