//
//  TendrilTree.swift
//  TendrilTree
//

import Foundation

class TendrilTree {
    internal var root: Node = Node("")
    internal var length: Int = 0

    var string: String {
        return root.string
    }

    init() { }
    
    init(content: String) {
        guard !content.isEmpty else { return }

        if let (root, length) = Node.parse(paragraphs: content.splitIntoLines()) {
            self.root = root
            self.length = length
        }
    }

    func insert(content: String, at offset: Int) throws {
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

            let combinedContent = String(prefix + content + suffix)

            if let (root, length) = Node.parse(paragraphs: combinedContent.splitIntoLines()) {
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
            self.root.insert(content: s, at: relativeOffset)
            remainder = remainder.suffix(from: idx)
            relativeOffset += s.utf16Length
        }

        self.length += content.utf16Length
    }

    func delete(range: NSRange) throws {
        // Check if the range is within bounds
        guard range.location >= 0 && range.length >= 0 && range.location + range.length <= length else {
            throw TendrilTreeError.invalidDeleteRange
        }

        self.root = self.root.delete(location: range.location, length: range.length) ?? Node("")
        self.length -= range.length
    }
}
