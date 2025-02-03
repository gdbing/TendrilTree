//
//  Node+Insertion.swift
//  TendrilTree
//

import Foundation

extension Node {
    func insert(content: String, at offset: Int) {
        cacheString = nil
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
                    self.weight += content.utf16Length
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
}
