//
//  Error.swift
//  TendrilTree
//

import Foundation

public enum TendrilTreeError: Error, LocalizedError {
    case invalidInsertOffset
    case invalidDeleteRange

    public var errorDescription: String? {
        switch self {
        case .invalidInsertOffset:
            return "The insert offset is out of bounds."
        case .invalidDeleteRange:
            return "The range for deletion is out of bounds."
        }
    }
}
