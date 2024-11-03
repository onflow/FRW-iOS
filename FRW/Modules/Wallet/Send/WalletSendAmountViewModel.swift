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

class WalletSendAmountViewModel: ObservableObject {
    @Published var targetContact: Contact
    @Published var token: TokenModel
    @Published var amountBalance: Double = 0
    @Published var coinRate: Double = 0

    @Published var inputText: String = ""
    @Published var inputTokenNum: Double = 0
    @Published var inputDollarNum: Double = 0
    var actualBalance: String = ""

    @Published var exchangeType: WalletSendAmountView.ExchangeType = .token
    @Published var errorType: WalletSendAmountView.ErrorType = .none

    @Published var showConfirmView: Bool = false

    @Published var isValidToken: Bool = true

    @Published var isEmptyTransation = true

    private var isSending = false
    private var cancelSets = Set<AnyCancellable>()

    private var addressIsValid: Bool?

    private var minBalance: Double = 0.001

    init(target: Contact, token: TokenModel) {
        targetContact = target
        self.token = token

        WalletManager.shared.$coinBalances.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshTokenData()
                self?.refreshInput()
            }
        }.store(in: &cancelSets)
        checkAddress()
        checkTransaction()
        fetchMinFlowBalance()
        NotificationCenter.default.addObserver(self, selector: #selector(onHolderChanged(noti:)), name: .transactionStatusDidChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var amountBalanceAsDollar: Double {
        return coinRate * amountBalance
    }

    var isReadyForSend: Bool {
        return errorType == .none && inputText.isNumber && addressIsValid == true
    }
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
                DispatchQueue.main.async {
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
        Task {
            if let address = targetContact.address {
                if address.isEVMAddress {
                    DispatchQueue.main.async {
                        self.isValidToken = true
                    }
                    return
                }
                let list = try await FlowNetwork.checkTokensEnable(address: Flow.Address(hex: address))
                let model = list.first { $0.key.lowercased() == token.contractId.lowercased() }
                let isValid = model?.value
                DispatchQueue.main.async {
                    self.isValidToken = isValid ?? false
                }
            }
        }
    }

    private func refreshTokenData() {
        amountBalance = WalletManager.shared.getBalance(bySymbol: token.symbol ?? "")
        coinRate = CoinRateCache.cache.getSummary(for: token.symbol ?? "")?.getLastRate() ?? 0
    }

    private func refreshInput() {
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
        actualBalance = inputText.doubleValue
            .formatCurrencyString(digits: token.decimal)
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

        if token.isFlowCoin, WalletManager.shared.isCoa(targetContact.address) {
            let validBalance = (
                Decimal(amountBalance) - Decimal(minBalance)
            ).doubleValue
            if validBalance < inputTokenNum  {
                errorType = .belowMinimum
                return
            }
        }

        errorType = .none
    }

    private func saveToRecentLlist() {
        RecentListCache.cache.append(contact: targetContact)
    }

    private func fetchMinFlowBalance() {
        Task {
            do {
                self.minBalance = try await FlowNetwork.minFlowBalance()
                log.debug("[Flow] min balance:\(self.minBalance)")
            } catch {
                self.minBalance = 0.001
            }
        }
    }
}

extension WalletSendAmountViewModel {
    func inputTextDidChangeAction(text _: String) {
        refreshInput()
    }

    func maxAction() {
        exchangeType = .token
        if token.isFlowCoin && WalletManager.shared
            .isCoa(targetContact.address) && WalletManager.shared.isMain() {
            Task {
                do {
                    let topAmount = try await FlowNetwork.minFlowBalance()
                    let num = max(
                        amountBalance - topAmount - WalletManager.moveFee,
                        0
                    )
                    DispatchQueue.main.async {
                        self.inputText = num.formatCurrencyString()
                    }
                    
                    actualBalance = num.formatCurrencyString(digits: token.decimal)
                } catch {
                    let num = max(amountBalance - minBalance, 0)
                    DispatchQueue.main.async {
                        self.inputText = num.formatCurrencyString()
                    }
                    actualBalance = num.formatCurrencyString(digits: token.decimal)
                    log.error("[Flow] min flow balance error")
                }
            }
        } else {
            let num = max(amountBalance, 0)
            inputText = num.formatCurrencyString()
            actualBalance = num.formatCurrencyString(digits: token.decimal)
        }
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
//        Task {
//            let result = await SecurityManager.shared.SecurityVerify()
//            if !result {
//                HUD.error(title: "verify_failed".localized)
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.doSend()
//            }
//        }
    }

    private func doSend() {
        enum AccountType {
            case flow
            case coa
            case eoa
        }

        if isSending {
            return
        }

        guard let address = WalletManager.shared.getPrimaryWalletAddress(), let targetAddress = targetContact.address else {
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

                let fromAccountType = WalletManager.shared.isSelectedEVMAccount ? AccountType.coa : AccountType.flow
                var toAccountType = targetAddress.isEVMAddress ? AccountType.coa : AccountType.flow
                if toAccountType == .coa, targetAddress != EVMAccountManager.shared.accounts.first?.address {
                    toAccountType = .eoa
                }

                switch (fromAccountType, toAccountType) {
                case (.flow, .flow):
                    txId = try await FlowNetwork.transferToken(to: Flow.Address(hex: targetContact.address ?? "0x"),
                                                               amount: amount,
                                                               token: token)
                case (.flow, .coa):
                    txId = try await FlowNetwork.fundCoa(amount: amount)
                case (.coa, .flow):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork.sendFlowTokenFromCoaToFlow(amount: amount, address: targetAddress)
                    } else {
                        guard let bigUIntValue = Utilities.parseToBigUInt(amount.description, units: .ether),
                              let flowIdentifier = self.token.flowIdentifier
                        else {
                            failureBlock()
                            return
                        }

                        txId = try await FlowNetwork.bridgeTokensFromEvmToFlow(identifier: flowIdentifier, amount: bigUIntValue, receiver: targetAddress)
                    }

                case (.coa, .coa):

                    txId = try await FlowNetwork.sendTransaction(amount: amount.description, data: nil, toAddress: targetAddress.stripHexPrefix(), gas: gas)
                case (.flow, .eoa):
                    if token.isFlowCoin {
                        txId = try await FlowNetwork.sendFlowToEvm(evmAddress: targetAddress.stripHexPrefix(), amount: amount, gas: gas)
                    } else {
                        let flowIdentifier = "\(self.token.contractId).Vault"
                        txId = try await FlowNetwork.sendNoFlowTokenToEVM(vaultIdentifier: flowIdentifier, amount: amount, recipient: targetAddress)
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
                        let erc20Contract = try await FlowProvider.Web3.defaultContract()
                        let testData = erc20Contract?.contract.method("transfer", parameters: [targetAddress, Utilities.parseToBigUInt(amount.description, units: .ether)!], extraData: nil)
                        guard let toAddress = token.getAddress() else {
                            throw LLError.invalidAddress
                        }
                        txId = try await FlowNetwork.sendTransaction(amount: "0", data: testData, toAddress: toAddress.stripHexPrefix(), gas: gas)
                    }
                default:
                    failureBlock()
                    return
                }

                guard let id = txId else {
                    failureBlock()
                    return
                }

                DispatchQueue.main.async {
                    let obj = CoinTransferModel(amount: self.inputTokenNum, symbol: self.token.symbol ?? "", target: self.targetContact, from: address)
                    guard let data = try? JSONEncoder().encode(obj) else {
                        debugPrint("WalletSendAmountViewModel -> obj encode failed")
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

                    let holder = TransactionManager.TransactionHolder(id: id, type: .transferCoin, data: data)
                    TransactionManager.shared.newTransaction(holder: holder)
                }
            } catch {
                debugPrint("WalletSendAmountViewModel -> sendAction error: \(error)")
                failureBlock()
                showConfirmView = false
            }
        }
    }

    func changeTokenModelAction(token: TokenModel) {
        LocalUserDefaults.shared.recentToken = token.symbol

        self.token = token
        refreshTokenData()
        refreshInput()
    }
}

extension WalletSendAmountViewModel {
    func checkTransaction() {
        isEmptyTransation = TransactionManager.shared.holders.count == 0
    }

    @objc private func onHolderChanged(noti _: Notification) {
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
