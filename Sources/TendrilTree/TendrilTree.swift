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
//    into paragraph nodes.
//  - **Operations:**
//    - **Insertion/Deletion:** Efficiently inserts and deletes text.
//    - **Accessors:** Retrieves content, line ranges, and indentation levels.
//    - **Indentation:** Modifies indentation of lines within a range.
//    - **Folding:** Collapses and expands hierarchical node structures.
//
//  - NB: The paragraph invariant means `content` of every Leaf must end with '\n'.
//        But it is not necessary that `TendrilTree.string` must end with '\n',
//        so TendrilTree is initialized with EXTRA_TRAILING_NEWLINE which is
//        part of the structure, but is not included in `string` output, and is not
//        counted in `length`.
//        As a result, the Tree will often have one Leaf more than is expected, if
//        its content has a trailing newline.
//

import Foundation

/// Structural newline used to ensure every leaf ends with a `\n`
/// Never shown to clients or counted in `.length`
private let EXTRA_TRAILING_NEWLINE = "\n"

public class TendrilTree {
    var root: Node = Leaf(EXTRA_TRAILING_NEWLINE)
    var length: Int = 0

    // MARK: - Initialization

    public init() {}

    public init(content: String) {
        guard !content.isEmpty else { return }

        if let (root, length) = Node.parse(content + EXTRA_TRAILING_NEWLINE) {
            self.root = root
            self.length = length - EXTRA_TRAILING_NEWLINE.count
        }
    }

    // MARK: - Accessors

    public var string: String {
        return String(root.string.dropLast())
    }

    /// Returns the indentation level of the line at the given UTF-16 offset.
    /// - Parameter offset: The UTF-16 offset to check.
    /// - Returns: The indentation level (number of spaces).
    /// - Throws: `TendrilTreeError.invalidRange` if the offset is out of bounds.
    public func indentation(at offset: Int) throws -> Int {
        guard offset >= 0 && offset <= length,
            let leaf = self.root.leafAt(offset: offset)
        else {
            throw TendrilTreeError.invalidRange
        }

        return leaf.indentation
    }

    /// Returns the UTF-16 range of the line containing the given offset.

    /// - Returns: An `NSRange` representing the full range of the line.
    /// - Throws: `TendrilTreeError.invalidRange` if the offset is out of bounds.
    public func rangeOfLine(at offset: Int) throws -> NSRange {
        guard offset >= 0 && offset <= length else {
            throw TendrilTreeError.invalidRange
        }

        var result = NSRange(location: 0, length: 0)
        self.root.enumerateLeaves(from: offset, to: offset) { leaf, offset in
            result = NSRange(location: offset, length: leaf.weight)
            return true
        }

        return result
    }

    /// Enumerates over the lines (leaves) that intersect with the given UTF-16 range.
    /// - Parameters:
    ///   - range: The `NSRange` to enumerate within.
    ///   - visit: A closure that is called for each line in the range.
    ///     - `content`: The string content of the line.
    ///     - `range`: The range of the line within the tree's full content.
    ///     - `indentation`: The indentation level of the line.
    public func enumerateLines(in range: NSRange, visit: (String, NSRange, Int) -> Void) {
        self.root.enumerateLeaves(from: range.location, to: range.upperBound) { leaf, offset in

            if offset + leaf.weight > length {
                visit(
                    leaf.content, NSRange(location: offset, length: leaf.weight - EXTRA_TRAILING_NEWLINE.count), leaf.indentation)
                return false
            }
            visit(leaf.content, NSRange(location: offset, length: leaf.weight), leaf.indentation)
            return true
        }
    }

    // MARK: - Operations

    public func insert(
        content: String,
        at offset: Int,
        callback: @escaping (String, NSRange) -> Void = { _, _ in }
    ) throws {
        guard offset >= 0 && offset <= length else {
            throw TendrilTreeError.invalidInsertOffset
        }
        guard content.utf16Length > 0 else {
            return
        }

        var stringAccumulator = ""
        var deletionLength = 0

        let wholeString = content.startIndex..<content.endIndex
        var relativeOffset = offset
        var thrownError: Error? = nil

        content.enumerateSubstrings(in: wholeString, options: .byLines) {
            (substring, range, enclosingRange, stopPointer) in
            if substring != nil {
                let line = content[enclosingRange]
                let indentation = line.prefix(while: { $0 == "\t" }).count
                let insertion = String(line.dropFirst(indentation))

                self.root = self.root.insert(line: insertion, at: relativeOffset)
                do {
                    try self.indent(depth: indentation, range: NSRange(location: relativeOffset, length: 0))
                } catch {
                    thrownError = error
                    stopPointer = true
                    return
                }
                stringAccumulator += String(insertion)

                relativeOffset += insertion.utf16Length
                self.length += insertion.utf16Length
            }
        }

        if let error = thrownError {
            throw error
        }

        // if a newline was inserted before some tabs, producing a tab-prefixed line
        // then convert those tabs into indentation
        if root.charAt(offset: relativeOffset - 1) == "\n",
            root.charAt(offset: relativeOffset) == "\t",
            let leaf = root.leafAt(offset: relativeOffset)
        {
            let indentation = leaf.content.prefix(while: { $0 == "\t" }).count
            self.root = self.root.delete(location: relativeOffset, length: indentation) ?? Leaf("\n")
            try self.indent(range: NSRange(location: relativeOffset, length: 0))
            deletionLength = indentation
            self.length -= indentation
        }

        // enumerateSubstrings byLines naively treats each line like they follow a newline
        // but the first line might not be if insertion point is in the middle of a line
        // We only want to convert tab chars which prefix lines, so we should undo the conversion.
        if offset > 0,
            content.hasPrefix("\t"),
            root.charAt(offset: offset - 1) != "\n",
            let leaf = root.leafAt(offset: offset)
        {
            let indentation = content.prefix(while: { $0 == "\t" }).count
            let tabs = String(repeating: "\t", count: indentation)
            self.root = self.root.insert(content: tabs, at: offset)
            leaf.indentation -= indentation

            self.length += indentation
            stringAccumulator = tabs + stringAccumulator
        }
        callback(stringAccumulator, NSRange(location: offset, length: deletionLength))
    }

    public func delete(range: NSRange, callback: @escaping (String, NSRange) -> Void = { _, _ in }) throws {
        guard range.location >= 0 && range.length >= 0 && range.location + range.length <= length else {
            throw TendrilTreeError.invalidDeleteRange
        }
        if range.length == 0 {
            return
        }

        var deletionLength = 0

        self.root = self.root.delete(location: range.location, length: range.length) ?? Leaf("\n")
        self.length -= range.length
        deletionLength += range.length

        if let leaf = self.root.leafAt(offset: range.location), leaf.content.hasPrefix("\t") {
            let content = leaf.content
            let indentation = content.prefix(while: { $0 == "\t" }).count
            leaf.content = String(content.suffix(from: content.index(content.startIndex, offsetBy: indentation)))
            try indent(depth: indentation, range: NSRange(location: range.location, length: 0))
            self.length -= indentation
            deletionLength += indentation
        }
        callback("", NSRange(location: range.location, length: deletionLength))
    }

    /// Increases the indentation level for all lines within the specified range.
    /// - Parameters:
    ///   - depth: The number of spaces to add to the indentation. Defaults to 1.
    ///   - range: The UTF-16 range of lines to indent.
    /// - Throws: `TendrilTreeError.invalidRange` if the range is out of bounds.
    public func indent(depth: Int = 1, range: NSRange, callback: (([NSRange]) -> Void) = { _ in }) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }
        guard depth > 0 else { return }

        var ranges = [NSRange]()
        self.root.enumerateLeaves(from: range.lowerBound, to: range.upperBound) { leaf, offset in
            leaf.indentation += depth
            ranges.append(NSRange(location: offset, length: leaf.weight))
            return true
        }

        if let last = ranges.last, last.upperBound > length {
            ranges = ranges.dropLast()
            if last.length > 1 {
                ranges.append(NSRange(location: last.location, length: last.length - EXTRA_TRAILING_NEWLINE.count))
            }
        }

        callback(ranges.mergedAdjacentNSRanges())
    }

    /// Decreases the indentation level for all lines within the specified range.
    ///
    /// The indentation level will not be reduced below zero.
    /// - Parameters:
    ///   - depth: The number of spaces to remove from the indentation (should be negative). Defaults to -1.
    ///   - range: The UTF-16 range of lines to outdent.
    /// - Throws: `TendrilTreeError.invalidRange` if the range is out of bounds.
    public func outdent(depth: Int = -1, range: NSRange, callback: (([NSRange]) -> Void) = { _ in }) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }
        guard depth < 0 else { return }

        var ranges = [NSRange]()
        self.root.enumerateLeaves(from: range.lowerBound, to: range.upperBound) { leaf, offset in
            let newIndentation = leaf.indentation + depth
            if newIndentation > -1 {
                leaf.indentation = newIndentation
                ranges.append(NSRange(location: offset, length: leaf.weight))
            }
            return true
        }

        if let last = ranges.last, last.upperBound > length {
            ranges = ranges.dropLast()
            if last.length > 1 {
                ranges.append(NSRange(location: last.location, length: last.length - EXTRA_TRAILING_NEWLINE.count))
            }
        }

        callback(ranges.mergedAdjacentNSRanges())
    }

    /// Collapses all eligible nodes in a specified range, folding hierarchical blocks as appropriate.
    ///
    /// For each line (leaf node) overlapped by `range`, this method examines folding opportunities:
    ///   - If the line is a parent (has one or more uncollapsed children), that parent’s children are collapsed into it.
    ///   - If the line itself is not a parent, but its parent exists within the tree, **that parent** collapses *all* its immediate children (including this line).
    ///   - If nodes are nested (multiple levels of hierarchy), collapsing proceeds fully as appropriate for all matching parents within the range.
    ///
    /// - Parameter range: The range (in UTF-16 code units) to consider for collapse.
    /// - Throws:
    ///    - `TendrilTreeError.invalidRange` if the range is not within the bounds of the document.
    ///    - `TendrilTreeError.cannotCollapse` if there are no collapsible nodes in the range (i.e., no parent with children or no eligible folds found).
    /// - Side Effects:
    ///    - Updates the tree’s structure such that affected parents now contain their collapsed children.
    ///    - Updates the tree’s length property to match its new content.
    ///    - No-op if the range contains only leaves with no parent-children relationships.
    public func collapse(range: NSRange) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }

        let (newRoot, collapsedWidth) = try self.root.collapse(range: range)
        self.root = newRoot
        self.length -= collapsedWidth
    }

    /// Expands all eligible collapsed nodes within a specified range.
    ///
    /// For each line (leaf node) overlapped by `range`, this method examines expansion opportunities:
    ///   - If a line is a collapsed parent (contains folded children), it is expanded to reveal its children.
    ///   - If nodes are nested, expansion proceeds fully as appropriate for all matching collapsed parents within the range.
    ///
    /// - Parameter range: The range (in UTF-16 code units) to consider for expansion.
    /// - Throws:
    ///    - `TendrilTreeError.invalidRange` if the range is not within the bounds of the document.
    ///    - `TendrilTreeError.cannotExpand` if there are no expandable nodes in the range.
    /// - Side Effects:
    ///    - Updates the tree’s structure such that affected children are now visible.
    ///    - Updates the tree’s length property to match its new content.
    ///    - No-op if the range contains no collapsed nodes.
    public func expand(range: NSRange) throws {
        guard range.location >= 0 && range.length >= 0 && range.upperBound <= length else {
            throw TendrilTreeError.invalidRange
        }

        let (newNode, expandedWidth) = try self.root.expand(range: range)
        self.root = newNode
        self.length += expandedWidth
    }
}
