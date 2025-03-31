//
//  EVMAccountManager.swift
//  FRW
//
//  Created by cat on 2024/3/19.
//

import Combine
import Foundation
import SwiftUI
import Web3Core

// MARK: - EVMAccountManager

class EVMAccountManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { activatedUID in
                if activatedUID == nil {
                    self.clean()
                }
            }.store(in: &cancelSets)

        WalletManager.shared.$currentMainAccount
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { walletInfo in
                if walletInfo != nil {
                    self.refresh()
                }
            }.store(in: &cancelSets)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )

        NotificationCenter.default.publisher(for: .transactionStatusDidChanged)
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] noti in
                self?.onTransactionStatusChanged(noti)
            }.store(in: &cancelSets)
    }

    // MARK: Internal

    static let shared = EVMAccountManager()

    @Published
    var hasAccount: Bool = false
    @Published
    var showEVM: Bool = false
    var balance: Decimal = 0

    @Published
    var accounts: [EVMAccountManager.Account] = [] {
        didSet {
            checkValid()
        }
    }

    var openEVM: Bool {
        (CadenceManager.shared.current.evm?.createCoaEmpty) != nil
    }

    @Published
    var selectedAccount: EVMAccountManager.Account? = LocalUserDefaults.shared
        .selectedEVMAccount
    {
        didSet {
            LocalUserDefaults.shared.selectedEVMAccount = selectedAccount
            NotificationCenter.default.post(name: .watchAddressDidChanged, object: nil)
        }
    }

    // MARK: Private

    private var cacheAccounts: [String: [String]] = LocalUserDefaults.shared.EVMAddress

    private var cancelSets = Set<AnyCancellable>()

    private func clean() {
        log.debug("cleaned")
        DispatchQueue.main.async {
            self.accounts = []
            self.selectedAccount = nil
        }
    }

    private func checkValid() {
        if (CadenceManager.shared.current.evm?.createCoaEmpty) != nil {
            hasAccount = !accounts.isEmpty
            showEVM = accounts.isEmpty
        } else {
            hasAccount = false
            showEVM = false
        }
    }

    private func addAddress(_ address: String) {
        guard let primaryAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        var list = cacheAccounts[primaryAddress] ?? []
        if !list.contains(address) {
            list.append(address)
            cacheAccounts[primaryAddress] = list
            LocalUserDefaults.shared.EVMAddress = cacheAccounts
        }
    }

    @objc
    private func willReset() {
        clean()
    }

    @objc
    private func onTransactionStatusChanged(_ noti: Notification) {
        guard let obj = noti.object as? TransactionManager.TransactionHolder,
              obj.type == .editChildAccount
        else {
            return
        }

        switch obj.internalStatus {
        case .success:
            refresh()
        default:
            break
        }
    }
}

extension EVMAccountManager {
    func refresh() {
        Task {
            await refreshSync()
        }
    }

    func refreshSync() async {
        if (CadenceManager.shared.current.evm?.createCoaEmpty) == nil {
            clean()
            return
        }

        guard let primaryAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }

        if let EVMAddress = cacheAccounts[primaryAddress]?.first, EthereumAddress(EVMAddress) != nil {
            await MainActor.run {
                let checksumAddress = EthereumAddress.toChecksumAddress(EVMAddress) ?? EVMAddress
                let account = EVMAccountManager.Account(address: checksumAddress)
                self.accounts = [account]
            }
            do {
                try await refreshBalance(address: EVMAddress)
            } catch {
                log.error("[EVM] fetch balance failed")
            }
            return
        }

        do {
            let address = try await fetchAddress()
            if let address = address {
                await MainActor.run {
                    let account = EVMAccountManager.Account(address: address)
                    self.accounts = [account]
                    self.addAddress(address)
                }
                try await refreshBalance(address: address)
            } else {
                clean()
            }
        } catch {
            clean()
            log.error("[EVM] get address failed.\(error)")
        }
    }

    func refreshBalance(address: String) async throws {
        log.info("[EVM] refresh balance at \(address)")
        let balance = try await fetchBalance(address)
        await MainActor.run {
            log.info("[EVM] refresh balance success")
            self.balance = balance
        }
    }

    func select(_ account: EVMAccountManager.Account?) {
        if selectedAccount?.address.lowercased() == account?.address.lowercased() {
            return
        }
        DispatchQueue.main.async {
            self.selectedAccount = account
        }
    }
}

extension EVMAccountManager {
    func enableEVM() async throws {
        let address = WalletManager.shared.getPrimaryWalletAddress() ?? ""

        do {
            let tid = try await FlowNetwork.createEVM()
            let result = try await tid.onceSealed()
            if result.isFailed {
                log.error("[EVM] create EVM result: Failed")
                EventTrack.General
                    .coaCreation(
                        txId: tid.description,
                        flowAddress: address,
                        message: result.errorMessage
                    )
                throw EVMError.createAccount
            } else {
                EventTrack.General
                    .coaCreation(
                        txId: tid.description,
                        flowAddress: address,
                        message: ""
                    )
            }
        } catch {
            EventTrack.General
                .coaCreation(
                    txId: "",
                    flowAddress: address,
                    message: error.localizedDescription
                )
            throw error
        }
    }

    func fetchAddress() async throws -> String? {
        let address = try await FlowNetwork.findEVMAddress()
        return address
    }

    func fetchBalance(_ address: String) async throws -> Decimal {
        try await FlowNetwork.fetchEVMBalance(address: address)
    }

    func fetchTokens() async throws -> [EVMTokenResponse] {
        guard let address = accounts.first?.showAddress else {
            return []
        }
        let response: [EVMTokenResponse] = try await Network.request(FRWAPI.EVM.tokenList(address))
        return response
    }
}

// MARK: EVMAccountManager.Account

extension EVMAccountManager {
    struct Account: ChildAccountSideCellItem, Codable {
        var address: String

        var showAddress: String {
            if address.hasPrefix("0x") {
                return address
            }
            return "0x" + address
        }

        var showIcon: String {
            "https://firebasestorage.googleapis.com/v0/b/lilico-334404.appspot.com/o/asset%2Feth.png?alt=media&token=1b926945-5459-4aee-b8ef-188a9b4acade"
        }

        var showName: String {
            "EVM wallet"
        }

        var isEVM: Bool {
            true
        }

        var isSelected: Bool {
            if let selectedAccount = EVMAccountManager.shared.selectedAccount,
               selectedAccount.address.lowercased() == address.lowercased(), !address.isEmpty
            {
                return true
            }
            return false
        }
    }
}
