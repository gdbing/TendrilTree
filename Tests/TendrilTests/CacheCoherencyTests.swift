//
//  CacheCoherencyTests.swift
//  TendrilTree
//
//  Created by o3-mini on 2025-05-01.
//
// Tests the proper invalidation and re‐population of internal caches
// (cacheString and cacheHeight) during modifying operations.

import Foundation
import Testing
@testable import TendrilTree

@Suite final class CacheCoherencyTests {

    @Test("Cache is invalidated after insertion")
    func testCacheInvalidationAfterInsertion() throws {
        // Create a tree with multiple lines.
        let tree = TendrilTree(content: "Line 1\nLine 2\nLine 3\n")

        // Force the caching by requesting string and height.
        _ = tree.string            // populates cacheString in root
        _ = tree.root.height       // populates cacheHeight

        // Confirm caches are populated.
        #expect(tree.root.cacheString != nil, "Expected cacheString to be populated")
        #expect(tree.root.cacheHeight != nil, "Expected cacheHeight to be populated")

        // Now perform an insertion.
        try tree.insert(content: "Inserted\n", at: 7)

        // The insert operation should have reset the caches.
        #expect(tree.root.cacheString == nil, "Cache string was not invalidated after insert")
        #expect(tree.root.cacheHeight == nil, "Cache height was not invalidated after insert")

        // Optionally, accessing tree.string again causes caches to be repopulated.
        _ = tree.string
        #expect(tree.root.cacheString != nil, "Cache string should be repopulated after access")
    }

    @Test("Cache is invalidated after deletion")
    func testCacheInvalidationAfterDeletion() throws {
        let tree = TendrilTree(content: "Line 1\nLine 2\nLine 3\n")

        // Force caching.
        _ = tree.string
        _ = tree.root.height

        // Verify that caches are populated.
        #expect(tree.root.cacheString != nil, "Expected cacheString to be populated")
        #expect(tree.root.cacheHeight != nil, "Expected cacheHeight to be populated")

        // Delete a portion (for example, remove part of "Line 2\n").
        try tree.delete(range: NSRange(location: 7, length: 7))

        // Caches must be invalidated by the deletion.
        #expect(tree.root.cacheString == nil, "Cache string was not invalidated after deletion")
        #expect(tree.root.cacheHeight == nil, "Cache height was not invalidated after deletion")
    }

    @Test("Cache coherency during multiple operations")
    func testCacheCoherencyMultipleOperations() throws {
        let tree = TendrilTree(content: "Line A\nLine B\nLine C\nLine D\n")

        // Prime the caches.
        _ = tree.string
        _ = tree.root.height

        // Insertion should clear caches.
        try tree.insert(content: "X\n", at: 7)
        #expect(tree.root.cacheString == nil, "After insert, cacheString should be nil")
        #expect(tree.root.cacheHeight == nil, "After insert, cacheHeight should be nil")

        // Access the tree again so caches are re-populated.
        _ = tree.string
        _ = tree.root.height
        #expect(tree.root.cacheString != nil, "Cache string should be repopulated")
        #expect(tree.root.cacheHeight != nil, "Cache height should be repopulated")

        // Then deletion should clear caches once more.
        try tree.delete(range: NSRange(location: 0, length: 7))
        #expect(tree.root.cacheString == nil, "After deletion, cacheString should be nil")
        #expect(tree.root.cacheHeight == nil, "After deletion, cacheHeight should be nil")

        // Finally, test a join operation between two nodes.
        guard let (node1, _) = Node.parse("Segment1\nSegment2\n"),
              let (node2, _) = Node.parse("Segment3\nSegment4\n")
        else {
            Issue.record("Failed to parse nodes for join test")
            return
        }
        // Prime caches on the individual nodes.
        _ = node1.string
        _ = node2.string

        let joined = Node.join(node1, node2)
        guard let joinedNode = joined else {
            Issue.record("Join resulted in nil")
            return
        }
        // The join operation is expected to call balance(), which resets caches.
        #expect(joinedNode.cacheString == nil, "After join, cacheString should be nil")
        #expect(joinedNode.cacheHeight == nil, "After join, cacheHeight should be nil")
    }

    @Test("Height cache is invalidated manually")
    func testHeightCacheInvalidation() {
        guard let (node, _) = Node.parse("Test\nCache\n") else {
            Issue.record("Failed to parse node")
            return
        }
        // Compute the height to populate the cache.
        let initialHeight = node.height
        #expect(node.cacheHeight == initialHeight, "Cache height should be set to computed value")

        // Manually reset the cache.
        node.resetCache()
        #expect(node.cacheHeight == nil, "Cache height should be nil after reset")
    }
}
