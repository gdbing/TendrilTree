//
//  Node+Folding.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-16.
//

import Foundation

extension Node {
    func collapse(range: NSRange) throws -> Node {
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
        for candidate in parentCandidates {
            currentRoot = currentRoot.collapseParent(at: candidate.offset)
        }
        
        return currentRoot
    }
    
    func collapseParent(at offset: Int) -> Node {
        // Ensure we are a parent with uncollapsed children
        guard let parent = leafAt(offset: offset),
              let children = childrenOfLeaf(at: offset) else {
            return self
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
        guard let splitPoint else { return self }
        
        let (left, interim) = split(at: splitPoint)
        guard let interim else { return left ?? self }
        
        let (collapsedNode, right) = interim.split(at: childrenWidth)
        
        collapsedNode?.enumerateLeaves {
            $0.indentation -= parent.indentation
            return true
        }
        if let existingCollapsed = parent.collapsedChildren  {
            parent.collapsedChildren = Node.join(existingCollapsed, collapsedNode)
        } else {
            parent.collapsedChildren = collapsedNode
        }
        return Node.join(left, right) ?? self
    }
    
    // return first immediate parent
    // return nil if leaf at offset has no parent
    func parentOfLeaf(at offset: Int) -> (leaf: Leaf, offset: Int)? {
        guard let leaf = leafAt(offset: offset), leaf.indentation > 0 else {
            return nil
        }
        let indentation = leaf.indentation
        var result: (Leaf, Int)?
        enumerateLeaves(from: offset, direction: .backward) { leaf, os in
            if leaf.indentation < indentation {
                result = (leaf, os)
                return false
            }
            return true
        }
        return result
    }
        
    func childrenOfLeaf(at offset: Int) -> [Leaf]? {
        var indentation: Int?
        var result: [Leaf] = []
        enumerateLeaves(from: offset) {
            if indentation == nil {
                indentation = $0.indentation
            } else if $0.indentation > indentation! {
                result.append($0)
            } else {
                return false
            }
            return true
        }
        return result
    }
        
    enum TraversalDirection {
        case forward, backward
    }

    /// Traverses leaves starting at the given offset, optionally in reverse.
    /// Calls `visit` on each leaf. If `visit` returns false, traversal stops early.
    func enumerateLeaves(
        from start: Int? = nil,
        to end: Int? = nil,
        direction: TraversalDirection? = nil,
        visit: (Leaf) -> Bool
    ) {
        enumerateLeaves(from: start, to: end, direction: direction) { leaf, _ in visit(leaf) }
    }

    func enumerateLeaves(
        from start: Int? = nil,
        to end: Int? = nil,
        direction: TraversalDirection? = nil,
        visit: (Leaf, Int) -> Bool
    ) {
        let length = string.utf16.count + 1
        
        
        let direction = direction ?? ((direction == nil && start ?? 0 > end ?? Int.max) ? .backward : .forward)
        let start = start ?? (direction == .forward ? 0 : length)
        let end = end ?? (direction == .forward ? length : 0)
        
        var nodeStack = [Node]()
        var currentNode: Node? = self
        var offset = 0
        
        if direction == .forward {
            seekStart: while let node = currentNode {
                guard node as? Leaf == nil else { break seekStart }
                
                if offset + node.weight > start {
                    nodeStack.append(node)
                    currentNode = node.left
                } else {
                    offset += node.weight
                    currentNode = node.right
                }
            }
            
            visitLeaves: while let node = currentNode {
                guard offset <= end else { return }
                
                if let leaf = node as? Leaf {
                    if !visit(leaf, offset) { return }
                    offset += node.weight
                    currentNode = nodeStack.popLast()?.right
                } else {
                    nodeStack.append(node)
                    currentNode = node.left
                }
            }
        } else {
            seekStart: while let node = currentNode {
                guard node as? Leaf == nil else { break seekStart }
                
                if offset + node.weight > start {
                    currentNode = node.left
                } else {
                    nodeStack.append(node)
                    offset += node.weight
                    currentNode = node.right
                }
            }

            offset += currentNode?.weight ?? 0
            
            visitLeaves: while let node = currentNode {
                guard offset > end else { return }
                
                if let leaf = node as? Leaf {
                    offset -= node.weight
                    if !visit(leaf, offset) { return }
                    currentNode = nodeStack.popLast()?.left
                } else {
                    nodeStack.append(node)
                    currentNode = node.right
                }
            }
        }
    }
}
