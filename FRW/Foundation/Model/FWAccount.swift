//
//  FWAccount.swift
//  FRW
//
//  Created by Hao Fu on 31/3/2025.
//

import Foundation
import Flow
import Web3Core

enum FWAccount: RawRepresentable, Codable {
    case main(Flow.Address)
    case child(Flow.Address)
    case coa(EthereumAddress)
  
    // MARK: - RawRepresentable
    
    init?(rawValue: String) {
        self.init(rawValue)
    }
    
    var rawValue: String {
        value
    }
    
    enum AccountType: String, Codable {
        case main
        case child
        case coa
    }
    
    var value: String {
        "\(type.rawValue)-\(hexAddr)"
    }
    
    init?(type: AccountType, addr: FWAddress) {
        switch type {
        case .child:
            guard let address = addr as? Flow.Address else {
                return nil
            }
            self = .child(address)
        case .main:
            guard let address = addr as? Flow.Address else {
                return nil
            }
            self = .main(address)
        case .coa:
            guard let address = addr as? EthereumAddress else {
                return nil
            }
            self = .coa(address)
        }
    }
    
    init?(_ value: String?) {
        guard let value else {
            return nil
        }
        
        let values = value.split(separator: "-")
        guard values.count == 2,
        let typeRaw = values.first,
        let type = AccountType(rawValue: String(typeRaw)),
        let addrRaw = values.last,
        let addr = FWAddressDector.create(address: String(addrRaw)) else {
            return nil
        }
        
        self.init(type: type, addr: addr)
    }

    var type: AccountType {
        switch self {
        case .main:
            return .main
        case .coa:
            return .coa
        case .child:
            return .child
        }
    }
    
    var vmType: VMType {
        switch self {
        case .coa:
            return .evm
        default:
            return .cadence
        }
    }

    var address: FWAddress {
        switch self {
        case let .main(address):
            return address
        case let .coa(address):
            return address
        case let .child(address):
            return address
        }
    }
    
    var hexAddr: String {
        return address.hexAddr
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type, address
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(hexAddr, forKey: .address)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(AccountType.self, forKey: .type)
        let address = try container.decode(String.self, forKey: .address)
        
        guard let addr = FWAddressDector.create(address: address) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid address"))
        }
        
        self.init(type: type, addr: addr)!
    }
}
