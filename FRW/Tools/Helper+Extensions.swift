//
//  Helper+Extensions.swift
//  FRW
//
//  Created by Antonio Bello on 11/25/24.
//

import Foundation

extension Optional<String> {
    var isNotNullNorEmpty: Bool {
        // An optional bool is a 3-state variable: nil, false, true, so this expression evaluates to true only if self is
        self?.isEmpty == false
    }
}

extension Optional<URL> {
    var isNotNullNorEmpty: Bool {
        self?.absoluteString.isEmpty == false
    }
}

extension Optional: @retroactive RawRepresentable where Wrapped: Codable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            return "{}"
        }
        return String(decoding: data, as: UTF8.self)
    }

    public init?(rawValue: String) {
        guard let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) else {
            return nil
        }
        self = value
    }
}
