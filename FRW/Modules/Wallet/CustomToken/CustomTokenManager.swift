//
//  CustomTokenManager.swift
//  FRW
//
//  Created by cat on 11/1/24.
//

import BigInt
import Foundation
import Web3Core
import web3swift
import Flow

// MARK: - CustomTokenManager

class CustomTokenManager: ObservableObject {
    // MARK: Internal

    @Published
    var list: [CustomToken] = []

    var allTokens: [CustomToken] = LocalUserDefaults.shared.customToken

    func refresh() {
        queue.sync {
            var result = findCurrent(list: allTokens)
            result = filterWhite(list: result)
            list = result
        }
    }

    func isInWhite(token: CustomToken) -> Bool {
        guard let support = WalletManager.shared.supportedCoins else {
            return true
        }
        let filterList = support.filter { model in
            model.getAddress()?.lowercased() == token.address.lowercased()
        }
        return !filterList.isEmpty
    }

    func isExist(token: CustomToken) -> Bool {
        queue.sync {
            let result = allTokens.filter { model in
                token.network == model.network && model.address == token.address && token
                    .belong == model.belong
            }
            return !result.isEmpty
        }
    }

    func allowDelete(token: CustomToken) -> Bool {
        guard !isInWhite(token: token) else {
            return false
        }
        return isExist(token: token)
    }

    func add(token: CustomToken) async {
        guard !isExist(token: token) else {
            return
        }
        var tmpToken = token
        let balance = try? await fetchBalance(token: token)
        tmpToken.balance = balance
        queue.sync {
            allTokens.append(tmpToken)
            LocalUserDefaults.shared.customToken = allTokens
        }
        refresh()
        WalletManager.shared.addCustomToken(token: tmpToken)
    }

    func delete(token: CustomToken) {
        queue.sync {
            allTokens.removeAll { model in
                token.network == model.network && token.belong == model.belong && model
                    .address == token.address
            }
            LocalUserDefaults.shared.customToken = allTokens
        }
        refresh()
        WalletManager.shared.deleteCustomToken(token: token)
    }

    // MARK: Private

    private var queue = DispatchQueue(label: "CustomToken.add")

    private func findCurrent(list: [CustomToken]) -> [CustomToken] {
        guard let address = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
            let userId = UserManager.shared.activatedUID
        else {
            return []
        }
        let currentNetwork = LocalUserDefaults.shared.network
        let belong = EVMAccountManager.shared.selectedAccount != nil ? CustomToken.Belong
            .evm : .flow

        let result = list.filter { token in
            token.network == currentNetwork && token.belong == belong
        }
        return result
    }

    private func filterWhite(list: [CustomToken]) -> [CustomToken] {
        var result: [CustomToken] = []
        for customToken in list {
            if !isInWhite(token: customToken) {
                result.append(customToken)
            }
        }
        return result
    }

    private func update(token: CustomToken) {
        queue.sync {
            let index = allTokens.firstIndex { model in
                token.belong == model.belong && model.address == token.address && token
                    .network == model.network
            }
            guard let index else {
                return
            }
            allTokens[index] = token
        }
    }
}

// EVM
extension CustomTokenManager {
    func findToken(evmAddress: String) async throws -> CustomToken? {
        let evmAddress = evmAddress.addHexPrefix()

        guard let web3 = try await FlowProvider.Web3.default() else {
            throw AddCustomTokenError.providerFailed
        }
        let contratc = web3.contract(Web3Utils.erc20ABI, at: .init(evmAddress))
        async let decimalsRequest = contratc?.createReadOperation("decimals")?.callContractMethod()

        let decimals = try await decimalsRequest?["0"] as? BigUInt
        let decimalInt = Int(decimals?.description ?? "6") ?? 0

        async let symbolRequest = contratc?.createReadOperation("symbol")?.callContractMethod()
        async let nameRequest = contratc?.createReadOperation("name")?.callContractMethod()
        let result: [String] = try await [symbolRequest, nameRequest]
            .compactMap { $0?["0"] as? String }
        guard result.count == 2 else {
            return nil
        }

        let name = result[1]
        let symbol = result[0]

        let flowIdentifier = try? await FlowNetwork.getAssociatedFlowIdentifier(address: evmAddress)

        let token = CustomToken(
            address: evmAddress,
            decimals: decimalInt,
            name: name,
            symbol: symbol,
            flowIdentifier: flowIdentifier,
            belong: .evm
        )
        return token
    }

    func fetchAllEVMBalance() async {
        await withTaskGroup(of: Void.self) { group in
            for token in allTokens {
                group.addTask { [weak self] in
                    do {
                        var model = token
                        let balance = try await self?.fetchBalance(token: model)
                        model.balance = balance
                        self?.update(token: model)
                    } catch {
                        log.info("[Custom Token] fetch balance failed.\(token.address)")
                    }
                }
            }
        }
        refresh()
    }

    func fetchBalance(token: CustomToken) async throws -> BigUInt? {
        guard let coaAddresss = EVMAccountManager.shared.selectedAccount?.showAddress else {
            throw AddCustomTokenError.invalidProfile
        }
        guard let web3 = try await FlowProvider.Web3.default() else {
            throw AddCustomTokenError.providerFailed
        }
        let contratc = web3.contract(
            Web3Utils.erc20ABI,
            at: .init(token.address)
        )
        // Parameters is user wallet address
        let balanceRequest = try await contratc?.createReadOperation(
            "balanceOf",
            parameters: [coaAddresss]
        )?.callContractMethod()
        if let balanceUInt = balanceRequest?["balance"] as? BigUInt {
            return balanceUInt
        }
        return nil
    }
}

// MARK: - CustomToken

struct CustomToken: Codable {
    // MARK: Lifecycle

    init(
        address: String,
        decimals: Int,
        name: String,
        symbol: String,
        flowIdentifier: String? = nil,
        belong: CustomToken.Belong = .evm,
        balance: BigUInt? = nil,
        icon _: String? = nil
    ) {
        self.address = address
        self.decimals = decimals
        self.name = name
        self.symbol = symbol
        self.belong = belong
        self.balance = balance
        self.flowIdentifier = flowIdentifier

        userId = UserManager.shared.activatedUID ?? ""
        belongAddress = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? ""
        network = LocalUserDefaults.shared.network
    }

    // MARK: Internal

    enum Belong: Codable {
        case flow
        case evm

        var tokenType: TokenModel.TokenType {
            return switch self {
            case .flow: .cadence
            case .evm: .evm
            }
        }
    }

    var address: String
    var decimals: Int
    var name: String
    var symbol: String
    var flowIdentifier: String?

    var userId: String
    var belongAddress: String
    var network: Flow.ChainID = .mainnet
    var belong: CustomToken.Belong = .flow
    // not store,
    var balance: BigUInt?
    var icon: String? = nil

    var balanceValue: String {
        let balance = balance ?? BigUInt(0)
        let result = Utilities.formatToPrecision(
            balance,
            units: .custom(decimals),
            formattingDecimals: decimals
        )
        return result
    }

    func toToken() -> TokenModel {
        TokenModel(
            type: belong.tokenType,
            name: name,
            address: FlowNetworkModel(
                mainnet: address,
                testnet: address,
                crescendo: nil
            ),
            contractName: "",
            storagePath: FlowTokenStoragePath(balance: "", vault: "", receiver: ""),
            decimal: decimals,
            icon: nil,
            symbol: symbol,
            website: nil,
            evmAddress: nil,
            balance: balance,
            avaibleBalance: balance
        )
    }
}

extension TokenModel {
    func findCustomToken() -> CustomToken? {
        let result = WalletManager.shared.customTokenManager.list
            .filter {
                $0.address == getAddress() && $0.name == name
            }.first
        return result
    }
}

// MARK: - AddCustomTokenError

enum AddCustomTokenError: Error {
    case invalidProfile
    case providerFailed
}
