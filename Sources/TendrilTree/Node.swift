//
//  Node.swift
//

import Foundation

internal class Node {
    /// weight, left, and right are the bare minimum requirements of a rope node
    var weight: Int = 0
    var left: Node?
    var right: Node?

    var content: String?

    // MARK: - init

    init() { }
    init(_ content: String) {
        self.content = content
        self.weight = content.utf16Length
    }

}

// MARK: - Utils

extension Node {
    func toString() -> String {
        if let content {
            return content
        }
        return (left?.toString() ?? "") + (right?.toString() ?? "")
    }

    func nodeAt(offset: Int) -> Node? {
        return nodeWithRemainderAt(offset: offset)?.node
    }

    private func nodeWithRemainderAt(offset:Int) -> (node: Node, remainder: Int)? {
        if left == nil && offset <= weight {
            return (self, offset)
        }

        if offset < weight {
            return left?.nodeWithRemainderAt(offset: offset)
        }

        return right?.nodeWithRemainderAt(offset: offset - weight)
    }
}

// MARK: - Parse

extension Node {
    /// Since paragraphs are already ordered we can insert them "middle out", without doing any balancing
    static func parse<C: Collection>(paragraphs: C) -> (node: Node, length: Int)? where C.Element == String {
        guard !paragraphs.isEmpty else { return nil }

        if paragraphs.count == 1 {
            let content = paragraphs.first!
            return (Node(content), content.utf16Length)
        }

        let midIdx = paragraphs.index(paragraphs.startIndex, offsetBy: paragraphs.count / 2)
        let left = parse(paragraphs: paragraphs[..<midIdx])!
        let right = parse(paragraphs: paragraphs[midIdx...])!
        let node = Node()
        node.left = left.node
        node.right = right.node
        node.weight = left.length

        return (node, left.length + right.length)
    }
}


extension Node {
    
    // MARK: - Insert

    func insert(content: String, at offset: Int) {
        if offset == 0
        {
            if let left {
                weight += content.utf16Length
                left.insert(content: content, at: 0)
            } else {
                if content.last != "\n" {
                    self.content = content + self.content!
                    self.weight += content.utf16Length
                } else {
                    self.left = Node()
                    left!.content = content
                    left!.weight = content.utf16Length

                    self.right = Node()
                    right!.content = self.content
                    right!.weight = self.content?.utf16Length ?? 0

                    self.content = nil
                    self.weight = left!.weight
                }
            }
        }
        else if offset < weight
        {
            if let left {
                left.insert(content: content, at: offset)
                self.weight += content.utf16Length
            } else {
                let offsetIndex = self.content!.charIndex(utf16Index: offset)!
                if content.last != "\n" {
                    self.content!.insert(contentsOf: content, at: offsetIndex)
                } else {
                    self.left = Node()
                    let leftSubString = self.content!.prefix(upTo: offsetIndex)
                    left!.content = String(leftSubString) + content
                    left!.weight = left!.content!.utf16Length

                    self.right = Node()
                    let rightSubString = self.content!.suffix(from: offsetIndex)
                    right!.content = String(rightSubString)
                    right!.weight = right!.content!.utf16Length

                    self.content = nil
                    self.weight = left!.weight
                }
            }
        }
        else // offset >= weight
        {
            if let right {
                right.insert(content: content, at: offset - weight)
            } else {
                guard offset == weight else { fatalError() }

                if self.content?.last != "\n" {
                    self.content! += content
                    weight += content.utf16Length
                } else {
                    self.left = Node()
                    left!.content = self.content
                    left!.weight = self.content?.utf16Length ?? 0

                    self.right = Node()
                    right!.content = content
                    right!.weight = content.utf16Length

                    self.content = nil
                }
            }
        }

        self.balance()
    }

// MARK: - Delete

    func delete(range: NSRange) -> Node? {
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
                if let node =  left?.nodeAt(offset: max(0, location - 1)), let content = node.content {
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

    // MARK: - Balance

    var height: Int {
        // We could cache this value and invalidate it when a node sees insert or delete or rotate
        let leftHeight = left?.height ?? 0
        let rightHeight = right?.height ?? 0
        return max(leftHeight, rightHeight) + 1
    }

    /// Basic AVL balance function
    private func balance() {
        let balanceFactor = (left?.height ?? 0) - (right?.height ?? 0)
        if balanceFactor > 1 {
            if let left, (left.left?.height ?? 0) < (left.right?.height ?? 0) {
                left.leftRotate()
            }
            rightRotate()
        } else if balanceFactor < -1 {
            if let right, (right.right?.height ?? 0) < (right.left?.height ?? 0) {
                right.rightRotate()
            }
            leftRotate()
        }
    }

    /// NB: rotate should never involve leafs, don't worry about content
    private func leftRotate() {
        let newLeft = Node()
        newLeft.weight = self.weight
        newLeft.left = left
        newLeft.right = self.right!.left
        self.left = newLeft

        self.weight += self.right!.weight
        self.right = self.right!.right
    }

    private func rightRotate() {
        let newRight = Node()
        newRight.left = self.left!.right
        newRight.weight = self.weight - self.left!.weight
        newRight.right = self.right
        self.right = newRight

        self.weight = left!.weight
        self.left = left!.left
    }
}
