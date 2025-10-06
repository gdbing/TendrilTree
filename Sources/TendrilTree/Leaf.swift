//
//  LeafNode.swift
//  TendrilTree
//
//  Defines Leaf nodes for TendrilTree rope structure.
//  - Subclass of Node
//  - `content` contains a single paragraph string (always ending in '\n').
//  - `left` and `right` (Node properties) are always nil.
//

class Leaf: Node {
    var content: String
    var indentation: Int
    var collapsedChildren: Node?

    init(_ content: String, indentation: Int = 0, collapsedChildren: Node? = nil) {
        assert(content.last == "\n")
        self.content = content
        self.indentation = indentation
        self.collapsedChildren = collapsedChildren
        super.init()
        self.weight = content.utf16Length
    }

    override var string: String {
        return content
    }
    
    override var count: Int {
        if cacheCount == nil {
            var inWord = false
            self.cacheCount = 0
            for ch in content {
                if ch.isWhitespace {
                    inWord = false
                } else if !inWord {
                    self.cacheCount! += 1
                    inWord = true
                }
            }
        }
        return cacheCount!
    }

    // MARK: - Insertion

    override func insert(line: String, at offset: Int) -> Node {
        guard let offsetIndex = content.charIndex(utf16Index: offset) else {
            fatalError()
        }
        cacheCount = nil

        let prefix = content.prefix(upTo: offsetIndex)
        if prefix.hasSuffix("\n") {
            // appending under the last paragraph
            // otherwise this would be prepended to the next leaf
            return splitNode(leftContent: String(prefix), rightContent: line)
        }
        if line.hasSuffix("\n") {
            return splitNode(leftContent: prefix + line, rightContent: String(content.suffix(from: offsetIndex)))
        }

        self.content = content.prefix(upTo: offsetIndex) + line + String(content.suffix(from: offsetIndex))
        self.weight += line.utf16Length
        return self
    }

    private func splitNode(leftContent: String, rightContent: String) -> Node {
        guard leftContent.utf16Length > 0 else {
            self.content = rightContent
            self.weight = rightContent.utf16Length
            return self
        }

        guard rightContent.utf16Length > 0 else {
            self.content = leftContent
            self.weight = leftContent.utf16Length
            return self
        }

        self.content = leftContent
        self.weight = leftContent.utf16Length

        let right = Leaf(rightContent)
        right.indentation = indentation

        let parent = Node()

        parent.left = self
        parent.right = right
        parent.weight = leftContent.utf16Length

        return parent
    }
}
