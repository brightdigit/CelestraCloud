// CloudKitConvertible.swift
// CelestraCloud
//
// Protocol for types that can be converted to/from CloudKit records
// Created for Celestra on 2025-12-16.
//

import Foundation
import MistKit

/// Protocol for types that can be converted to/from CloudKit records using MistKit
///
/// Types conforming to this protocol can be:
/// - Converted to CloudKit field dictionaries for creating/updating records
/// - Initialized from CloudKit RecordInfo for reading records
///
/// This protocol standardizes the conversion pattern used throughout the codebase
/// and enables generic CloudKit operations.
protocol CloudKitConvertible {
    /// Convert the instance to a CloudKit fields dictionary
    ///
    /// - Returns: Dictionary mapping field names to FieldValue instances
    func toFieldsDict() -> [String: FieldValue]

    /// Create an instance from a CloudKit record
    ///
    /// - Parameter record: The CloudKit RecordInfo containing field data
    /// - Throws: CloudKitConversionError if required fields are missing or invalid
    init(from record: RecordInfo) throws
}
