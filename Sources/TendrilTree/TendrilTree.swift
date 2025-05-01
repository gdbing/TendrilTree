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
//  - **Insertion:**  Breaks strings into individual paragraphs for insertion.
//  - **Deletion:** Delegates validated deletion ranges to the `root` node.
//

import Foundation

public class TendrilTree {
    var root: Node = Leaf("\n")
    var length: Int = 0

    public var string: String {
        return String(root.string.dropLast())
    }

    public init() { }
    
    public init(content: String) {
        guard !content.isEmpty else { return }

        if let (root, length) = Node.parse(content + "\n") {
            self.root = root
            self.length = length - 1
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
        root = root.insert(content: content, at: offset)
        self.length += content.utf16Length
    }
    
    public func delete(range: NSRange) throws {
        // Check if the range is within bounds
        guard range.location >= 0 && range.length >= 0 && range.location + range.length <= length else {
            throw TendrilTreeError.invalidDeleteRange
        }

        self.root = self.root.delete(location: range.location, length: range.length) ?? Leaf("\n")
        self.length -= range.length
    }
}
