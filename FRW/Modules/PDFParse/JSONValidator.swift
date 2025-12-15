//
//  JSONValidator.swift
//  FRW
//
//  Created by cat on 12/15/25.
//

import Foundation

// MARK: - JSON Validation Error

indirect enum JSONValidationError: Error, LocalizedError {
    case emptyInput
    case invalidJSON(underlyingError: Error)
    case unexpectedType(expected: String, actual: String)
    case missingRequiredKey(key: String)
    case invalidValueType(key: String, expected: String, actual: String)
    case invalidStringFormat(key: String, expectedFormat: String)
    case valueTooShort(key: String, minLength: Int, actualLength: Int)
    case valueTooLong(key: String, maxLength: Int, actualLength: Int)
    case valueOutOfRange(key: String, min: Double?, max: Double?, actual: Double)
    case invalidArrayElement(index: Int, error: JSONValidationError)
    case customValidationFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input is empty"
        case .invalidJSON(let error):
            return "Invalid JSON: \(error.localizedDescription)"
        case .unexpectedType(let expected, let actual):
            return "Expected \(expected) but got \(actual)"
        case .missingRequiredKey(let key):
            return "Missing required key: '\(key)'"
        case .invalidValueType(let key, let expected, let actual):
            return "Key '\(key)' expected \(expected) but got \(actual)"
        case .invalidStringFormat(let key, let format):
            return "Key '\(key)' does not match expected format: \(format)"
        case .valueTooShort(let key, let min, let actual):
            return "Key '\(key)' is too short (min: \(min), actual: \(actual))"
        case .valueTooLong(let key, let max, let actual):
            return "Key '\(key)' is too long (max: \(max), actual: \(actual))"
        case .valueOutOfRange(let key, let min, let max, let actual):
            let range = "\(min.map { String($0) } ?? "∞")...\(max.map { String($0) } ?? "∞")"
            return "Key '\(key)' value \(actual) is out of range (\(range))"
        case .invalidArrayElement(let index, let error):
            return "Invalid element at index \(index): \(error.localizedDescription)"
        case .customValidationFailed(let message):
            return message
        }
    }
}

// MARK: - JSON Validation Result

struct JSONValidationResult {
    let isValid: Bool
    let errors: [JSONValidationError]
    let parsedValue: Any?

    static func success(_ value: Any) -> JSONValidationResult {
        JSONValidationResult(isValid: true, errors: [], parsedValue: value)
    }

    static func failure(_ errors: [JSONValidationError]) -> JSONValidationResult {
        JSONValidationResult(isValid: false, errors: errors, parsedValue: nil)
    }

    static func failure(_ error: JSONValidationError) -> JSONValidationResult {
        JSONValidationResult(isValid: false, errors: [error], parsedValue: nil)
    }
}

// MARK: - JSON Type

enum JSONType: String {
    case object = "Object"
    case array = "Array"
    case string = "String"
    case number = "Number"
    case boolean = "Boolean"
    case null = "Null"
    case unknown = "Unknown"

    static func from(_ value: Any) -> JSONType {
        switch value {
        case is [String: Any]:
            return .object
        case is [Any]:
            return .array
        case is String:
            return .string
        case let number as NSNumber:
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                return .boolean
            }
            return .number
        case is NSNull:
            return .null
        default:
            return .unknown
        }
    }
}

// MARK: - Field Validator

/// Validator for individual JSON fields
struct FieldValidator {
    let key: String
    let required: Bool
    let expectedType: JSONType?
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let regex: String?
    let customValidator: ((Any) -> JSONValidationError?)?

    init(
        key: String,
        required: Bool = true,
        expectedType: JSONType? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        regex: String? = nil,
        customValidator: ((Any) -> JSONValidationError?)? = nil
    ) {
        self.key = key
        self.required = required
        self.expectedType = expectedType
        self.minLength = minLength
        self.maxLength = maxLength
        self.minValue = minValue
        self.maxValue = maxValue
        self.regex = regex
        self.customValidator = customValidator
    }
}

// MARK: - JSON Validator

/// Comprehensive JSON validator using native Foundation JSONSerialization
///
/// ## Basic Validation
/// ```swift
/// let result = JSONValidator.shared.validate(string: jsonString)
/// if result.isValid {
///     print("Valid JSON: \(result.parsedValue!)")
/// } else {
///     for error in result.errors {
///         print("Error: \(error.localizedDescription)")
///     }
/// }
///
/// // Quick check
/// if JSONValidator.shared.isValid(string: jsonString) {
///     // Valid JSON
/// }
/// ```
///
/// ## Type Validation
/// ```swift
/// let dict = JSONValidator.shared.validateAsObject(string: jsonString)
/// let array = JSONValidator.shared.validateAsArray(string: jsonString)
/// let type = JSONValidator.shared.getType(from: jsonString) // .object, .array, .string, etc.
/// ```
///
/// ## Schema Validation
/// ```swift
/// let result = JSONValidator.shared.validate(string: jsonString, fields: [
///     .requiredString("name", minLength: 1, maxLength: 100),
///     .requiredNumber("age", min: 0, max: 150),
///     .optionalString("email"),
///     .email("contactEmail"),
///     .url("website", required: false),
///     .hexString("walletAddress", length: 40),  // 0x + 40 hex chars
///     .requiredBool("isActive"),
///     .requiredArray("tags"),
///     .requiredObject("metadata")
/// ])
/// ```
///
/// ## Array Element Validation
/// ```swift
/// let result = JSONValidator.shared.validateArray(
///     string: "[1, 2, 3]",
///     elementType: .number
/// )
/// ```
///
/// ## Codable Decoding
/// ```swift
/// struct User: Codable {
///     let name: String
///     let age: Int
/// }
/// let user = JSONValidator.shared.validateAndDecode(string: jsonString, as: User.self)
/// ```
///
/// ## Formatting Utilities
/// ```swift
/// let pretty = JSONValidator.shared.prettyPrint(string: minifiedJson)
/// let minified = JSONValidator.shared.minify(string: prettyJson)
/// ```
///
/// ## Available Field Validators
/// - `.requiredString(key)` - Required string field
/// - `.optionalString(key)` - Optional string field
/// - `.requiredNumber(key, min, max)` - Required number with optional range
/// - `.requiredBool(key)` - Required boolean field
/// - `.requiredArray(key)` - Required array field
/// - `.requiredObject(key)` - Required object field
/// - `.email(key)` - Email format validation
/// - `.url(key)` - URL format validation
/// - `.hexString(key, length)` - Hex string (blockchain addresses, etc.)
///
final class JSONValidator {

    // MARK: - Singleton

    static let shared = JSONValidator()

    private init() {}

    // MARK: - Basic Validation

    /// Validate if string is valid JSON
    /// - Parameter string: JSON string to validate
    /// - Returns: Validation result with parsed value
    func validate(string: String) -> JSONValidationResult {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.emptyInput)
        }

        guard let data = string.data(using: .utf8) else {
            return .failure(.invalidJSON(underlyingError: NSError(
                domain: "JSONValidator",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to UTF-8 data"]
            )))
        }

        return validate(data: data)
    }

    /// Validate if data is valid JSON
    /// - Parameter data: JSON data to validate
    /// - Returns: Validation result with parsed value
    func validate(data: Data) -> JSONValidationResult {
        guard !data.isEmpty else {
            return .failure(.emptyInput)
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return .success(jsonObject)
        } catch {
            return .failure(.invalidJSON(underlyingError: error))
        }
    }

    /// Quick check if string is valid JSON
    /// - Parameter string: JSON string to check
    /// - Returns: True if valid JSON
    func isValid(string: String) -> Bool {
        validate(string: string).isValid
    }

    /// Quick check if data is valid JSON
    /// - Parameter data: JSON data to check
    /// - Returns: True if valid JSON
    func isValid(data: Data) -> Bool {
        validate(data: data).isValid
    }

    // MARK: - Type Validation

    /// Validate JSON and ensure it's an object (dictionary)
    /// - Parameter string: JSON string
    /// - Returns: Parsed dictionary or nil
    func validateAsObject(string: String) -> [String: Any]? {
        let result = validate(string: string)
        return result.parsedValue as? [String: Any]
    }

    /// Validate JSON and ensure it's an array
    /// - Parameter string: JSON string
    /// - Returns: Parsed array or nil
    func validateAsArray(string: String) -> [Any]? {
        let result = validate(string: string)
        return result.parsedValue as? [Any]
    }

    /// Validate JSON type
    /// - Parameters:
    ///   - string: JSON string
    ///   - expectedType: Expected JSON type
    /// - Returns: Validation result
    func validate(string: String, expectedType: JSONType) -> JSONValidationResult {
        let result = validate(string: string)

        guard result.isValid, let value = result.parsedValue else {
            return result
        }

        let actualType = JSONType.from(value)
        if actualType != expectedType {
            return .failure(.unexpectedType(expected: expectedType.rawValue, actual: actualType.rawValue))
        }

        return result
    }

    // MARK: - Schema Validation

    /// Validate JSON object against field validators
    /// - Parameters:
    ///   - string: JSON string
    ///   - fields: Array of field validators
    /// - Returns: Validation result
    func validate(string: String, fields: [FieldValidator]) -> JSONValidationResult {
        let result = validate(string: string)

        guard result.isValid, let dict = result.parsedValue as? [String: Any] else {
            if result.isValid {
                return .failure(.unexpectedType(expected: JSONType.object.rawValue, actual: JSONType.from(result.parsedValue ?? NSNull()).rawValue))
            }
            return result
        }

        return validate(object: dict, fields: fields)
    }

    /// Validate dictionary against field validators
    /// - Parameters:
    ///   - object: Dictionary to validate
    ///   - fields: Array of field validators
    /// - Returns: Validation result
    func validate(object: [String: Any], fields: [FieldValidator]) -> JSONValidationResult {
        var errors: [JSONValidationError] = []

        for field in fields {
            if let error = validateField(object: object, validator: field) {
                errors.append(error)
            }
        }

        if errors.isEmpty {
            return .success(object)
        } else {
            return .failure(errors)
        }
    }

    // MARK: - Field Validation

    private func validateField(object: [String: Any], validator: FieldValidator) -> JSONValidationError? {
        let value = object[validator.key]

        // Check required
        if value == nil || value is NSNull {
            if validator.required {
                return .missingRequiredKey(key: validator.key)
            }
            return nil
        }

        let actualValue = value!

        // Check type
        if let expectedType = validator.expectedType {
            let actualType = JSONType.from(actualValue)
            if actualType != expectedType {
                return .invalidValueType(
                    key: validator.key,
                    expected: expectedType.rawValue,
                    actual: actualType.rawValue
                )
            }
        }

        // String validations
        if let stringValue = actualValue as? String {
            // Min length
            if let minLength = validator.minLength, stringValue.count < minLength {
                return .valueTooShort(key: validator.key, minLength: minLength, actualLength: stringValue.count)
            }

            // Max length
            if let maxLength = validator.maxLength, stringValue.count > maxLength {
                return .valueTooLong(key: validator.key, maxLength: maxLength, actualLength: stringValue.count)
            }

            // Regex
            if let pattern = validator.regex {
                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(stringValue.startIndex..., in: stringValue)
                if regex?.firstMatch(in: stringValue, options: [], range: range) == nil {
                    return .invalidStringFormat(key: validator.key, expectedFormat: pattern)
                }
            }
        }

        // Number validations
        if let numberValue = actualValue as? NSNumber {
            let doubleValue = numberValue.doubleValue

            if validator.minValue != nil || validator.maxValue != nil {
                if let min = validator.minValue, doubleValue < min {
                    return .valueOutOfRange(key: validator.key, min: min, max: validator.maxValue, actual: doubleValue)
                }
                if let max = validator.maxValue, doubleValue > max {
                    return .valueOutOfRange(key: validator.key, min: validator.minValue, max: max, actual: doubleValue)
                }
            }
        }

        // Custom validation
        if let customValidator = validator.customValidator {
            return customValidator(actualValue)
        }

        return nil
    }

    // MARK: - Array Validation

    /// Validate JSON array elements
    /// - Parameters:
    ///   - string: JSON string containing array
    ///   - elementType: Expected type for each element
    ///   - elementValidator: Optional validator for each element
    /// - Returns: Validation result
    func validateArray(
        string: String,
        elementType: JSONType? = nil,
        elementValidator: ((Any, Int) -> JSONValidationError?)? = nil
    ) -> JSONValidationResult {
        let result = validate(string: string, expectedType: .array)

        guard result.isValid, let array = result.parsedValue as? [Any] else {
            return result
        }

        var errors: [JSONValidationError] = []

        for (index, element) in array.enumerated() {
            // Type check
            if let expectedType = elementType {
                let actualType = JSONType.from(element)
                if actualType != expectedType {
                    let error = JSONValidationError.invalidValueType(
                        key: "[\(index)]",
                        expected: expectedType.rawValue,
                        actual: actualType.rawValue
                    )
                    errors.append(.invalidArrayElement(index: index, error: error))
                }
            }

            // Custom validation
            if let validator = elementValidator, let error = validator(element, index) {
                errors.append(.invalidArrayElement(index: index, error: error))
            }
        }

        if errors.isEmpty {
            return .success(array)
        } else {
            return .failure(errors)
        }
    }

    // MARK: - Convenience Methods

    /// Validate and decode JSON to Codable type
    /// - Parameters:
    ///   - string: JSON string
    ///   - type: Target Codable type
    /// - Returns: Decoded object or nil
    func validateAndDecode<T: Codable>(string: String, as type: T.Type) -> T? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }

    /// Validate and decode JSON data to Codable type
    /// - Parameters:
    ///   - data: JSON data
    ///   - type: Target Codable type
    /// - Returns: Decoded object or nil
    func validateAndDecode<T: Codable>(data: Data, as type: T.Type) -> T? {
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Get JSON type from string
    /// - Parameter string: JSON string
    /// - Returns: JSON type or nil if invalid
    func getType(from string: String) -> JSONType? {
        let result = validate(string: string)
        guard let value = result.parsedValue else {
            return nil
        }
        return JSONType.from(value)
    }

    /// Pretty print JSON string
    /// - Parameter string: JSON string
    /// - Returns: Formatted JSON string or nil if invalid
    func prettyPrint(string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }

    /// Minify JSON string (remove whitespace)
    /// - Parameter string: JSON string
    /// - Returns: Minified JSON string or nil if invalid
    func minify(string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let minifiedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
              let minifiedString = String(data: minifiedData, encoding: .utf8) else {
            return nil
        }
        return minifiedString
    }
}

// MARK: - Common Field Validators

extension FieldValidator {

    /// Create a required string field validator
    static func requiredString(_ key: String, minLength: Int? = nil, maxLength: Int? = nil) -> FieldValidator {
        FieldValidator(key: key, required: true, expectedType: .string, minLength: minLength, maxLength: maxLength)
    }

    /// Create an optional string field validator
    static func optionalString(_ key: String, minLength: Int? = nil, maxLength: Int? = nil) -> FieldValidator {
        FieldValidator(key: key, required: false, expectedType: .string, minLength: minLength, maxLength: maxLength)
    }

    /// Create a required number field validator
    static func requiredNumber(_ key: String, min: Double? = nil, max: Double? = nil) -> FieldValidator {
        FieldValidator(key: key, required: true, expectedType: .number, minValue: min, maxValue: max)
    }

    /// Create an optional number field validator
    static func optionalNumber(_ key: String, min: Double? = nil, max: Double? = nil) -> FieldValidator {
        FieldValidator(key: key, required: false, expectedType: .number, minValue: min, maxValue: max)
    }

    /// Create a required boolean field validator
    static func requiredBool(_ key: String) -> FieldValidator {
        FieldValidator(key: key, required: true, expectedType: .boolean)
    }

    /// Create an optional boolean field validator
    static func optionalBool(_ key: String) -> FieldValidator {
        FieldValidator(key: key, required: false, expectedType: .boolean)
    }

    /// Create a required array field validator
    static func requiredArray(_ key: String) -> FieldValidator {
        FieldValidator(key: key, required: true, expectedType: .array)
    }

    /// Create a required object field validator
    static func requiredObject(_ key: String) -> FieldValidator {
        FieldValidator(key: key, required: true, expectedType: .object)
    }

    /// Create an email field validator
    static func email(_ key: String, required: Bool = true) -> FieldValidator {
        FieldValidator(
            key: key,
            required: required,
            expectedType: .string,
            regex: "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        )
    }

    /// Create a URL field validator
    static func url(_ key: String, required: Bool = true) -> FieldValidator {
        FieldValidator(
            key: key,
            required: required,
            expectedType: .string,
            customValidator: { value in
                guard let urlString = value as? String,
                      URL(string: urlString) != nil else {
                    return .invalidStringFormat(key: key, expectedFormat: "valid URL")
                }
                return nil
            }
        )
    }

    /// Create a hex string field validator (for blockchain addresses, etc.)
    static func hexString(_ key: String, required: Bool = true, length: Int? = nil) -> FieldValidator {
        var pattern = "^0x[0-9a-fA-F]+"
        if let len = length {
            pattern = "^0x[0-9a-fA-F]{\(len)}$"
        } else {
            pattern += "$"
        }

        return FieldValidator(
            key: key,
            required: required,
            expectedType: .string,
            regex: pattern
        )
    }
}
