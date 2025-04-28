//
//  TendrilTree.swift
//  TendrilTree
//
//  Provides the main public interface for the TendrilTree rope data structure.
//  Manages the root node and overall state, handling UTF-16 based operations.
//
//  Key Responsibilities:
//
//  - **Root Management:** Holds the `root` node (always non-nil, initialized empty).
//  - **UTF-16 Interface:** Public API operates exclusively with UTF-16 offsets/ranges.
//  - **Length Tracking:** Maintains the total UTF-16 `length` of the content.
//  - **API Contract:** Enforces valid offsets/ranges, throwing `TendrilTreeError`.
//  - **Initialization:** Can be initialized from a String, automatically parsing it
//    into paragraph nodes using `Node.parse`.
//  - **Insertion Handling:**
//      - Breaks multi-line strings into individual paragraphs for insertion.
//      - May rebuild the entire tree for very large insertions relative to
//        current content size for performance.
//  - **Deletion Handling:** Delegates validated deletion ranges to the `root` node.
//

import Foundation

public class TendrilTree {
    internal var root: Node = Node("\n")
    internal var length: Int = 0

    public var string: String {
        return String(root.string.dropLast())
    }

    public init() { }
    
    public init(content: String) {
        guard !content.isEmpty else { return }

        if let (root, length) = Node.parse(content) {
            self.root = root
            self.length = length
        }
    }

    public func insert(content: String, at offset: Int) throws {
        // Check if the offset is within bounds
        guard offset >= 0 && offset <= length else {
            throw TendrilTreeError.invalidInsertOffset
        }

        let insertLength = content.utf16Length
        guard insertLength > 0 else {
            return
        }

        if insertLength > self.length * 10 {
            let str = self.string
            let idx = str.charIndex(utf16Index: offset)!
            let prefix = str.prefix(upTo: idx)
            let suffix = str.suffix(from: idx)

            let combinedContent = prefix + content + suffix

            if let (root, length) = Node.parse(combinedContent) {
                self.root = root
                self.length = length
            }
            return
        }

        var relativeOffset = offset
        var remainder: any StringProtocol = content
        var idx = remainder.startIndex
        while idx != remainder.endIndex {
            if let newLineIdx = remainder.firstIndex(of: "\n") {
                idx = remainder.index(newLineIdx, offsetBy: 1)
            } else {
                idx = remainder.endIndex
            }
            let s = String(remainder.prefix(upTo: idx))
            self.root = self.root.insert(content: s, at: relativeOffset)
            remainder = remainder.suffix(from: idx)
            relativeOffset += s.utf16Length
        }

        self.length += content.utf16Length
    }

    public func delete(range: NSRange) throws {
        // Check if the range is within bounds
        guard range.location >= 0 && range.length >= 0 && range.location + range.length <= length else {
            throw TendrilTreeError.invalidDeleteRange
        }

        self.root = self.root.delete(location: range.location, length: range.length) ?? Node("\n")
        self.length -= range.length
    }
}
