//
//  OutlinerStage3Tests.swift
//  TendrilTree
//
//  Created by o4-mini on 2025-05-02.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final class OutlinerStage3Tests {
    
    // Helper to round-trip parse & serialize
    @Test("Round-trip fileString == input")
    func testFileStringRoundTrip() throws {
        let input =
        "\t\tFirst line\n" +
        "\tSecond line\n" +
        "Third line\n"
        let tree = TendrilTree(content: input)
        #expect(tree.fileString == input,
                "fileString must exactly match the original text with tabs")
        // visible string must have no tabs
        let expectedVisible = "First line\nSecond line\nThird line\n"
        #expect(tree.string == expectedVisible,
                "string must drop all leading tabs")
    }
    
    @Test("fileLength accounts for tabs")
    func testFileLengthIncludesTabs() throws {
        let input = "\tA\n\t\tB\nC\n"
        let tree = TendrilTree(content: input)
        let countTabs = input.filter { $0 == "\t" }.utf16.count
        #expect(tree.fileLength == tree.string.utf16.count + countTabs)
    }
    
    @Test("length unaffected by tabs")
    func testVisibleLengthUnaffected() throws {
        let input = "\tHello\nWorld\n"
        let tree = TendrilTree(content: input)
        #expect(tree.length == tree.string.utf16.count,
                "length must equal count of visible string")
    }
    
    @Test("depth(at:) returns correct indentation")
    func testDepthAtOffset() throws {
        // Setup a tree with known indentation per line:
        //   line0 indentation=0: "L0\n"
        //   line1 indentation=1: "L1\n"
        //   line2 indentation=2: "L2\n"
        let raw =
        "L0\n" +
        "\tL1\n" +
        "\t\tL2\n"
        let tree = TendrilTree(content: raw)
        // Compute visible string offsets:
        // visible = "L0\nL1\nL2"
        let offsets = [0, 2,    // within "L0\n"
                       3, 5,    // within "L1\n"
                       6, 8]    // within "L2\n"
        let expected = [0, 0,  // first line indent 0
                        1, 1,  // second line indent 1
                        2, 2]  // third line indent 2
        for (i, off) in offsets.enumerated() {
            #expect(try tree.depth(at: off) == expected[i],
                    "depth(at:\(off)) should be \(expected[i])")
        }
    }
    
    @Test("depth(at:) at boundary cases")
    func testDepthInvalidOffsets() {
        let tree = TendrilTree(content: "A\nB\n")
        #expect(throws: TendrilTreeError.invalidQueryOffset) {
            _ = try tree.depth(at: -1)
        }
        #expect(throws: TendrilTreeError.invalidQueryOffset) {
            _ = try tree.depth(at: tree.length + 1)
        }
    }
}
