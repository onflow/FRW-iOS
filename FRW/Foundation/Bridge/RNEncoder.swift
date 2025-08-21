//
//  RNEncoder.swift
//  FRW
//
//  Created by cat on 7/24/25.
//

import Foundation

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        return jsonObject as? [String: Any] ?? [:]
    }
}

extension Decodable {
  static func fromDictionary(_ dictionary: [String: Any]) throws -> Self {
      let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
      return try JSONDecoder().decode(Self.self, from: data)
  }
}
