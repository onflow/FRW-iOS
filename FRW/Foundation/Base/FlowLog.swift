//
//  FlowLog.swift
//  FRW
//
//  Created by cat on 2024/8/6.
//

import Foundation
import LogView
import OSLog
import SwiftyBeaver

// MARK: - FlowLog

class FlowLog {
    // MARK: Lifecycle

    private init() {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let logFileUrl = url?.appendingPathComponent("FlowWallet.log", isDirectory: false)

        let console = ConsoleDestination()
        console.format = "[Flow] $DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M - $X"
        console.logPrintWay = .logger(subsystem: "Main", category: "UI")

        file = FileDestination(logFileURL: logFileUrl)
        file.format = console.format
        file.logFileAmount = 2
        file.logFileMaxSize = (10 * 1024 * 1024)

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

    // MARK: Internal

    static let shared = FlowLog()

    var path: URL? {
        file.logFileURL
    }

    // MARK: Private

    private let file: FileDestination
}

public extension NSPredicate {
    /// Predicate for fetching from OSLogStore, allow to condition subsystem, and set if empty subsystem should be filtered.
    static func library(_ values: [String]) -> NSPredicate {
        NSPredicate(format: "library in $LIST")
            .withSubstitutionVariables(["LIST": values])
    }
}

// MARK: - FlowLog.Category

extension FlowLog {
    enum Category: String {
        case debug, info, warning, error
    }
}

// MARK: - FlowLog.Prefix

extension FlowLog {
    enum Prefix {
        case cadence
        case netword
        case ui
        case walletconnect

        case main
        case evm
        case linked
    }
}

// MARK: Levels

extension FlowLog {
    /// log something which help during debugging (low priority)
    func debug(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        SwiftyBeaver.custom(
            level: .debug,
            message: message(),
            file: file,
            function: function,
            line: line,
            context: context
        )

        addLogModel(category: .debug, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }

    /// log something which you are really interested but which is not an issue or error (normal priority)
    func info(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        SwiftyBeaver.custom(
            level: .info,
            message: message(),
            file: file,
            function: function,
            line: line,
            context: context
        )
        addLogModel(category: .info, viewModel: DebugViewModel(name: "\(message())", detail: " "))
    }

    /// log something which may cause big trouble soon (high priority)
    func warning(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        SwiftyBeaver.custom(
            level: .warning,
            message: message(),
            file: file,
            function: function,
            line: line,
            context: context
        )

        addLogModel(
            category: .warning,
            viewModel: DebugViewModel(name: "\(message())", detail: " ")
        )
    }

    /// log something which will keep you awake at night (highest priority)
    func error(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        context: Any? = nil
    ) {
        SwiftyBeaver.custom(
            level: .error,
            message: message(),
            file: file,
            function: function,
            line: line,
            context: context
        )
        addLogModel(category: .error, viewModel: DebugViewModel(
            name: "\(message())",
            detail: (context as? Error)?
                .localizedDescription ?? ""
        ))
    }

    private func addLogModel(category: FlowLog.Category, viewModel: DebugViewModel) {
        if LocalUserDefaults.shared.openLogWindow {
            DebugViewer.shared.addViewModel(category: category.rawValue, viewModel: viewModel)
        }
    }
}
