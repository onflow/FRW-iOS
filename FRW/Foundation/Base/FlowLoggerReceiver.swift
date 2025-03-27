//
//  FlowLoggerReceiver.swift
//  FRW
//
//  Created by cat on 3/27/25.
//

import Flow
import Foundation

class FlowLoggerReceiver: FlowLoggerProtocol {
    func log(_ level: FlowLogLevel, message: String, function: String, file: String, line: Int) {
        let prefix = "[FlowSDK]"
        let content = prefix + message
        switch level {
        case .debug:
            FlowLog.shared.debug(content, file: file, function: function, line: line)
        case .info:
            FlowLog.shared.info(content, file: file, function: function, line: line)
        case .warning:
            FlowLog.shared.warning(content, file: file, function: function, line: line)
        case .error:
            FlowLog.shared.error(content, file: file, function: function, line: line)
        }
    }
}
