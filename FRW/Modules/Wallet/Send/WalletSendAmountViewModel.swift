//
//  WalletSendAmountViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 13/7/2022.
//

import Flow
import Foundation
import SwiftUI
import Web3Core
import web3swift

import Combine

extension WalletSendAmountView {
    enum ExchangeType {
        case token
        case dollar
    }

    enum ErrorType {
        case none
        case insufficientBalance
        case formatError
        case invalidAddress
        case belowMinimum

        // MARK: Internal

        var desc: String {
            switch self {
            case .none:
                return ""
            case .insufficientBalance:
                return "insufficient_balance".localized
            case .formatError:
                return "format_error".localized
            case .invalidAddress:
                return "invalid_address".localized
            case .belowMinimum:
                return "below_minimum_error".localized
            }
        }
    }
}

// MARK: - WalletSendAmountViewModel

@MainActor
final class WalletSendAmountViewModel: ObservableObject {
    // MARK: Lifecycle

    init(target: Contact, token: TokenModel) {
        targetContact = target
        self.token = token

        WalletManager.shared.$activatedCoins.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshTokenData()
                self?.refreshInput()
            }
        }.store(in: &cancelSets)
        
        checkAddress()
        checkTransaction()
        checkForInsufficientStorage()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onHolderChanged(noti:)),
            name: .transactionStatusDidChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Internal

    @Published
    private(set) var targetContact: Contact
    @Published
    private(set) var token: TokenModel
    @Published
    private(set) var amountBalance: Double = 0
    @Published
    private(set) var coinRate: Double = 0

    @Published
    var inputText: String = ""
    @Published
    private(set) var inputTokenNum: Double = 0
    @Published
    private(set) var inputDollarNum: Double = 0
    private(set) var actualBalance: String = ""

    @Published
    private(set) var exchangeType: WalletSendAmountView.ExchangeType = .token
    @Published
    private(set) var errorType: WalletSendAmountView.ErrorType = .none

    @Published
    var showConfirmView: Bool = false

    @Published
    private(set) var isValidToken: Bool = true

    @Published
    var isEmptyTransation = true

    var amountBalanceAsDollar: Double {
        coinRate * amountBalance
    }

    var isReadyForSend: Bool {
        errorType == .none && inputText.isNumber && addressIsValid == true
    }

    // MARK: Private

    private var isSending = false
    private var cancelSets = Set<AnyCancellable>()

    private var addressIsValid: Bool?

    private var _insufficientStorageFailure: InsufficientStorageFailure?
}

extension WalletSendAmountViewModel {
    private func checkAddress() {
        Task {
            if let address = targetContact.address {
                var isValidAddr = address.isEVMAddress
                if !isValidAddr {
                    isValidAddr = await FlowNetwork.addressVerify(address: address)
                }
                let isValid = isValidAddr
                await MainActor.run {
                    self.addressIsValid = isValid
                    if isValid == false {
                        self.errorType = .invalidAddress
                    } else {
                        self.checkToken()
                    }
                }
            }
        }
    }

    private func checkToken() {
        if token.isFlowCoin {
            isValidToken = true
        }
        Task {
            if let address = targetContact.address {
                if address.isEVMAddress {
                    await MainActor.run {
                        self.isValidToken = true
                    }
                    return
                }
                guard let compareKey = token.vaultIdentifier
                else {
                    await MainActor.run {
                        self.isValidToken = false
                    }
                    return
                }

                let list = try await FlowNetwork.fetchTokenBalance(address: Flow.Address(hex: address))
                let model = list.first { $0.key.lowercased().contains(compareKey.lowercased()) }
                await MainActor.run {
                    self.isValidToken = (model != nil)
                }
            }
        }
    }

    private func refreshTokenData() {
        amountBalance = WalletManager.shared
            .getBalance(with: token).doubleValue
        coinRate = CoinRateCache.cache
            .getSummary(by: token.contractId)?
            .getLastRate() ?? 0
    }

    private func refreshInput() {
        defer {
            checkForInsufficientStorage()
        }

        if errorType == .invalidAddress {
            return
        }

        if inputText.isEmpty {
            errorType = .none
            return
        }

        if !inputText.isNumber {
            inputDollarNum = 0
            inputTokenNum = 0
            errorType = .formatError
            return
        }

        if exchangeType == .token {
            inputTokenNum = actualBalance.doubleValue
            inputDollarNum = inputTokenNum * coinRate * CurrencyCache.cache.currentCurrencyRate
        } else {
            inputDollarNum = actualBalance.doubleValue
            if coinRate == 0 {
                inputTokenNum = 0
            } else {
                inputTokenNum = inputDollarNum / CurrencyCache.cache.currentCurrencyRate / coinRate
            }
        }

        if inputTokenNum > amountBalance {
            errorType = .insufficientBalance
            return
        }

        errorType = .none
    }

    private func saveToRecentLlist() {
        RecentListCache.cache.append(contact: targetContact)
    }
}

// MARK: InsufficientStorageToastViewModel

extension WalletSendAmountViewModel: InsufficientStorageToastViewModel {
    var variant: InsufficientStorageFailure? { _insufficientStorageFailure }

    private func checkForInsufficientStorage() {
        _insufficientStorageFailure = insufficientStorageCheckForTransfer(
            amount: inputTokenNum.decimalValue,
            token: .ft(token)
        )
    }
}

extension WalletSendAmountViewModel {
    func inputTextDidChangeAction(text _: String) {
        actualBalance = inputText.doubleValue.formatCurrencyString(digits: token.decimal)
        refreshInput()
    }

    func maxAction() {
        exchangeType = .token
        let num = max(amountBalance, 0)
        inputText = num.formatCurrencyString()
        actualBalance = num.formatCurrencyString(digits: token.decimal)
    }

    func toggleExchangeTypeAction() {
        if exchangeType == .token, coinRate != 0 {
            exchangeType = .dollar
            inputText = inputDollarNum.formatCurrencyString()
            actualBalance = inputDollarNum
                .formatCurrencyString(digits: token.decimal)
        } else {
            exchangeType = .token
            inputText = inputTokenNum.formatCurrencyString()
            actualBalance = inputTokenNum
                .formatCurrencyString(digits: token.decimal)
        }
    }

    func nextAction() {
        UIApplication.shared.endEditing()

        if showConfirmView {
            showConfirmView = false
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showConfirmView = true
        }
    }

    func sendWithVerifyAction() {
        DispatchQueue.main.async {
            self.doSend()
        }
    }

    private func doSend() {
        enum AccountType {
            case flow
            case coa
            case eoa
        }

        if isSending {
            log.info("[Send] isSending")
            return
        }

        guard let address = WalletManager.shared.getPrimaryWalletAddress(),
              let targetAddress = targetContact.address
        else {
            log.info("[Send] empty target address:\(String(describing: targetContact.address))")
            return
        }

        let failureBlock = {
            DispatchQueue.main.async {
                self.isSending = false
                HUD.dismissLoading()
                HUD.error(title: "send_failed".localized)
            }
        }

        saveToRecentLlist()

        isSending = true
        let gas: UInt64 = WalletManager.defaultGas
        Task {
            do {
                var txId: Flow.ID?
                let amount = inputTokenNum.decimalValue

                let fromAccountType = WalletManager.shared.isSelectedEVMAccount ? AccountType
                    .coa : AccountType.flow
                var toAccountType = targetAddress.isEVMAddress ? AccountType.coa : AccountType.flow
                if toAccountType == .coa,
                   targetAddress != EVMAccountManager.shared.accounts.first?.address
                {
                    toAccountType = .eoa
                }
                log.info("\(fromAccountType)->\(toAccountType): Token:{\(String(describing: token.vaultIdentifier))}")
                switch (fromAccountType, toAccountType) {
                case (.flow, .flow):
                    txId = try await FlowNetwork.transferToken(
                        to: Flow.Address(hex: targetContact.address ?? "0x"),
                        amount: amount,
                        token: token
                    )
                case (.flow, .coa):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork.fundCoa(amount: amount)
                    } else {
                        guard let vaultIdentifier = token.vaultIdentifier else {
                            failureBlock()
                            return
                        }
                        txId = try await FlowNetwork.bridgeToken(
                            vaultIdentifier: vaultIdentifier,
                            amount: amount,
                            fromEvm: false,
                            decimals: token.decimal
                        )
                    }
                case (.coa, .flow):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork.sendFlowTokenFromCoaToFlow(
                            amount: amount,
                            address: targetAddress
                        )
                    } else if targetAddress == address {
                        guard let vaultIdentifier = token.vaultIdentifier else {
                            failureBlock()
                            return
                        }
                        txId = try await FlowNetwork.bridgeToken(
                            vaultIdentifier: vaultIdentifier,
                            amount: amount,
                            fromEvm: true,
                            decimals: token.decimal
                        )
                    } else {
                        guard let bigUIntValue = amount.description
                            .parseToBigUInt(decimals: token.decimal),
                            let vaultIdentifier = token.vaultIdentifier
                        else {
                            failureBlock()
                            return
                        }

                        txId = try await FlowNetwork.bridgeTokensFromEvmToFlow(
                            identifier: vaultIdentifier,
                            amount: bigUIntValue,
                            receiver: targetAddress
                        )
                    }
                case (.coa, .coa):

                    txId = try await FlowNetwork.sendTransaction(
                        amount: amount.description,
                        data: nil,
                        toAddress: targetAddress.stripHexPrefix(),
                        gas: gas
                    )
                case (.flow, .eoa):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork.sendFlowToEvm(
                            evmAddress: targetAddress.stripHexPrefix(),
                            amount: amount,
                            gas: gas
                        )
                    } else {
                        guard let vaultIdentifier = self.token.vaultIdentifier else {
                            failureBlock()
                            return
                        }

                        txId = try await FlowNetwork.sendNoFlowTokenToEVM(
                            vaultIdentifier: vaultIdentifier,
                            amount: amount,
                            recipient: targetAddress
                        )
                    }
                case (.coa, .eoa):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork
                            .sendTransaction(
                                amount: amount.description,
                                data: nil,
                                toAddress: targetAddress.stripHexPrefix(),
                                gas: gas
                            )
                    } else {
                        guard let toAddress = token.getAddress() else {
                            throw LLError.invalidAddress
                        }
                        guard let bigAmount = amount.description
                            .parseToBigUInt(decimals: token.decimal)
                        else {
                            throw WalletError.insufficientBalance
                        }
                        let erc20Contract = try await FlowProvider.Web3.defaultContract()
                        let testData = erc20Contract?.contract.method(
                            "transfer",
                            parameters: [
                                targetAddress,
                                bigAmount,
                            ],
                            extraData: nil
                        )

                        txId = try await FlowNetwork.sendTransaction(
                            amount: "0",
                            data: testData,
                            toAddress: toAddress.stripHexPrefix(),
                            gas: gas
                        )
                    }
                default:
                    log.warning("[send] not match type")
                    failureBlock()
                    return
                }

                guard let id = txId else {
                    log.warning("[send] fetch txid failed")
                    failureBlock()
                    return
                }

                EventTrack.Transaction
                    .ftTransfer(
                        from: address,
                        to: targetAddress,
                        type: token.symbol ?? "",
                        amount: self.inputTokenNum,
                        identifier: token.contractId
                    )

                DispatchQueue.main.async {
                    let obj = CoinTransferModel(
                        amount: self.inputTokenNum,
                        symbol: self.token.symbol ?? "",
                        target: self.targetContact,
                        from: address
                    )
                    guard let data = try? JSONEncoder().encode(obj) else {
                        log.error("WalletSendAmountViewModel -> obj encode failed")
                        failureBlock()
                        return
                    }

                    self.isSending = false
                    HUD.dismissLoading()
                    self.showConfirmView = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Router.dismiss()
                    }

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    let holder = TransactionManager.TransactionHolder(
                        id: id,
                        type: .transferCoin,
                        data: data
                    )
                    TransactionManager.shared.newTransaction(holder: holder)
                }
            } catch {
                log.error(error, report: true)
                failureBlock()
                showConfirmView = false
            }
        }
    }

    func changeTokenModelAction(token: TokenModel) {
        LocalUserDefaults.shared.recentToken = token.vaultIdentifier

        self.token = token
        checkAddress()
        refreshTokenData()
        refreshInput()
    }
}

extension WalletSendAmountViewModel {
    func checkTransaction() {
        isEmptyTransation = TransactionManager.shared.holders.count == 0
    }

    @objc
    private func onHolderChanged(noti _: Notification) {
        checkTransaction()
    }
}

extension String {
    static let numberFormatter = NumberFormatter()
    var doubleValue: Double {
        String.numberFormatter.decimalSeparator = "."
        if let result = String.numberFormatter.number(from: self) {
            return result.doubleValue
        } else {
            String.numberFormatter.decimalSeparator = ","
            if let result = String.numberFormatter.number(from: self) {
                return result.doubleValue
            }
        }
        return 0
    }
}
