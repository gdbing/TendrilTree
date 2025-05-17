//
//  FoldOperationTests.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-05-10.
//

import Foundation
import Testing
@testable import TendrilTree

@Suite final class FoldOperationTests {
    @Test func testEnumerate() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        var result = ""
        tree.root.enumerateLeaves() { leaf in
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect(content + "\n" == result)
        
        result = ""
        tree.root.enumerateLeaves(from: 5, to: "abcd\nefg\nhijk\nlmnop\nqrs\ntuv".count) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: 5) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            if leaf.content.contains("s") {
                return false
            } else {
                return true
            }
        }
        #expect("\tefg\n\t\thijk\n\tlmnop\nqrs\n" == result)
    }
    
    @Test func testEnumerateBackward() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        var result = ""
        tree.root.enumerateLeaves(direction: .backward) { leaf in
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("wxyz\ntuv\nqrs\n\tlmnop\n\t\thijk\n\tefg\nabcd\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: "abcd\nefg\nhijk\nlmnop\nqrs\nt".count, to: "abcd\nef".count) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            return true
        }
        #expect("tuv\nqrs\n\tlmnop\n\t\thijk\n\tefg\n" == result)

        result = ""
        tree.root.enumerateLeaves(from: "abcd\nefg\nhijk\nlmnop\nqrs\nt".count, direction: .backward) { leaf in
            
            if leaf.indentation > 0 {
                result += String(repeating: "\t", count: leaf.indentation)
            }
            result += leaf.content
            if leaf.content.contains("j") {
                return false
            } else {
                return true
            }
        }
        #expect("tuv\nqrs\n\tlmnop\n\t\thijk\n" == result)
    }

    @Test func testEnumerateOffset() throws {
        var offsets: [Int] = []
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        tree.root.enumerateLeaves { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [0,5,9,14,20,24,28])

        offsets = []
        tree.root.enumerateLeaves(direction: .backward) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [0,5,9,14,20,24,28].reversed())

        offsets = []
        tree.root.enumerateLeaves(from: 7) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [5,9,14,20,24,28])

        offsets = []
        tree.root.enumerateLeaves(from: 21, to: 8, direction: .backward) { leaf, offset in
            offsets.append(offset)
            return true
        }
        #expect(offsets == [20, 14, 9, 5])
        
        offsets = []
    }
        
    @Test func testParentOfLeaf() throws {
        let content = "abcd\nefg\n"
                    + "\t" + "hijk\n"
                    + "\t\t" + "lmnop\n"
                    + "\t" + "qrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        #expect(tree.root.parentOfLeaf(at: 0)?.leaf.content == nil)
        #expect(tree.root.parentOfLeaf(at: "abcd\n".count)?.leaf.content == nil)
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\n".count)?.leaf.content == "efg\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\n".count)?.leaf.content == "hijk\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\nlmnop\n".count)?.leaf.content == "efg\n")
        #expect(tree.root.parentOfLeaf(at: "abcd\nefg\nhijk\nlmnop\nqrs\n".count)?.leaf.content == nil)
    }
    
    @Test func testChildrenOfLeaf() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        let tree = TendrilTree(content: content)
        #expect(tree.root.childrenOfLeaf(at: 0)?.map { $0.content } == ["efg\n", "hijk\n", "lmnop\n"])
        #expect(tree.root.childrenOfLeaf(at: "abcd\n".count)?.map { $0.content } == ["hijk\n"])
        #expect(tree.root.childrenOfLeaf(at: "abcd\nefg\n".count)?.map { $0.content } == [])
    }
    
    // abcd
    //     efg
    //         hijk
    //     lmnop
    // qrs
    // tuv
    // wxyz
    @Test func testCollapse() throws {
        let content = "abcd\n\tefg\n\t\thijk\n\tlmnop\nqrs\ntuv\nwxyz"
        var tree = TendrilTree(content: content)
        #expect(tree.string == "abcd\nefg\nhijk\nlmnop\nqrs\ntuv\nwxyz")
        try tree.root = tree.root.collapse(range: NSRange(location: 0, length: 0))
        #expect(tree.string == "abcd\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "efg\nhijk\nlmnop\n")
        
        tree = TendrilTree(content: content)
        try tree.root = tree.root.collapse(range: NSRange(location: "abcd\n".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\n".count)?.collapsedChildren?.string == "hijk\n")
        
        tree = TendrilTree(content: content)
        try tree.root = tree.root.collapse(range: NSRange(location: "abcd\nef".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\nef".count)?.collapsedChildren?.string == "hijk\n")
        
        tree = TendrilTree(content: content)
        try tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\n".count, length: 0))
        #expect(tree.string == "abcd\nefg\nlmnop\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: "abcd\n".count)?.collapsedChildren?.string == "hijk\n")

        tree = TendrilTree(content: content)
        try tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\nhijk\nlmn".count, length: 0))
        #expect(tree.string == "abcd\nqrs\ntuv\nwxyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "efg\nhijk\nlmnop\n")

        tree = TendrilTree(content: content)
        #expect(throws: TendrilTreeError.cannotCollapse) {
            try tree.root = tree.root.collapse(range: NSRange(location: "abcd\nefg\nhijk\nlmnop\n".count, length: 0))
        }
        #expect(tree.string == "abcd\nefg\nhijk\nlmnop\nqrs\ntuv\nwxyz")
    }
    
    @Test func testCollapseIntoCollapsed() throws {
        let content = "abcd\n\tefg"
        let tree = TendrilTree(content: content)
        tree.root = tree.root.collapseParent(at: 1)
        #expect(tree.string == "abcd")
        try tree.insert(content: "\nhijk", at: 4)
        try tree.indent(range: NSRange(location: 5, length: 0))
        #expect(tree.string == "abcd\nhijk")
        tree.root = tree.root.collapseParent(at: 1)
        #expect(tree.string == "abcd")
    }
    
    // abc
    //     defg
    // hijk
    //     lmnop
    //         qrs
    //     tuv
    //     wx
    // yz
    @Test func testCollapseMultipleParents() throws {
        let content = "abc\n\tdefg\nhijk\n\tlmnop\n\t\tqrs\n\ttuv\n\twx\nyz"
        var tree = TendrilTree(content: content)
        #expect(tree.string == "abc\ndefg\nhijk\nlmnop\nqrs\ntuv\nwx\nyz")
        try tree.root = tree.root.collapse(range: NSRange(location: 0, length: content.count))
        #expect(tree.string == "abc\nhijk\nyz")
        #expect(tree.root.leafAt(offset: 0)?.collapsedChildren?.string == "defg\n")
        #expect(tree.root.leafAt(offset: 4)?.collapsedChildren?.string == "lmnop\ntuv\nwx\n")
        #expect(tree.root.leafAt(offset: 4)?.collapsedChildren?.leafAt(offset: 0)?.collapsedChildren?.string == "qrs\n")
        
        tree = TendrilTree(content: content)
        try tree.root = tree.root.collapse(range: NSRange(location: "abcd\n".count, length: "defg\nhijk".count))
        #expect(tree.string == "abc\nhijk\nyz")

    }
}
