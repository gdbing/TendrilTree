//
//  Node+Folding.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-16.
//

import Foundation

extension Node {
    func collapse(range: NSRange) throws -> (Node, Int) {
        var parentCandidates: [(leaf: Leaf, offset: Int)] = []

        // - For Each leaf within range:
        //    - If it is a parent, store it
        //    - If it has a parent, get and store that
        // - Sort parents, remove duplicates
        // - Collapse parents in reverse order so they don't affect the offsets of each other

        self.enumerateLeaves(from: range.location, to: range.upperBound) { leaf, offset -> Bool in
            if let children = self.childrenOfLeaf(at: offset), !children.isEmpty {
                parentCandidates.append((leaf: leaf, offset: offset))
            } else if let parent = self.parentOfLeaf(at: offset) {
                parentCandidates.append(parent)
            }
            return true
        }

        guard parentCandidates.count > 0 else {
            throw TendrilTreeError.cannotCollapse
        }

        var seenLeaves = Set<ObjectIdentifier>()
        parentCandidates = parentCandidates.filter {
            seenLeaves.insert(ObjectIdentifier($0.leaf)).inserted
        }
        parentCandidates.sort { $0.offset > $1.offset }

        var currentRoot = self
        var totalWidth = 0
        for candidate in parentCandidates {
            let (newRoot, childrenWidth) = currentRoot.collapseParent(at: candidate.offset)
            currentRoot = newRoot
            totalWidth += childrenWidth
        }

        return (currentRoot, totalWidth)
    }

    func collapseParent(at offset: Int) -> (Node, Int) {
        // Ensure we are a parent with uncollapsed children
        guard let parent = leafAt(offset: offset),
            let children = childrenOfLeaf(at: offset)
        else {
            return (self, 0)
        }

        let childrenWidth = children.reduce(into: 0) { widthAccumulator, childLeaf in
            widthAccumulator += childLeaf.weight
        }

        var splitPoint: Int?
        var currentOffset = offset
        var currentNode: Node? = self

        while let node = currentNode {
            if node is Leaf {
                splitPoint = offset + node.weight - currentOffset
                break
            } else if currentOffset < node.weight {
                currentNode = node.left
            } else {
                currentNode = node.right
                currentOffset -= node.weight
            }
        }
        guard let splitPoint else { return (self, 0) }

        let (left, interim) = split(at: splitPoint)
        guard let interim else { return (left ?? self, 0) }

        let (collapsedNode, right) = interim.split(at: childrenWidth)

        collapsedNode?.enumerateLeaves {
            $0.indentation -= parent.indentation
            return true
        }
        if let existingCollapsed = parent.collapsedChildren {
            parent.collapsedChildren = Node.join(existingCollapsed, collapsedNode)
        } else {
            parent.collapsedChildren = collapsedNode
        }
        return (Node.join(left, right) ?? self, childrenWidth)
    }

    func expand(range: NSRange) throws -> Node {
        var node = self
        self.enumerateLeaves(from: range.upperBound, to: range.lowerBound) { leaf, offset in
            if let children = leaf.collapsedChildren {
                node = node.insert(subTree: children, at: offset + leaf.weight)
                leaf.collapsedChildren = nil
            }
            return true
        }
        return node
    }
}
