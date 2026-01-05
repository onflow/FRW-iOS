//
//  NativeEventModels.swift
//  FRW
//
//  Auto-generated from TypeScript bridge types
//  Do not edit manually
//

import Foundation

enum RNNativeEvent {
    struct KeyRotationCheckParams: Codable {
        let address: String
    }

    struct KeyRotationCheckResult: Codable {
        let address: String
        let isBlocto: Bool
    }

    struct NativeRequestPayload: Codable {
        let requestId: String
        let eventName: NativeEventName
        let paramsJson: String
    }

    struct NativeResponsePayload: Codable {
        let requestId: String
        let eventName: NativeEventName
        let resultJson: String?
        let error: String?
    }

    enum NativeEventName: String, Codable {
        case keyrotationcheck = "keyRotationCheck"
    }

}
