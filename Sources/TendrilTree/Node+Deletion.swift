//
//  Node+Deletion.swift
//  TendrilTree
//

import Foundation

extension Node {
    // MARK: - Delete

        func delete(range: NSRange) -> Node? {
            cacheString = nil
            return delete(location: range.location, length: range.length)
        }

        private func delete(location: Int, length: Int) -> Node? {
            if let content = self.content {
                let prefixIndex = content.charIndex(utf16Index: location)
                let prefix = content.prefix(upTo: prefixIndex ?? content.startIndex)
                let suffixIndex = content.charIndex(utf16Index: location + length)
                let suffix = content.suffix(from: suffixIndex ?? content.endIndex)
                if !suffix.isEmpty || !prefix.isEmpty {
                    self.content = String(prefix + suffix)
                    self.weight = self.content!.utf16Length
                    /// NB: if the suffix is deleted it can remove the newline, breaking
                    ///    the invariant that each Node contains a whole paragraph.
                    ///    This is addressed in `delete(range: NSRange)`
                    return self
                } else { /// delete the whole node
                    return nil
                }
            }

            if location + length > weight {
                if location > weight {
                    self.right = self.right?.delete(location: location - weight, length: length)
                } else {
                    self.right = self.right?.delete(location: 0, length: location + length - weight)
                }
            }

            if location < weight {
                self.left = self.left?.delete(location: location, length: length)

                /// Maintain the invariant that paragraphs aren't split between nodes.
                /// If the newline is deleted from the end of a paragraph, then delete that whole node and reinsert its contents into the next node
                if location + length >= self.weight {
                    if let node = left?.nodeAt(offset: max(0, location - 1)),
                       let content = node.content,
                       self.right != nil {
                        if content.last != "\n" {
                            self.left = self.left?.delete(location: location - node.weight, length: node.weight)
                            self.right?.insert(content: content, at: 0)
                        }
                    }
                }

                self.weight -= min(length, weight - location) // length if deleting only from left node
                                                              // weight - location if also deleting right node
            }

            if self.left == nil {
                return self.right
            }

            if self.right == nil {
                return self.left
            }

            self.balance()

            return self
        }

}
