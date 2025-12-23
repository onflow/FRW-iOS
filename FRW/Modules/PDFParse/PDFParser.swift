//
//  PDFParser.swift
//  FRW
//
//  Created by cat on 12/15/25.
//

import Foundation
import PDFKit

// MARK: - PDF Parser Error

enum PDFParserError: Error, LocalizedError, Equatable {
    case fileNotFound
    case invalidPDF
    case emptyDocument
    case pageExtractionFailed(page: Int)
    case textExtractionFailed
    case passwordRequired
    case incorrectPassword

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "PDF file not found at the specified path"
        case .invalidPDF:
            return "The file is not a valid PDF document"
        case .emptyDocument:
            return "The PDF document contains no pages"
        case .pageExtractionFailed(let page):
            return "Failed to extract content from page \(page)"
        case .textExtractionFailed:
            return "Failed to extract text from PDF"
        case .passwordRequired:
            return "This PDF is password protected. Please provide a password."
        case .incorrectPassword:
            return "The password provided is incorrect."
        }
    }
}

// MARK: - PDF Page Content

/// Content extracted from a single PDF page
struct PDFPageContent {
    let pageNumber: Int
    let text: String
    let bounds: CGRect

    /// Check if page has meaningful text content
    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - PDF Document Info

/// Metadata and information about a PDF document
struct PDFDocumentInfo {
    let url: URL
    let fileName: String
    let pageCount: Int
    let title: String?
    let author: String?
    let subject: String?
    let creator: String?
    let creationDate: Date?
    let modificationDate: Date?
    let isEncrypted: Bool
    let isLocked: Bool
    let allowsCopying: Bool
    let allowsPrinting: Bool
    let fileSize: Int64?

    init(document: PDFDocument, url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.pageCount = document.pageCount

        // Extract metadata from document attributes
        let attributes = document.documentAttributes ?? [:]

        self.title = attributes[PDFDocumentAttribute.titleAttribute] as? String
        self.author = attributes[PDFDocumentAttribute.authorAttribute] as? String
        self.subject = attributes[PDFDocumentAttribute.subjectAttribute] as? String
        self.creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String
        self.creationDate = attributes[PDFDocumentAttribute.creationDateAttribute] as? Date
        self.modificationDate = attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date

        self.isEncrypted = document.isEncrypted
        self.isLocked = document.isLocked
        self.allowsCopying = document.allowsCopying
        self.allowsPrinting = document.allowsPrinting

        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            self.fileSize = size
        } else {
            self.fileSize = nil
        }
    }
}

// MARK: - PDF Parse Result

/// Complete result of parsing a PDF document
struct PDFParseResult {
    let info: PDFDocumentInfo
    let pages: [PDFPageContent]
    let fullText: String

    /// Total character count across all pages
    var totalCharacters: Int {
        fullText.count
    }

    /// Total word count (approximate)
    var wordCount: Int {
        fullText.split(separator: " ").count
    }

    /// Pages that contain text content
    var pagesWithContent: [PDFPageContent] {
        pages.filter { $0.hasContent }
    }
}

// MARK: - PDF Parser

/// Native iOS PDF parser using PDFKit
final class PDFParser {

    // MARK: - Singleton

    static let shared = PDFParser()

    private init() {}

    // MARK: - Public Methods

    /// Parse PDF from DocumentPickerResult
    /// - Parameters:
    ///   - result: Result from DocumentPicker
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Parsed PDF content
    func parse(from result: DocumentPickerResult, password: String? = nil) throws -> PDFParseResult {
        return try parse(from: result.url, password: password)
    }

    /// Parse PDF from URL
    /// - Parameters:
    ///   - url: File URL to the PDF
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Parsed PDF content
    func parse(from url: URL, password: String? = nil) throws -> PDFParseResult {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFParserError.fileNotFound
        }

        // Load PDF document
        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.invalidPDF
        }

        // Handle encryption
        if document.isEncrypted {
            if document.isLocked {
                if let password = password {
                    if !document.unlock(withPassword: password) {
                        throw PDFParserError.incorrectPassword
                    }
                } else {
                    throw PDFParserError.passwordRequired
                }
            }
        }

        // Check if document has pages
        guard document.pageCount > 0 else {
            throw PDFParserError.emptyDocument
        }

        // Extract document info
        let info = PDFDocumentInfo(document: document, url: url)

        // Extract pages content
        var pages: [PDFPageContent] = []
        var fullTextParts: [String] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                continue
            }

            let pageText = page.string ?? ""
            let bounds = page.bounds(for: .mediaBox)

            let pageContent = PDFPageContent(
                pageNumber: pageIndex + 1,
                text: pageText,
                bounds: bounds
            )

            pages.append(pageContent)

            if !pageText.isEmpty {
                fullTextParts.append(pageText)
            }
        }

        let fullText = fullTextParts.joined(separator: "\n\n")

        return PDFParseResult(
            info: info,
            pages: pages,
            fullText: fullText
        )
    }

    /// Extract only text from PDF (lightweight operation)
    /// - Parameters:
    ///   - url: File URL to the PDF
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Full text content
    func extractText(from url: URL, password: String? = nil) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFParserError.fileNotFound
        }

        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.invalidPDF
        }
        
        // Handle encryption
        if document.isEncrypted {
            if document.isLocked {
                if let password = password {
                    if !document.unlock(withPassword: password) {
                        throw PDFParserError.incorrectPassword
                    }
                } else {
                    throw PDFParserError.passwordRequired
                }
            }
        }

        guard document.pageCount > 0 else {
            throw PDFParserError.emptyDocument
        }

        // Extract text from each page with proper ordering
        var allText: [String] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                continue
            }

            let pageText = extractTextPreservingOrder(from: page)
            if !pageText.isEmpty {
                allText.append(pageText)
            }
        }

        guard !allText.isEmpty else {
            throw PDFParserError.textExtractionFailed
        }

        return allText.joined(separator: "\n\n")
    }

    /// Extract text from a page preserving top-to-bottom, left-to-right order
    /// - Parameter page: PDF page to extract from
    /// - Returns: Extracted text with preserved order
    private func extractTextPreservingOrder(from page: PDFPage) -> String {
      let pageBounds = page.bounds(for: .mediaBox)

      // Get selection for entire page
      guard let selection = page.selection(for: pageBounds) else {
          return page.string ?? ""
      }

      // Get selections by line
      let lineSelections = selection.selectionsByLine()
      guard !lineSelections.isEmpty else {
          return page.string ?? ""
      }

      // Sort lines by Y position (top to bottom in PDF coordinates)
      // PDF coordinates: origin at bottom-left, Y increases upward
      // So we sort by descending Y to get top-to-bottom order
      let sortedLines = lineSelections.sorted { sel1, sel2 in
          let bounds1 = sel1.bounds(for: page)
          let bounds2 = sel2.bounds(for: page)

          // Compare Y positions (higher Y = higher on page = should come first)
          let yDiff = bounds2.midY - bounds1.midY
          if abs(yDiff) > 2 {
              // Different lines - sort by Y (descending for top-to-bottom)
              return bounds1.midY > bounds2.midY
          }

          // Same line - sort by X (ascending for left-to-right)
          return bounds1.minX < bounds2.minX
      }

      // Extract text from sorted selections
      let lines = sortedLines.compactMap { $0.string }
      return lines.joined(separator: "\n")
    }

    /// Get document info without full text extraction
    /// - Parameter url: File URL to the PDF
    /// - Returns: Document metadata and info
    func getDocumentInfo(from url: URL) throws -> PDFDocumentInfo {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFParserError.fileNotFound
        }

        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.invalidPDF
        }

        return PDFDocumentInfo(document: document, url: url)
    }

    /// Extract text from specific page range
    /// - Parameters:
    ///   - url: File URL to the PDF
    ///   - range: Page range (1-based index)
    /// - Returns: Array of page contents
    func extractPages(from url: URL, range: ClosedRange<Int>) throws -> [PDFPageContent] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFParserError.fileNotFound
        }

        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.invalidPDF
        }

        var pages: [PDFPageContent] = []

        // Convert to 0-based index and clamp to valid range
        let startIndex = max(0, range.lowerBound - 1)
        let endIndex = min(document.pageCount - 1, range.upperBound - 1)

        for pageIndex in startIndex...endIndex {
            guard let page = document.page(at: pageIndex) else {
                throw PDFParserError.pageExtractionFailed(page: pageIndex + 1)
            }

            let pageContent = PDFPageContent(
                pageNumber: pageIndex + 1,
                text: page.string ?? "",
                bounds: page.bounds(for: .mediaBox)
            )

            pages.append(pageContent)
        }

        return pages
    }

    /// Get page count without loading full document content
    /// - Parameter url: File URL to the PDF
    /// - Returns: Number of pages
    func getPageCount(from url: URL) throws -> Int {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFParserError.fileNotFound
        }

        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.invalidPDF
        }

        return document.pageCount
    }

    /// Check if URL points to a valid PDF
    /// - Parameter url: File URL to check
    /// - Returns: True if valid PDF
    func isValidPDF(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }

        return PDFDocument(url: url) != nil
    }

    /// Check if PDF is password protected and locked
    /// - Parameter url: File URL to the PDF
    /// - Returns: True if PDF needs password
    func isPasswordProtected(at url: URL) -> Bool {
        guard let document = PDFDocument(url: url) else {
            return false
        }
        return document.isEncrypted && document.isLocked
    }
}

// MARK: - Async Support

extension PDFParser {

    /// Parse PDF asynchronously
    /// - Parameters:
    ///   - url: File URL to the PDF
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Parsed PDF content
    func parseAsync(from url: URL, password: String? = nil) async throws -> PDFParseResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.parse(from: url, password: password)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Parse PDF from DocumentPickerResult asynchronously
    /// - Parameters:
    ///   - result: Result from DocumentPicker
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Parsed PDF content
    func parseAsync(from result: DocumentPickerResult, password: String? = nil) async throws -> PDFParseResult {
        return try await parseAsync(from: result.url, password: password)
    }

    /// Extract text asynchronously
    /// - Parameters:
    ///   - url: File URL to the PDF
    ///   - password: Optional password for encrypted PDFs
    /// - Returns: Full text content
    func extractTextAsync(from url: URL, password: String? = nil) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let text = try self.extractText(from: url, password: password)
                    continuation.resume(returning: text)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
