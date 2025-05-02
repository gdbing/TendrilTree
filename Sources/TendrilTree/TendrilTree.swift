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
//  - NB: The paragraph invariant means `content` of every Leaf must end with '\n'.
//        But it is not necessarily so that `TendrilTree.string` must end with '\n'.
//        So TendrilTree is initialized with an "extra" trailing newline which is
//        part of the structure, but is not included in `string` output, and is not
//        counted in `length`.
//        As a result, the Tree will often have one Leaf more than is expected, if
//        its content has a trailing newline.
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
        guard range.location >= 0 && range.length >= 0 && range.location + range.length <= length else {
            throw TendrilTreeError.invalidDeleteRange
        }

        self.root = self.root.delete(location: range.location, length: range.length) ?? Leaf("\n")
        self.length -= range.length
    }
    
    public func indent(depth: Int = 1, range: NSRange) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }

        let leaves = self.root.leavesAt(start: range.lowerBound, end: range.upperBound)
        leaves.forEach { $0.indentation += depth }
    }

    public func outdent(depth: Int = -1, range: NSRange) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }

        let leaves = self.root.leavesAt(start: range.lowerBound, end: range.upperBound)
        leaves.forEach { $0.indentation = max(0, $0.indentation + depth) }
    }
    
}
