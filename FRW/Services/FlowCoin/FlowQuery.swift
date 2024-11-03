//
//  LLCadence.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/2.
//

import Combine
import Flow
import Foundation

typealias TokenCadence = LLCadence<LLCadenceAction.token>
typealias BalanceCadence = LLCadence<LLCadenceAction.balance>
typealias NFTCadence = LLCadence<LLCadenceAction.nft>

enum LLCadenceAction {
    enum token {}
    enum balance {}
    enum nft {}
}

struct LLCadence<T> {}

// MARK: Check Token vault is enabled

extension LLCadence where T == LLCadenceAction.token {
    static func tokenTransfer(token: TokenModel, at network: Flow.ChainID) -> String {
        let transferTokenCadence = CadenceManager.shared.current.ft?.transferTokens?.toFunc() ?? ""
        let script = transferTokenCadence
        return script
            .replace(by: ScriptAddress.addressMap())
            .buildTokenInfo(token, chainId: network)
    }
}

// MARK: Get Token Balance

extension LLCadence where T == LLCadenceAction.balance {}

// MARK: Body of Check Token vault is enabled

extension LLCadence {
    private static func importRow(with tokens: [TokenModel], at network: Flow.ChainID) -> String {
        let tokenImports = tokens.map { token in
            """
            import <Token> from <TokenAddress>

            """
            .buildTokenInfo(token, chainId: network)
        }.joined(separator: "\r\n")
        return tokenImports
    }
}

// MARK: NFT

extension LLCadence where T == LLCadenceAction.nft {
    static func collectionListCheckEnabled(with list: [NFTCollectionInfo], on _: Flow.ChainID) -> String {
        let tokenImports = list.map {
            $0.formatCadence(script: "import <Token> from <TokenAddress>")
        }.joined(separator: "\r\n")

        let tokenFunctions = list.map {
            $0.formatCadence(script:
                """
                pub fun check<Token>Vault(address: Address) : Bool {
                    let account = getAccount(address)
                    let vaultRef = account
                    .getCapability<&{NonFungibleToken.CollectionPublic}>(<TokenCollectionPublicPath>)
                    .check()
                    return vaultRef
                }
                """
            )
        }.joined(separator: "\r\n")

        let tokenCalls = list.map {
            $0.formatCadence(script:
                """
                check<Token>Vault(address: address)
                """
            )
        }.joined(separator: ",")

        let cadence =
            """
            import NonFungibleToken from 0xNonFungibleToken
            <TokenImports>

            <TokenFunctions>

            pub fun main(address: Address) : [Bool] {
                return [<TokenCall>]
            }
            """
            .replace(by: ScriptAddress.addressMap())
            .replacingOccurrences(of: "<TokenFunctions>", with: tokenFunctions)
            .replacingOccurrences(of: "<TokenImports>", with: tokenImports)
            .replacingOccurrences(of: "<TokenCall>", with: tokenCalls)
        return cadence
    }
}

extension String {
    func buildTokenInfo(_ token: TokenModel, chainId: Flow.ChainID) -> String {
        let dict = [
            "<Token>": token.contractName,
            "<TokenAddress>": token.address.addressByNetwork(chainId) ?? "0x",
            "<TokenBalancePath>": token.storagePath.balance,
            "<TokenReceiverPath>": token.storagePath.receiver,
            "<TokenStoragePath>": token.storagePath.vault,
        ]
        return replace(by: dict)
    }
}

extension String {
    func replace(by dict: [String: String]) -> String {
        var string = self
        for (key, value) in dict {
            string = string.replacingOccurrences(of: key, with: value)
        }
        return string
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
    func formatCadence(cadence: String) -> String {
        let dict = [
            "<Token>": contractName,
            "<TokenAddress>": getAddress() ?? "0x",
            "<TokenReceiverPath>": storagePath.receiver,
            "<TokenBalancePath>": storagePath.balance,
            "<TokenStoragePath>": storagePath.vault,
        ]

        return cadence.replace(by: dict).replace(by: ScriptAddress.addressMap())
    }
}
