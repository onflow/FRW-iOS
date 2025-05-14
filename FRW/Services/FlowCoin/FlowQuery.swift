//
//  FlowQuery.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/2.
//

import Combine
import Flow
import Foundation

extension String {
    func replace(by dict: [String: String]) -> String {
        var string = self
        for (key, value) in dict {
            string = string.replaceExactMatch(target: key, replacement: value)
        }
        return string
    }

    func replace(from dict: [String: String]) -> String {
        var string = self
        for (key, value) in dict {
            string = string.replacingOccurrences(of: key, with: value)
        }
        return string
    }

    func replaceExactMatch(target: String, replacement: String) -> String {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: target))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let range = NSRange(startIndex ..< endIndex, in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
    }
}

extension NFTCollectionInfo {
    func formatCadence(script: String, chainId _: Flow.ChainID = flow.chainID) -> String {
        var newScript = script
            .replacingOccurrences(of: "<NFT>", with: contractName?.trim() ?? "")
            .replacingOccurrences(of: "<NFTAddress>", with: address ?? "")
            .replacingOccurrences(of: "<Token>", with: contractName?.trim() ?? "")
            .replacingOccurrences(of: "<TokenAddress>", with: address ?? "")

        if let path = path {
            newScript = newScript
                .replacingOccurrences(of: "<CollectionStoragePath>", with: path.storagePath)
                .replacingOccurrences(of: "<CollectionPublic>", with: path.publicCollectionName ?? "")
                .replacingOccurrences(of: "<CollectionPublicPath>", with: path.publicPath)
                .replacingOccurrences(of: "<TokenCollectionStoragePath>", with: path.storagePath)
                .replacingOccurrences(of: "<TokenCollectionPublic>", with: path.publicCollectionName ?? "")
                .replacingOccurrences(of: "<TokenCollectionPublicPath>", with: path.publicPath)
                .replacingOccurrences(of: "<CollectionPublicType>", with: path.publicType ?? "")
                .replacingOccurrences(of: "<CollectionPrivateType>", with: path.privateType ?? "")
        }
        return newScript.replace(by: ScriptAddress.addressMap())
    }
}

extension TokenModel {
    func formatCadence(cadence: String) throws -> String {
        guard !contractName.isEmpty else {
            EventTrack.Dev.cadence(CadenceError.contractNameIsEmpty, message: "")
            throw CadenceError.contractNameIsEmpty
        }
        guard let address = getAddress() else {
            EventTrack.Dev.cadence(CadenceError.tokenAddressEmpty, message: "")
            throw CadenceError.tokenAddressEmpty
        }
        guard let receiverPath = receiverPath?.value, let storagePath = storagePath?.value, let balancePath = balancePath?.value else {
            throw CadenceError.storagePathEmpty
        }
        let dict = [
            "<Token>": contractName,
            "<TokenAddress>": address,
            "<TokenReceiverPath>": receiverPath,
            "<TokenBalancePath>": balancePath,
            "<TokenStoragePath>": storagePath,
        ]

        return cadence.replace(from: dict).replace(by: ScriptAddress.addressMap())
    }
}
