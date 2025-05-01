//
//  ExtraPerformanceMeasurements.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-05-01.
//


import XCTest
import Foundation
@testable import TendrilTree

extension Measurements {

    // Helper to generate a simple large document.
    private func generateLargeDocument(lines: Int) -> String {
        // A simple document where each line is “Line X\n”
        return (1...lines).map { "Line \($0)\n" }.joined()
    }

    // Helper to generate a random string – only ASCII for simplicity.
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in letters.randomElement() })
    }

    // 1. Stress test with many small, random insertions and deletions.
    func testRepeatedRandomEdits() throws {
        // Start with a moderate-size document – about Moby Dick size, or smaller.
        let initialContent = generateLargeDocument(lines: 500)
        let tree = TendrilTree(content: initialContent)
        let iterations = 1000

        self.measure {
            for _ in 0..<iterations {
                // Randomly decide whether to insert or delete
                let op = Int.random(in: 0...1)
                let pos = Int.random(in: 0...tree.length)
                if op == 0 { // Insert
                    let insertLength = Int.random(in: 1...10)
                    let toInsert = randomString(length: insertLength)
                    try? tree.insert(content: toInsert, at: pos)
                } else { // Delete
                    if tree.length > 0 {
                        // Ensure deletion doesn’t run off the end.
                        let deleteLength = min(Int.random(in: 1...10), tree.length - pos)
                        try? tree.delete(range: NSRange(location: pos, length: deleteLength))
                    }
                }
            }
        }
        tree.verifyInvariants()
    }

    // 2. Stress test with repeated prepends.
    func testRepeatedPrepend() throws {
        let tree = TendrilTree(content: "Initial content\n")
        let iterations = 1000
        let contentToPrepend = "PREPEND\n"

        self.measure {
            for _ in 0..<iterations {
                try? tree.insert(content: contentToPrepend, at: 0)
            }
        }
        tree.verifyInvariants()
    }

    // 3. Stress test with repeated mid-insertions.
    func testRepeatedMidInsert() throws {
        // Start with a moderate-size document.
        let initialContent = generateLargeDocument(lines: 500)
        let tree = TendrilTree(content: initialContent)
        let iterations = 1000
        let contentToInsert = "MID\n"

        self.measure {
            for _ in 0..<iterations {
                // Insert in the middle of the current document.
                let pos = tree.length / 2
                try? tree.insert(content: contentToInsert, at: pos)
            }
        }
        tree.verifyInvariants()
    }

    // 4. Test on a much larger document to verify scalability.
    func testLargeDocumentPerformance() throws {
        // Generate a synthetic large document (e.g., 10,000 lines).
        let largeContent = generateLargeDocument(lines: 10_000)
        var tree: TendrilTree?
        self.measure {
            tree = TendrilTree(content: largeContent)
        }
//        XCTAssertEqual(tree?.string, largeContent.dropLast())
        tree?.verifyInvariants()
    }

    // 5. Stress test cache churn: alternate insertions and deletions.
    func testCacheChurn() throws {
        let tree = TendrilTree(content: generateLargeDocument(lines: 300))
        let iterations = 500

        self.measure {
            for _ in 0..<iterations {
                // Insert a short random string at a random position.
                let pos = Int.random(in: 0...tree.length)
                let toInsert = randomString(length: 5)
                try? tree.insert(content: toInsert, at: pos)

                // Delete a short range from a random position.
                if tree.length > 5 {
                    let pos2 = Int.random(in: 0...(tree.length - 5))
                    try? tree.delete(range: NSRange(location: pos2, length: 5))
                }
            }
        }
        tree.verifyInvariants()
    }
}
