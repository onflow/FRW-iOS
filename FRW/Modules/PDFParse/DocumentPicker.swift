//
//  DocumentPicker.swift
//  FRW
//
//  Created by cat on 12/15/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - File Type Configuration

/// Supported file types for document picker
enum DocumentFileType: CaseIterable {
    case pdf
    case png
    case jpeg
    case image
    case all

    var utType: UTType {
        switch self {
        case .pdf:
            return .pdf
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .image:
            return .image
        case .all:
            return .item
        }
    }

    var displayName: String {
        switch self {
        case .pdf:
            return "PDF"
        case .png:
            return "PNG"
        case .jpeg:
            return "JPEG"
        case .image:
            return "Images"
        case .all:
            return "All Files"
        }
    }
}

// MARK: - Document Picker Result

/// Result returned from document picker
struct DocumentPickerResult {
    let url: URL
    let fileName: String
    let fileType: UTType?
    let fileSize: Int64?

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.fileType = UTType(filenameExtension: url.pathExtension)

        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            self.fileSize = size
        } else {
            self.fileSize = nil
        }
    }
}

// MARK: - Document Picker View (SwiftUI)

/// SwiftUI wrapper for UIDocumentPickerViewController
struct DocumentPicker: UIViewControllerRepresentable {

    // MARK: - Properties

    /// File types allowed for selection
    let allowedTypes: [UTType]

    /// Allow multiple file selection
    let allowsMultipleSelection: Bool

    /// Callback when files are selected
    let onPick: ([DocumentPickerResult]) -> Void

    /// Callback when picker is cancelled
    let onCancel: (() -> Void)?

    // MARK: - Initialization

    /// Initialize with specific file types
    /// - Parameters:
    ///   - fileTypes: Array of DocumentFileType to allow
    ///   - allowsMultipleSelection: Whether to allow selecting multiple files
    ///   - onPick: Callback with selected file results
    ///   - onCancel: Optional callback when cancelled
    init(
        fileTypes: [DocumentFileType],
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.allowedTypes = fileTypes.map { $0.utType }
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onPick = onPick
        self.onCancel = onCancel
    }

    /// Initialize with UTType array directly
    /// - Parameters:
    ///   - utTypes: Array of UTType to allow
    ///   - allowsMultipleSelection: Whether to allow selecting multiple files
    ///   - onPick: Callback with selected file results
    ///   - onCancel: Optional callback when cancelled
    init(
        utTypes: [UTType],
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.allowedTypes = utTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onPick = onPick
        self.onCancel = onCancel
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let results = urls.compactMap { url -> DocumentPickerResult? in
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    return nil
                }

                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                // Copy file to temporary location for processing
                let tempURL = copyToTemporaryLocation(url: url)
                return DocumentPickerResult(url: tempURL ?? url)
            }

            parent.onPick(results)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel?()
        }

        /// Copy file to temporary directory for safe access
        private func copyToTemporaryLocation(url: URL) -> URL? {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)

            // Remove existing file if present
            try? FileManager.default.removeItem(at: tempURL)

            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                return tempURL
            } catch {
                print("Failed to copy file to temporary location: \(error)")
                return nil
            }
        }
    }
}

// MARK: - Convenience Static Methods

extension DocumentPicker {

    /// Create picker for PDF files only
    static func pdf(
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> DocumentPicker {
        DocumentPicker(
            fileTypes: [.pdf],
            allowsMultipleSelection: allowsMultipleSelection,
            onPick: onPick,
            onCancel: onCancel
        )
    }

    /// Create picker for image files (PNG, JPEG, etc.)
    static func images(
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> DocumentPicker {
        DocumentPicker(
            fileTypes: [.image],
            allowsMultipleSelection: allowsMultipleSelection,
            onPick: onPick,
            onCancel: onCancel
        )
    }

    /// Create picker for all file types
    static func allFiles(
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> DocumentPicker {
        DocumentPicker(
            fileTypes: [.all],
            allowsMultipleSelection: allowsMultipleSelection,
            onPick: onPick,
            onCancel: onCancel
        )
    }

    /// Create picker for PDF and image files
    static func pdfAndImages(
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> DocumentPicker {
        DocumentPicker(
            fileTypes: [.pdf, .png, .jpeg],
            allowsMultipleSelection: allowsMultipleSelection,
            onPick: onPick,
            onCancel: onCancel
        )
    }
}

// MARK: - View Modifier for Presenting Document Picker

extension View {

    /// Present document picker as a sheet
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - fileTypes: File types to allow
    ///   - allowsMultipleSelection: Whether to allow multiple selection
    ///   - onPick: Callback with selected results
    ///   - onCancel: Optional callback when cancelled
    func documentPicker(
        isPresented: Binding<Bool>,
        fileTypes: [DocumentFileType],
        allowsMultipleSelection: Bool = false,
        onPick: @escaping ([DocumentPickerResult]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            DocumentPicker(
                fileTypes: fileTypes,
                allowsMultipleSelection: allowsMultipleSelection,
                onPick: { results in
                    isPresented.wrappedValue = false
                    onPick(results)
                },
                onCancel: {
                    isPresented.wrappedValue = false
                    onCancel?()
                }
            )
        }
    }
}
