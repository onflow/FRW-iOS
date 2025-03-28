//
//  JSONValue.swift
//  FRW
//
//  Created by cat on 2024/10/9.
//

import Foundation

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case object([String: JSONValue])
    case array([JSONValue])
    case bool(Bool)
    case null

    // MARK: Lifecycle

    init(_ value: Any) {
        if let stringValue = value as? String {
            self = .string(stringValue)
        } else if let numberValue = value as? Double {
            self = .number(numberValue)
        } else if let numberValue = value as? Int {
            self = .number(Double(numberValue))
        } else if let boolValue = value as? Bool {
            self = .bool(boolValue)
        } else if let dictValue = value as? [String: Any] {
            self = .object(dictValue.mapValues { JSONValue($0) })
        } else if let arrayValue = value as? [Any] {
            self = .array(arrayValue.map { JSONValue($0) })
        } else {
            self = .null
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode JSONValue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

extension JSONValue {
    var rawValue: Any {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            return value
        case let .object(value):
            return value.mapValues { $0.rawValue }
        case let .array(value):
            return value.map { $0.rawValue }
        case let .bool(value):
            return value
        case .null:
            return NSNull()
        }
    }

    func toString() -> String {
        switch self {
        case let .string(value):
            return "\(value)"
        case let .number(value):
            return "\(value)"
        case let .object(dictionary):
            let objectString = dictionary.map { "\($0): \($1.toString())" }
                .joined(separator: ", ")
            return "{ \(objectString) }"
        case let .array(array):
            let arrayString = array.map { $0.toString() }.joined(separator: ", ")
            return "[ \(arrayString) ]"
        case let .bool(value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }
}

extension JSONValue {
    static func parse(jsonString: String) -> JSONValue? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Invalid JSON string")
            return nil
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            return JSONValue(jsonObject)
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }
}

extension JSONValue {
    static func decode(from data: Data) throws -> JSONValue {
        let decoder = JSONDecoder()
        return try decoder.decode(JSONValue.self, from: data)
    }

    static func decode(from string: String) throws -> JSONValue {
        guard let data = string.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid UTF-8 string"
            ))
        }
        return try decode(from: data)
    }
}

extension JSONValue {
    var title: String {
        switch self {
        case let .object(dictionary):
            if let value = dictionary["name"] {
                if case let .string(name) = value {
                    return name
                }
            }
            return dictionary.keys.first ?? ""
        default:
            return ""
        }
    }

    var content: String {
        switch self {
        case let .object(dictionary):

            let subtitle = dictionary[title]
            switch subtitle {
            case .object:
                return ""
            case let .array(model):
                if case .object = model.first {
                    return ""
                }
                return subtitle?.toString() ?? ""
            default:
                return subtitle?.toString() ?? ""
            }
        case let .string(str):
            return str
        default:
            return ""
        }
    }

    var contentIsArrayOrDic: Bool {
        switch self {
        case let .object(dictionary):
            let subtitle = dictionary[title]
            switch subtitle {
            case let .array(model):
                return true
            case .object:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    var subValue: JSONValue? {
        switch self {
        case let .object(dictionary):
            return dictionary.values.first
        default:
            return nil
        }
    }
}

extension String {
    func uppercasedAllFirstLetter() -> String {
        let words = components(separatedBy: " ")
        let capitalizedWords = words.map { word in
            guard !word.isEmpty else { return word }
            return word.prefix(1).uppercased() + word.dropFirst()
        }
        return capitalizedWords.joined(separator: " ")
    }
}
