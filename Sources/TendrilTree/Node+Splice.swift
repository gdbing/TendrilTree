extension Node {
    /// Splits the tree at the specified UTF-16 offset.
    ///
    /// - Parameters:
    ///   - offset: UTF-16 based split position, must align with leaf boundaries
    /// - Returns: A tuple containing the left and right subtrees
    ///   - left: Contains all content before the split point (may be nil)
    ///   - right: Contains all content after the split point (may be nil)
    /// - Important: The offset must align with leaf boundaries to maintain the paragraph invariant
    func split(at offset: Int) -> (left: Node?, right: Node?) {
        if self is Leaf {
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
    
    /// Joins two trees by concatenating their content.
    ///
    /// - Parameters:
    ///   - left: The left subtree (may be nil)
    ///   - right: The right subtree (may be nil)
    /// - Returns: A new tree containing the concatenated content, or nil if both inputs are nil
    /// - Important: Assumes left.string ends with '\n' according to paragraph invariant
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
