//
//  OutlinerStage4Tests.swift
//  TendrilTree
//
//  Created by Gemini Pro 2.5 on 2025-05-02.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final class OutlinerStage4Tests {

    // Helper to verify indentations using depth(at:)
    // Checks the indentation at the beginning of each line's visible content
    private func verifyIndentations(in tree: TendrilTree, expectedIndents: [Int], file: StaticString = #file, line: Int = #line) throws {
        var currentOffset = 0
        var lineIndex = 0
        var lines = tree.string.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) + "\n" }
         // Handle potential empty last line correctly if tree.string doesn't end with \n
        if !tree.string.hasSuffix("\n") && !lines.isEmpty {
            lines[lines.count - 1] = String(lines[lines.count - 1].dropLast())
        }


        guard lines.count == expectedIndents.count else {
            Issue.record("Mismatch between number of lines (\(lines.count)) and expected indentations (\(expectedIndents.count))")
            return
        }

        for lineContent in lines {
            guard !lineContent.isEmpty else { // Skip checks for potentially empty trailing line representation
                 if lineIndex == expectedIndents.count - 1 && expectedIndents[lineIndex] == 0 {
                    // Allow trailing empty line with 0 indent if expected
                 } else {
                    Issue.record("Unexpected empty line content at index \(lineIndex)")
                 }
                 lineIndex += 1
                 continue
            }
            // Check depth at the start of the visible line content
            if currentOffset < tree.length { // Only check valid offsets
                 let depth = try tree.depth(at: currentOffset)
                 #expect(depth == expectedIndents[lineIndex], "Line \(lineIndex) expected indent \(expectedIndents[lineIndex]), got \(depth)")
            } else if currentOffset == tree.length && lineContent == "\n" {
                // Special case: last line might just be a newline, depth query at length is invalid, but we check count match above
                 #expect(expectedIndents[lineIndex] == 0, "Expected indent 0 for trailing newline") // Assume 0 indent for implicit trailing newline leaf
            }

            currentOffset += lineContent.utf16Length
            lineIndex += 1
        }
         tree.verifyInvariants() // Also run structural checks
    }

    // MARK: - Indent Tests

    @Test("Indent single line")
    func testIndentSingleLine() throws {
        let initialContent = "Line 1"
        let tree = TendrilTree(content: initialContent)
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        try tree.indent(range: NSRange(location: 0, length: initialLength))

        #expect(tree.string == initialContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "\tLine 1")
        #expect(tree.fileLength == initialFileLength + 1)
        try verifyIndentations(in: tree, expectedIndents: [1])
    }

    @Test("Indent multiple lines")
    func testIndentMultipleLines() throws {
        let initialContent = "Line 1\nLine 2\nLine 3"
        let tree = TendrilTree(content: initialContent)
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Indent lines 2 and 3 (range covers part of Line 2 and Line 3)
        let rangeStart = "Line 1\n".utf16Length
        let rangeLength = "Line 2\nLine 3".utf16Length
        try tree.indent(range: NSRange(location: rangeStart, length: rangeLength))

        #expect(tree.string == initialContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\n\tLine 2\n\tLine 3")
        #expect(tree.fileLength == initialFileLength + 2) // +1 tab for Line 2, +1 for Line 3
        try verifyIndentations(in: tree, expectedIndents: [0, 1, 1])
    }

    @Test("Indent with existing indentation")
    func testIndentWithExisting() throws {
        let initialFileContent = "Line 1\n\tLine 2\n\t\tLine 3"
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Line 1\nLine 2\nLine 3"
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Indent all lines
        try tree.indent(range: NSRange(location: 0, length: initialLength))

        #expect(tree.string == initialVisibleContent)
        #expect(tree.length == initialLength)
        let expectedFileString = "\tLine 1\n\t\tLine 2\n\t\t\tLine 3"
        #expect(tree.fileString == expectedFileString)
        #expect(tree.fileLength == initialFileLength + 3) // +1 tab for each of the 3 lines
        try verifyIndentations(in: tree, expectedIndents: [1, 2, 3])
    }

    @Test("Indent partial overlap affects whole leaf")
    func testIndentPartialOverlap() throws {
        let initialContent = "Line 1\nLine 2 is longer\nLine 3"
        let tree = TendrilTree(content: initialContent)
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Range covers just "ine 2" within the second line
        let rangeStart = "Line 1\nL".utf16Length
        let rangeLength = "ine 2".utf16Length
        try tree.indent(range: NSRange(location: rangeStart, length: rangeLength))

        // Expect the entire second line (leaf) to be indented
        #expect(tree.string == initialContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\n\tLine 2 is longer\nLine 3")
        #expect(tree.fileLength == initialFileLength + 1)
        try verifyIndentations(in: tree, expectedIndents: [0, 1, 0])
    }

    @Test("Indent empty range")
    func testIndentEmptyRange() throws {
        let initialContent = "Line 1\n\tLine 2"
        let tree = TendrilTree(content: initialContent)
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        try tree.indent(range: NSRange(location: 7, length: 0)) // Empty range in middle

        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\n\t\tLine 2")
        #expect(tree.fileLength == initialFileLength + 1)
        try verifyIndentations(in: tree, expectedIndents: [0, 2])
    }

    // MARK: - Outdent Tests

    @Test("Outdent single line")
    func testOutdentSingleLine() throws {
        let initialFileContent = "\tLine 1"
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Line 1"
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        try tree.outdent(range: NSRange(location: 0, length: initialLength))

        #expect(tree.string == initialVisibleContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1")
        #expect(tree.fileLength == initialFileLength - 1)
        try verifyIndentations(in: tree, expectedIndents: [0])
    }

    @Test("Outdent multiple lines")
    func testOutdentMultipleLines() throws {
        let initialFileContent = "\tLine 1\n\t\tLine 2\n\tLine 3"
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Line 1\nLine 2\nLine 3"
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Outdent lines 1 and 2
        let rangeStart = 0
        let rangeLength = "Line 1\nLine 2".utf16Length
        try tree.outdent(range: NSRange(location: rangeStart, length: rangeLength))

        #expect(tree.string == initialVisibleContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\n\tLine 2\n\tLine 3") // L1: 1->0, L2: 2->1, L3: unchanged
        #expect(tree.fileLength == initialFileLength - 2) // -1 tab for L1, -1 for L2
        try verifyIndentations(in: tree, expectedIndents: [0, 1, 1])
    }

    @Test("Outdent clamps at zero")
    func testOutdentClampsAtZero() throws {
        let initialFileContent = "Line 1\n\tLine 2" // L1 indent 0, L2 indent 1
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Line 1\nLine 2"
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Outdent all lines
        try tree.outdent(range: NSRange(location: 0, length: initialLength))

        #expect(tree.string == initialVisibleContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\nLine 2") // L1: 0->0, L2: 1->0
        #expect(tree.fileLength == initialFileLength - 1) // Only L2 loses a tab
        try verifyIndentations(in: tree, expectedIndents: [0, 0])
    }

     @Test("Outdent partial overlap affects whole leaf")
     func testOutdentPartialOverlap() throws {
        let initialFileContent = "\tLevel 1\n\t\tLevel 2 is longer\n\tLevel 3"
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Level 1\nLevel 2 is longer\nLevel 3"
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        // Range covers just "vel 2" within the second line
        let rangeStart = "Level 1\nLe".utf16Length
        let rangeLength = "vel 2".utf16Length
        try tree.outdent(range: NSRange(location: rangeStart, length: rangeLength))

        // Expect the entire second line (leaf) to be outdented
        #expect(tree.string == initialVisibleContent)
        #expect(tree.length == initialLength)
        #expect(tree.fileString == "\tLevel 1\n\tLevel 2 is longer\n\tLevel 3") // L1: 1, L2: 2->1, L3: 1
        #expect(tree.fileLength == initialFileLength - 1) // L2 loses one tab
        try verifyIndentations(in: tree, expectedIndents: [1, 1, 1])
     }

    @Test("Outdent empty range")
    func testOutdentEmptyRange() throws {
        let initialFileContent = "Line 1\n\tLine 2"
        let tree = TendrilTree(content: initialFileContent)
        let initialLength = tree.length
        let initialFileLength = tree.fileLength

        try tree.outdent(range: NSRange(location: 7, length: 0)) // Empty range in middle

        #expect(tree.length == initialLength)
        #expect(tree.fileString == "Line 1\nLine 2") // File string unchanged
        #expect(tree.fileLength == initialFileLength - 1)
        try verifyIndentations(in: tree, expectedIndents: [0, 0])
    }

    // MARK: - Edge Cases & Errors

    @Test("Indent/Outdent at start/end of document")
    func testIndentOutdentAtBoundaries() throws {
        let initialFileContent = "\tLine 1\nLine 2\n\tLine 3"
        let tree = TendrilTree(content: initialFileContent)
        let initialVisibleContent = "Line 1\nLine 2\nLine 3"
        let initialLength = tree.length

        // Indent first line
        try tree.indent(range: NSRange(location: 0, length: 0))
        #expect(tree.fileString == "\t\tLine 1\nLine 2\n\tLine 3")
        try verifyIndentations(in: tree, expectedIndents: [2, 0, 1])

        // Outdent last line
        let lastLineStartOffset = "Line 1\nLine 2\nLine 3".utf16Length
        try tree.outdent(range: NSRange(location: lastLineStartOffset, length: 0))
        #expect(tree.fileString == "\t\tLine 1\nLine 2\nLine 3") // L3: 1->0
        try verifyIndentations(in: tree, expectedIndents: [2, 0, 0])

        #expect(tree.string == initialVisibleContent) // Visible content still the same
        #expect(tree.length == initialLength)
    }

     @Test("Indent/Outdent entire document")
     func testIndentOutdentEntireDocument() throws {
         let initialFileContent = "L0\n\tL1\n\t\tL2"
         let tree = TendrilTree(content: initialFileContent)
         let initialVisibleContent = "L0\nL1\nL2"
         let initialLength = tree.length

         // Indent all
         try tree.indent(range: NSRange(location: 0, length: initialLength))
         #expect(tree.fileString == "\tL0\n\t\tL1\n\t\t\tL2")
         try verifyIndentations(in: tree, expectedIndents: [1, 2, 3])

         // Outdent all twice
         try tree.outdent(range: NSRange(location: 0, length: initialLength))
         #expect(tree.fileString == "L0\n\tL1\n\t\tL2") // Back to original
         try verifyIndentations(in: tree, expectedIndents: [0, 1, 2])

         try tree.outdent(range: NSRange(location: 0, length: initialLength))
         #expect(tree.fileString == "L0\nL1\n\tL2") // L1 clamped, L2 decreased
         try verifyIndentations(in: tree, expectedIndents: [0, 0, 1])

         #expect(tree.string == initialVisibleContent) // Visible content still the same
         #expect(tree.length == initialLength)
     }

    @Test("Invalid range throws error")
    func testInvalidRange() throws {
        let tree = TendrilTree(content: "Line 1\nLine 2")

        // Location out of bounds
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.indent(range: NSRange(location: tree.length + 1, length: 1))
        }
        #expect(throws: TendrilTreeError.invalidRange) {
             try tree.outdent(range: NSRange(location: tree.length + 1, length: 1))
        }

        // Location + length out of bounds
        #expect(throws: TendrilTreeError.invalidRange) {
            try tree.indent(range: NSRange(location: 0, length: tree.length + 1))
        }
         #expect(throws: TendrilTreeError.invalidRange) {
             try tree.outdent(range: NSRange(location: 0, length: tree.length + 1))
         }

         // Check if the state is unchanged after error
         let originalFileString = tree.fileString
         let originalLength = tree.length
         do {
             try tree.indent(range: NSRange(location: tree.length, length: 1)) // Invalid range: starts exactly at end
         } catch TendrilTreeError.invalidRange {
            // Expected error
         } catch {
            Issue.record("Caught unexpected error: \(error)")
         }
         #expect(tree.fileString == originalFileString)
         #expect(tree.length == originalLength)
         try verifyIndentations(in: tree, expectedIndents: [0, 0])
    }
}
