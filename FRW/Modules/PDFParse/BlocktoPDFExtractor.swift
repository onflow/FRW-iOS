//
//  BlocktoPDFExtractor.swift
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
    case invalidJSON(errors: [JSONValidationError])
    case unexpectedError(String)

    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No PDF file was selected"
        case .pdfParsingFailed(let error):
            return "Failed to parse PDF: \(error.localizedDescription)"
        case .emptyContent:
            return "PDF contains no text content"
        case .invalidJSON(let errors):
            let errorMessages = errors.map { $0.localizedDescription }.joined(separator: "; ")
            return "Invalid JSON format: \(errorMessages)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
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
///
/// ## Usage with SwiftUI
/// ```swift
/// struct ContentView: View {
///     @StateObject private var extractor = BloctoPDFExtractor()
///
///     var body: some View {
///         VStack {
///             Button("Select PDF") {
///                 extractor.presentPicker()
///             }
///
///             if extractor.isProcessing {
///                 ProgressView("Processing...")
///             }
///
///             if let result = extractor.result {
///                 Text("JSON extracted successfully!")
///                 Text(result.formattedJSON)
///                     .font(.system(.caption, design: .monospaced))
///             }
///
///             if let error = extractor.error {
///                 Text("Error: \(error.localizedDescription)")
///                     .foregroundColor(.red)
///             }
///         }
///         .sheet(isPresented: $extractor.showPicker) {
///             extractor.documentPicker
///         }
///     }
/// }
/// ```
///
/// ## Programmatic Usage
/// ```swift
/// let extractor = BloctoPDFExtractor()
///
/// // Extract from URL directly
/// let result = try await extractor.extract(from: pdfURL)
/// print(result.formattedJSON)
///
/// // Extract from DocumentPickerResult
/// let result = try await extractor.extract(from: pickerResult)
/// ```
///
/// ## With Completion Handler
/// ```swift
/// extractor.extract(from: url) { result in
///     switch result {
///     case .success(let extraction):
///         print(extraction.formattedJSON)
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
///
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
    private let jsonValidator = JSONValidator.shared

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
        // Sometimes PDF text may have extra content, try to find JSON boundaries
        let jsonText = extractJSONString(from: rawText)

        // Step 4: Validate JSON
        let validationResult = jsonValidator.validate(string: jsonText)

        guard validationResult.isValid, let jsonValue = validationResult.parsedValue else {
            throw PDFExtractionError.invalidJSON(errors: validationResult.errors)
        }

        // Step 5: Format JSON
        guard let formattedJSON = jsonValidator.prettyPrint(string: jsonText) else {
            throw PDFExtractionError.invalidJSON(errors: [.customValidationFailed(message: "Failed to format JSON")])
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

    /// Try to extract JSON string from raw text
    /// Handles cases where PDF might have extra text before/after JSON
    private func extractJSONString(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it starts with { or [, assume it's JSON
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            // Find matching closing bracket
            if let jsonString = findJSONBoundary(in: trimmed) {
                return jsonString
            }
        }

        // Try to find JSON object in text
        if let objectRange = trimmed.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            let potentialJSON = String(trimmed[objectRange])
            if jsonValidator.isValid(string: potentialJSON) {
                return potentialJSON
            }
        }

        // Try to find JSON array in text
        if let arrayRange = trimmed.range(of: "\\[[\\s\\S]*\\]", options: .regularExpression) {
            let potentialJSON = String(trimmed[arrayRange])
            if jsonValidator.isValid(string: potentialJSON) {
                return potentialJSON
            }
        }

        // Return original text as fallback
        return trimmed
    }

    /// Find JSON boundary by matching brackets
    private func findJSONBoundary(in text: String) -> String? {
        let openBracket: Character = text.first == "{" ? "{" : "["
        let closeBracket: Character = openBracket == "{" ? "}" : "]"

        var depth = 0
        var inString = false
        var escaped = false

        for (index, char) in text.enumerated() {
            if escaped {
                escaped = false
                continue
            }

            if char == "\\" {
                escaped = true
                continue
            }

            if char == "\"" {
                inString.toggle()
                continue
            }

            if !inString {
                if char == openBracket {
                    depth += 1
                } else if char == closeBracket {
                    depth -= 1
                    if depth == 0 {
                        let endIndex = text.index(text.startIndex, offsetBy: index + 1)
                        return String(text[..<endIndex])
                    }
                }
            }
        }

        return nil
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

// MARK: - SwiftUI View Extension (Disabled)

// extension View {
//
//     /// Add PDF extraction capability to any view
//     /// - Parameters:
//     ///   - extractor: BloctoPDFExtractor instance
//     ///   - onResult: Callback when extraction succeeds
//     ///   - onError: Callback when extraction fails
//     func pdfExtractor(
//         _ extractor: BloctoPDFExtractor,
//         onResult: @escaping (PDFExtractionResult) -> Void,
//         onError: ((PDFExtractionError) -> Void)? = nil
//     ) -> some View {
//         self
//             .sheet(isPresented: Binding(
//                 get: { extractor.showPicker },
//                 set: { extractor.showPicker = $0 }
//             )) {
//                 extractor.documentPicker
//             }
//             .onChange(of: extractor.result) { _, newResult in
//                 if let result = newResult {
//                     onResult(result)
//                 }
//             }
//             .onChange(of: extractor.error) { _, newError in
//                 if let error = newError {
//                     onError?(error)
//                 }
//             }
//     }
// }
