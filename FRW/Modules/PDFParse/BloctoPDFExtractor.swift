//
//  BloctoPDFExtractor.swift
//  FRW
//
//  Created by cat on 12/15/25.
//

import Foundation
import SwiftUI

// MARK: - Extraction Error

enum PDFExtractionError: Error, LocalizedError {
    case noFileSelected
    case pdfParsingFailed(Error)
    case emptyContent
    case invalidJSON(Error?)
    case unexpectedError(String)

    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No PDF file was selected"
        case .pdfParsingFailed(let error):
            return "Failed to parse PDF: \(error.localizedDescription)"
        case .emptyContent:
            return "PDF contains no text content"
        case .invalidJSON(let error):
            if let error = error {
                return "Invalid JSON format: \(error.localizedDescription)"
            }
            return "Invalid JSON format"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
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

// MARK: - Extraction Result

/// Result of PDF to JSON extraction
struct PDFExtractionResult {
    /// Original PDF file info
    let pdfInfo: PDFDocumentInfo

    /// Raw text extracted from PDF
    let rawText: String

    /// Validated and formatted JSON string
    let formattedJSON: String

    /// Parsed JSON value (dictionary or array)
    let jsonValue: Any

    /// JSON type detected
    let jsonType: JSONType

    /// Extraction metadata
    let extractedAt: Date

    init(pdfInfo: PDFDocumentInfo, rawText: String, formattedJSON: String, jsonValue: Any, jsonType: JSONType) {
        self.pdfInfo = pdfInfo
        self.rawText = rawText
        self.formattedJSON = formattedJSON
        self.jsonValue = jsonValue
        self.jsonType = jsonType
        self.extractedAt = Date()
    }
}

// MARK: - Blocto PDF Extractor

/// Complete workflow for extracting JSON from PDF files
final class BloctoPDFExtractor: ObservableObject {

    // MARK: - Published Properties

    /// Whether the document picker is shown
    @Published var showPicker = false

    /// Whether extraction is in progress
    @Published var isProcessing = false

    /// Extraction result (nil if not yet extracted or failed)
    @Published var result: PDFExtractionResult?

    /// Extraction error (nil if successful)
    @Published var error: PDFExtractionError?

    // MARK: - Private Properties

    private let pdfParser = PDFParser.shared

    // MARK: - Initialization

    init() {}

    // MARK: - Document Picker

    /// Document picker view for SwiftUI integration
    var documentPicker: DocumentPicker {
        DocumentPicker.pdf(
            allowsMultipleSelection: false,
            onPick: { [weak self] results in
                self?.showPicker = false
                guard let first = results.first else {
                    self?.error = .noFileSelected
                    return
                }
                self?.processFile(result: first)
            },
            onCancel: { [weak self] in
                self?.showPicker = false
            }
        )
    }

    /// Present the document picker
    func presentPicker() {
        error = nil
        result = nil
        showPicker = true
    }

    // MARK: - Extraction Methods

    /// Extract JSON from PDF URL asynchronously
    /// - Parameter url: PDF file URL
    /// - Returns: Extraction result
    func extract(from url: URL) async throws -> PDFExtractionResult {
        return try await withCheckedThrowingContinuation { continuation in
            extract(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Extract JSON from DocumentPickerResult asynchronously
    /// - Parameter pickerResult: Result from DocumentPicker
    /// - Returns: Extraction result
    func extract(from pickerResult: DocumentPickerResult) async throws -> PDFExtractionResult {
        return try await extract(from: pickerResult.url)
    }

    /// Extract JSON from PDF URL with completion handler
    /// - Parameters:
    ///   - url: PDF file URL
    ///   - completion: Completion handler with result
    func extract(from url: URL, completion: @escaping (Result<PDFExtractionResult, PDFExtractionError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let result = try self.performExtraction(from: url)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch let error as PDFExtractionError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.unexpectedError(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func processFile(result: DocumentPickerResult) {
        isProcessing = true
        error = nil
        self.result = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let extractionResult = try self.performExtraction(from: result.url)
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.result = extractionResult
                }
            } catch let extractionError as PDFExtractionError {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.error = extractionError
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.error = .unexpectedError(error.localizedDescription)
                }
            }
        }
    }

    private func performExtraction(from url: URL) throws -> PDFExtractionResult {
        // Step 1: Parse PDF
        let parseResult: PDFParseResult
        do {
            parseResult = try pdfParser.parse(from: url)
        } catch {
            throw PDFExtractionError.pdfParsingFailed(error)
        }

        // Step 2: Get text content
        let rawText = parseResult.fullText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawText.isEmpty else {
            throw PDFExtractionError.emptyContent
        }

        // Step 3: Try to extract JSON from text
        let jsonText = BloctoPDFExtractor.extractJSON(from: rawText)

        // Step 4: Validate and parse JSON using native JSONSerialization
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw PDFExtractionError.invalidJSON(nil)
        }

        let jsonValue: Any
        do {
            jsonValue = try JSONSerialization.jsonObject(with: jsonData, options: [.fragmentsAllowed])
        } catch {
            throw PDFExtractionError.invalidJSON(error)
        }

        // Step 5: Format JSON (pretty print)
        let formattedJSON: String
        do {
            let prettyData = try JSONSerialization.data(withJSONObject: jsonValue, options: [.prettyPrinted, .sortedKeys])
            guard let prettyString = String(data: prettyData, encoding: .utf8) else {
                throw PDFExtractionError.invalidJSON(nil)
            }
            formattedJSON = prettyString
        } catch {
            throw PDFExtractionError.invalidJSON(error)
        }

        // Step 6: Get JSON type
        let jsonType = JSONType.from(jsonValue)

        return PDFExtractionResult(
            pdfInfo: parseResult.info,
            rawText: rawText,
            formattedJSON: formattedJSON,
            jsonValue: jsonValue,
            jsonType: jsonType
        )
    }

    // MARK: - Utility Methods

    /// Reset extractor state
    func reset() {
        showPicker = false
        isProcessing = false
        result = nil
        error = nil
    }

    /// Get result as dictionary (if JSON is object)
    func resultAsDictionary() -> [String: Any]? {
        result?.jsonValue as? [String: Any]
    }

    /// Get result as array (if JSON is array)
    func resultAsArray() -> [Any]? {
        result?.jsonValue as? [Any]
    }

    /// Decode result to Codable type
    func decodeResult<T: Codable>(as type: T.Type) -> T? {
        guard let json = result?.formattedJSON,
              let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Static JSON Extraction Methods

extension BloctoPDFExtractor {

    /// Check if a string is valid JSON using native JSONSerialization
    /// - Parameter string: String to validate
    /// - Returns: True if valid JSON
    static func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil
    }

    /// Parse JSON string and return the parsed object
    /// - Parameter string: JSON string to parse
    /// - Returns: Parsed JSON object or nil if invalid
    static func parseJSON(_ string: String) -> Any? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    /// Minify JSON string (remove whitespace)
    /// - Parameter string: JSON string to minify
    /// - Returns: Minified JSON string or nil if invalid
    static func minifyJSON(_ string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let minifiedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
              let minifiedString = String(data: minifiedData, encoding: .utf8) else {
            return nil
        }
        return minifiedString
    }

    /// Pretty print JSON string
    /// - Parameter string: JSON string to format
    /// - Returns: Formatted JSON string or nil if invalid
    static func prettyPrintJSON(_ string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        return prettyString
    }

    /// Extract JSON string from raw text
    /// Handles cases where PDF might have multiple JSON blocks or extra text
    /// - Parameter text: Raw text that may contain JSON
    /// - Returns: Extracted JSON string or original text as fallback
    static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find all potential JSON objects starting with '{'
        let allJSONBlocks = findAllJSONBlocks(in: trimmed)

        // Try each block and return the first valid one
        for block in allJSONBlocks {
            if isValidJSON(block) {
                return block
            }
        }

        // If no valid JSON found, try the whole text
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            if let jsonString = findJSONBoundary(in: trimmed, startIndex: trimmed.startIndex) {
                if isValidJSON(jsonString) {
                    return jsonString
                }
            }
        }

        // Return original text as fallback
        return trimmed
    }

    /// Find all potential JSON blocks in text
    /// Returns array of JSON strings found at each '{' position
    /// - Parameter text: Text to search for JSON blocks
    /// - Returns: Array of potential JSON strings
    static func findAllJSONBlocks(in text: String) -> [String] {
        var blocks: [String] = []
        var searchStart = text.startIndex

        while searchStart < text.endIndex {
            // Find next '{' character
            guard let braceIndex = text[searchStart...].firstIndex(of: "{") else {
                break
            }

            // Try to extract JSON starting from this position
            if let jsonBlock = findJSONBoundary(in: text, startIndex: braceIndex) {
                blocks.append(jsonBlock)
            }

            // Move search position forward
            searchStart = text.index(after: braceIndex)
        }

        return blocks
    }

    /// Find JSON boundary by matching brackets starting from a given index
    /// - Parameters:
    ///   - text: Text containing JSON
    ///   - startIndex: Index to start searching from
    /// - Returns: Extracted JSON string or nil if not found
    static func findJSONBoundary(in text: String, startIndex: String.Index) -> String? {
        guard startIndex < text.endIndex else { return nil }

        let firstChar = text[startIndex]
        guard firstChar == "{" || firstChar == "[" else { return nil }

        let openBracket: Character = firstChar == "{" ? "{" : "["
        let closeBracket: Character = openBracket == "{" ? "}" : "]"

        var depth = 0
        var inString = false
        var escaped = false
        var currentIndex = startIndex

        while currentIndex < text.endIndex {
            let char = text[currentIndex]

            if escaped {
                escaped = false
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\\" && inString {
                escaped = true
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\"" {
                inString.toggle()
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if !inString {
                if char == openBracket {
                    depth += 1
                } else if char == closeBracket {
                    depth -= 1
                    if depth == 0 {
                        let endIndex = text.index(after: currentIndex)
                        return String(text[startIndex..<endIndex])
                    }
                }
            }

            currentIndex = text.index(after: currentIndex)
        }

        return nil
    }
}
