//
//  ZipFile.swift
//  FRW
//
//  Created by cat on 4/17/25.
//

import Foundation
import ZIPFoundation

class ZipFile {
    static func zipItem(_ at: URL, to: URL) throws {
        do {
            let fileManager = FileManager()
            try fileManager.zipItem(at: at, to: to, compressionMethod: .deflate)
        } catch {
            throw error
        }
    }
}

extension ZipFile {
    static func zipLogFile() throws -> URL? {
        guard let sourceURL = FlowLog.filePath,
              let destinationURL = FlowLog.filePath?.appendingPathExtension("zip")
        else {
            log.warning("ZIP failed with nil path")
            return nil
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try zipItem(sourceURL, to: destinationURL)
        return destinationURL
    }

    /// only test with time
    static func zipLogFileWithMeasure() throws -> URL? {
        guard let sourceURL = FlowLog.filePath,
              let destinationURL = FlowLog.filePath?.appendingPathExtension("zip")
        else {
            log.warning("ZIP failed with nil path")
            return nil
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        let sourceFileAttributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
        let sourceFileSize = sourceFileAttributes[.size] as? UInt64 ?? 0

        let startTime = CFAbsoluteTimeGetCurrent()

        try zipItem(sourceURL, to: destinationURL)

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        let zipFileAttributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let zipFileSize = zipFileAttributes[.size] as? UInt64 ?? 0

        let compressionRatio = sourceFileSize > 0 ? Double(zipFileSize) / Double(sourceFileSize) * 100 : 0

        log.debug("[ZIP] Finshi - cost: \(String(format: "%.6f", timeElapsed))s, Before: \(ByteCountFormatter.string(fromByteCount: Int64(sourceFileSize), countStyle: .file)), After: \(ByteCountFormatter.string(fromByteCount: Int64(zipFileSize), countStyle: .file)), Ratio: \(String(format: "%.2f", compressionRatio))%")

        return destinationURL
    }
}
