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
//    var child: TendrilTree?

    init(_ content: String) {
        self.content = content
//        self.child = nil
        super.init()
        self.weight = content.utf16Length
    }

    override var string: String {
        return content
    }
    
    // MARK: - Insertion
    
    override func insert(line insertion: String, at offset: Int) -> Node {
        guard let offsetIndex = content.charIndex(utf16Index: offset) else {
            fatalError()
        }
        let prefix = content.prefix(upTo: offsetIndex)
        if prefix.hasSuffix("\n") {
            // appending under the last paragraph
            return splitNode(leftContent: String(prefix), rightContent: insertion)
        }
        if insertion.hasSuffix("\n") {
            return splitNode(leftContent: prefix + insertion, rightContent: String(content.suffix(from: offsetIndex)))
        }
        
        self.content = content.prefix(upTo: offsetIndex) + insertion + String(content.suffix(from:offsetIndex))
        self.weight += insertion.utf16Length
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
        
        let left = Leaf(leftContent)
        
        self.content = rightContent
        self.weight = rightContent.utf16Length
        
        let parent = Node()
        
        parent.left = left
        parent.right = self
        parent.weight = leftContent.utf16Length
        
        return parent
    }
}
