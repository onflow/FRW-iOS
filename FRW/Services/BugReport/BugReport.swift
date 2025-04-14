//
//  BugReport.swift
//  FRW
//
//  Created by cat on 4/11/25.
//

import Foundation
import Instabug

enum BugReport {
    static func build(error: Error, level: NonFatalLevel = .error, group: BugReport.Group = .app) -> NonFatalException? {
        let exception: NSException
        if let baseError = error as? (any BaseError) {
            exception = NSException(name: NSExceptionName(baseError.rawValue), reason: "\(baseError.errorLog)")
        } else if let custom = error as? CustomError {
            exception = NSException(name: NSExceptionName(custom.name), reason: custom.reason)
        } else {
            exception = NSException(name: NSExceptionName("\(error)"), reason: "\(error.localizedDescription)")
        }
        if let nonFatalException = CrashReporting.exception(exception) {
            nonFatalException.stackTraceMode = .full
            nonFatalException.level = level
            nonFatalException.groupingString = group.name
            return nonFatalException
        }
        return nil
    }
}

extension BaseError {
    func toNSError() -> NSError {
        NSError(domain: rawValue, code: errorCode)
    }
}

extension BugReport {
    enum Group {
        case app
        case custom(String)

        var name: String {
            switch self {
            case .app:
                return "app"
            case let .custom(string):
                return string
            }
        }
    }
}
