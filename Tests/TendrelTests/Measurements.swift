//
//  Measurements.swift
//  TendrilTree
//
//  Created by Graham Bing on 2025-01-27.
//

import XCTest
import Foundation
@testable import TendrilTree

final class Measurements: XCTestCase {
    func testParseMobyDick() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let contents = try! String(contentsOfFile: filePath, encoding: .utf8)
            self.measure {
                tendrilTree = TendrilTree(content: contents)
            }
            XCTAssertEqual(tendrilTree?.string, contents)
        }
    }

    func testPrintMobyDick() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let contents = try! String(contentsOfFile: filePath, encoding: .utf8)
            tendrilTree = TendrilTree(content: contents)
            var s: String?
            self.measure {
                s = tendrilTree?.string
            }
            XCTAssertEqual(s, contents)
        }
    }

    func testPrintMobyDick_insertion() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            var contents = try! String(contentsOfFile: filePath, encoding: .utf8)
            tendrilTree = TendrilTree(content: contents)
            var s: String?
            // load cache
            s = tendrilTree?.string
            // partially invalidate cache
            try tendrilTree?.insert(content: "x", at: contents.utf16Length / 3)
            self.measure {
                s = tendrilTree?.string
            }
            contents.insert(Character("x"), at: contents.index(contents.startIndex, offsetBy: contents.utf16Length / 3))
            XCTAssertEqual(s, contents)
        }
    }

    func testInsertMobyDickIntoEmptyTree() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let contents = try! String(contentsOfFile: filePath, encoding: .utf8)
            self.measure {
                tendrilTree = TendrilTree()
                do {
                    try tendrilTree?.insert(content: contents, at: 0)
                } catch {

                }
            }
            XCTAssertEqual(tendrilTree?.string, contents)
        }
    }

    func testInsertLongLineIntoEmptyTree() throws {
        var tendrilTree: TendrilTree?
        let content = String(repeating: "LongContent-", count: 1000)
        self.measure {
            tendrilTree = TendrilTree()
            do {
                try tendrilTree?.insert(content: content, at: 0)
            } catch {

            }
        }
        XCTAssertEqual(tendrilTree?.string, content)
    }

    func testInsertManyLinesIntoEmptyTree() throws {
        var tendrilTree: TendrilTree?
        let content = String(repeating: "LongContent\n", count: 1000)
        self.measure {
            tendrilTree = TendrilTree()
            do {
                try tendrilTree?.insert(content: content, at: 0)
            } catch {

            }
        }
        XCTAssertEqual(tendrilTree?.string, content)
    }

    func testAppendManyLinesToMobyDick() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let mobyDickContent = try! String(contentsOfFile: filePath, encoding: .utf8)
            let content = String(repeating: "LongContent\n", count: 1000)
            self.measure {
                tendrilTree = TendrilTree(content: mobyDickContent)
                do {
                    try tendrilTree?.insert(content: content, at: mobyDickContent.utf16Length)
                } catch {

                }
            }
            XCTAssertEqual(tendrilTree?.string, mobyDickContent + content)
        }
    }

    func testPrependManyLinesToMobyDick() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let mobyDickContent = try! String(contentsOfFile: filePath, encoding: .utf8)
            let content = String(repeating: "LongContent\n", count: 1000)
            self.measure {
                tendrilTree = TendrilTree(content: mobyDickContent)
                do {
                    try tendrilTree?.insert(content: content, at: 0)
                } catch {

                }
            }
            XCTAssertEqual(tendrilTree?.string, content + mobyDickContent)
        }
    }

    func testInsertManyLinesIntoTheMiddleOfMobyDick() throws {
        var tendrilTree: TendrilTree?
        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
            let mobyDickContent = try! String(contentsOfFile: filePath, encoding: .utf8)
            let offset = 500000
            XCTAssert(mobyDickContent.utf16Length < offset * 3)
            XCTAssert(mobyDickContent.utf16Length > offset * 2)
            let midIdx = mobyDickContent.charIndex(utf16Index: offset)!
            let content = String(repeating: "LongContent\n", count: 1000)
            self.measure {
                tendrilTree = TendrilTree(content: mobyDickContent)
                do {
                    try tendrilTree?.insert(content: content, at: offset)
                } catch {

                }
            }
            XCTAssertEqual(tendrilTree?.string, String(mobyDickContent.prefix(upTo: midIdx)) + content + String(mobyDickContent.suffix(from: midIdx)))
        }
    }

//    func testAppendMobyDickToMobyDick() throws {
//        var tendrilTree: TendrilTree?
//        if let filePath = Bundle.module.path(forResource: "moby_dick", ofType: "md") {
//            let contents = try! String(contentsOfFile: filePath, encoding: .utf8)
//            self.measure {
//                tendrilTree = TendrilTree(content: contents)
//                do {
//                    try tendrilTree?.insert(content: contents, at: contents.utf16Length)
//                } catch {
//
//                }
//            }
//            XCTAssertEqual(tendrilTree?.string, contents + contents)
//        }
//    }
}
