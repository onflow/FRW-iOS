//
//  FlowLog.swift
//  FRW
//
//  Created by cat on 2024/8/6.
//

import Foundation
import SwiftyBeaver
import LogView
import OSLog

class FlowLog {
    static let shared = FlowLog()
    
    private let file = FileDestination()
    
    var path: URL? {
        return file.logFileURL
    }
    
    private init() {
        let console = ConsoleDestination()
        console.format = "[Flow]$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M - $X"
        
        console.logPrintWay = .logger(subsystem: "Main", category: "UI")
        SwiftyBeaver.addDestination(console)
        SwiftyBeaver.addDestination(file)
        
        SwiftyBeaver.debug("[Log] filePath: \(String(describing: file.logFileURL))")
        
        let filter: ((OSLogEntryLog) -> Bool) = { log in
            if log.sender.contains("FRW") {
                return true
            }
            return false
        }
        LogView.filterEntries = filter
    }
}

public extension NSPredicate {
  /// Predicate for fetching from OSLogStore, allow to condition subsystem, and set if empty subsystem should be filtered.
  static func library(_ values: [String]) -> NSPredicate {
    NSPredicate(format: "library in $LIST")
      .withSubstitutionVariables(["LIST" : values])
  }
}

extension FlowLog {
    enum Category: String {
        case debug,info,warning,error
    }
}

// MARK: Levels
extension FlowLog {
    

    /// log something which help during debugging (low priority)
    func debug(_ message: @autoclosure () -> Any,
        file: String = #file, function: String = #function, line: Int = #line, context: Any? = nil) {
        SwiftyBeaver.custom(level: .debug, message: message(), file: file, function: function, line: line, context: context)
        DebugViewer.shared.addViewModel(category: Category.debug.rawValue, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }

    /// log something which you are really interested but which is not an issue or error (normal priority)
    func info(_ message: @autoclosure () -> Any,
        file: String = #file, function: String = #function, line: Int = #line, context: Any? = nil) {
        
        SwiftyBeaver.custom(level: .info, message: message(), file: file, function: function, line: line, context: context)
        DebugViewer.shared.addViewModel(category: Category.info.rawValue, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }

    /// log something which may cause big trouble soon (high priority)
    func warning(_ message: @autoclosure () -> Any,
        file: String = #file, function: String = #function, line: Int = #line, context: Any? = nil) {

        SwiftyBeaver.custom(level: .warning, message: message(), file: file, function: function, line: line, context: context)
        DebugViewer.shared.addViewModel(category: Category.warning.rawValue, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }

    /// log something which will keep you awake at night (highest priority)
    func error(_ message: @autoclosure () -> Any,
        file: String = #file, function: String = #function, line: Int = #line, context: Any? = nil) {
        
        SwiftyBeaver.custom(level: .error, message: message(), file: file, function: function, line: line, context: context)
        DebugViewer.shared.addViewModel(category: Category.error.rawValue, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }


}