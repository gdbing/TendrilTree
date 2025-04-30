extension Node {
    // Split the tree at the given UTF‑16 offset.
    // Returns a tuple (left, right) such that:
    // • left.string + right.string == self.string
    // • Either side may be nil if the split occurs at the very beginning or end.
    // NB offset must align between leaves, splitting the content of a leaf would violate the paragraph invariant
    func split(at offset: Int) -> (left: Node?, right: Node?) {
        if isLeaf {
            if offset == 0 {
                return (nil, self)
            } else if offset == weight {
                return (self, nil)
            } else {
                fatalError("Splitting a leaf node violates the paragraph invariant")
            }
        }

        if offset < self.weight {
            let splitResult = self.left!.split(at: offset)
            let newRight = Node.join(splitResult.right, self.right)
            return (splitResult.left, newRight)
        } else {
            let newOffset = offset - self.weight
            let splitResult = self.right!.split(at: newOffset)
            let newLeft = Node.join(self.left, splitResult.left)
            return (newLeft, splitResult.right)
        }
    }

    // Joins two trees where the resulting content should be the concatenation
    // of left.string and right.string.
    // Either argument may be nil.
    static func join(_ left: Node?, _ right: Node?) -> Node? {
        switch (left, right) {
        case (nil, nil):
            return nil
        case (nil, let r?):
            return r
        case (let l?, nil):
            return l
        case (let l?, let r?):
            let parent = Node()
            parent.left = l
            parent.right = r
            parent.weight = l.string.utf16Length
            return parent.balance()
        }
    }
}
