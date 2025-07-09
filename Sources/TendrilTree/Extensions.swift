//
//  Extensions.swift
//  TendrilTree
//

import Foundation

extension String {
    func charIndex(utf16Index: Int) -> String.Index? {
        guard let idx = utf16.index(utf16.startIndex, offsetBy: utf16Index, limitedBy: utf16.endIndex)
        else { return nil }

        return String.Index(idx, within: self)
    }

    @inline(__always)
    var utf16Length: Int {
        self.utf16.count
    }
}

extension StringProtocol {
    func splitIntoLines() -> [String] {
        var lines: [String] = []
        let wholeString = self.startIndex..<self.endIndex
        self.enumerateSubstrings(in: wholeString, options: .byLines) {
            (substring, range, enclosingRange, stopPointer) in
            if substring != nil {
                let line = self[enclosingRange]
                lines.append(String(line))
            }
        }
        return lines
    }
}

extension Array where Element == NSRange {
    /// Returns a new array where adjacent ranges are merged into one.
    func mergedAdjacentNSRanges() -> [NSRange] {
        guard !self.isEmpty else { return [] }
        var result: [NSRange] = []
        var current = self[0]

        for range in self.dropFirst() {
            if current.upperBound == range.location {
                // Extend the current range to include the next one.
                current.length += range.length
            } else {
                result.append(current)
                current = range
            }
        }
        result.append(current)
        return result
    }
}
