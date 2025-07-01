//
//  File.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-06-29.
//

import Foundation

extension Node {
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
