//
//  MoveTokenViewModel.swift
//  FRW
//
//  Created by cat on 2024/2/27.
//

import SwiftUI
import Flow

class MoveTokenViewModel: ObservableObject {
    @Published var inputDollarNum: Double = 0

    @Published var showBalance: String = ""
    var actualBalance: String = ""
    
    @Published var inputTokenNum: Double = 0
    @Published var amountBalance: Double = 0
    @Published var coinRate: Double = 0
    @Published var errorType: WalletSendAmountView.ErrorType = .none

    @Published var buttonState: VPrimaryButtonState = .disabled

    @Published var fromContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)
    @Published var toContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)

    private var minBalance: Double? = nil
    
    var token: TokenModel
    @Binding var isPresent: Bool

    init(token: TokenModel, isPresent: Binding<Bool>) {
        self.token = token
        _isPresent = isPresent
        loadUserInfo()
        refreshTokenData()
        Task {
            await fetchMinFlowBalance()
        }
    }

    private func loadUserInfo() {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress() else {
            return
        }
        if let account = ChildAccountManager.shared.selectedChildAccount {
            fromContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        } else if let account = EVMAccountManager.shared.selectedAccount {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            fromContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            fromContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        }

        if ChildAccountManager.shared.selectedChildAccount != nil || EVMAccountManager.shared.selectedAccount != nil {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            toContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        } else if let account = EVMAccountManager.shared.accounts.first {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            toContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else if let account = ChildAccountManager.shared.childAccounts.first {
            toContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        }
    }

    private func fetchMinFlowBalance() async {
        do {
            self.minBalance = try await FlowNetwork.minFlowBalance()
            log.debug("[Flow] min balance:\(self.minBalance ?? 0.001)")
        } catch {
            self.minBalance = 0.001
        }
    }
    
    private func updateBalance(_ text: String) {
        guard !text.isEmpty else {
            showBalance = ""
            actualBalance = ""
            return
        }
        
    }
    
    func changeTokenModelAction(token: TokenModel) {
        if token.contractId == self.token.contractId {
            return
        }
        self.token = token
        updateBalance("")
        errorType = .none
        refreshTokenData()
    }

    private func refreshTokenData() {
        amountBalance = WalletManager.shared.getBalance(bySymbol: token.symbol ?? "")
        coinRate = CoinRateCache.cache.getSummary(for: token.symbol ?? "")?.getLastRate() ?? 0
    }

    func inputTextDidChangeAction(text _: String) {
        refreshSummary()
        updateState()
    }

    func refreshSummary() {
        if showBalance.isEmpty {
            inputTokenNum = 0.0
            inputDollarNum = 0.0
            errorType = .none
            return
        }

        if !showBalance.isNumber {
            inputTokenNum = 0.0
            inputDollarNum = 0.0
            errorType = .formatError
            return
        }
        
        actualBalance = showBalance.doubleValue
            .formatCurrencyString(digits: token.decimal)
        inputTokenNum = actualBalance.doubleValue
        inputDollarNum = inputTokenNum * coinRate * CurrencyCache.cache.currentCurrencyRate
        
        if inputTokenNum > amountBalance {
            errorType = .insufficientBalance
            return
        }
        
        if !allowZero() {
            errorType = .insufficientBalance
            return
        }
        errorType = .none
    }

    func maxAction() {
        Task {
            let num = await updateAmountIfNeed(inputAmount: amountBalance)
            DispatchQueue.main.async {
                self.showBalance = num.formatCurrencyString()
                self.actualBalance = num.formatCurrencyString(digits: self.token.decimal)
                self.refreshSummary()
                self.updateState()
            }
        }
    }
    
    private func isFromFlowToCoa() -> Bool {
        return token.isFlowCoin && fromContact.walletType == .flow && toContact.walletType == .evm
    }
    
    private func allowZero() -> Bool {
        guard isFromFlowToCoa() else {
            return true
        }
        return false
    }
    
    private func updateAmountIfNeed(inputAmount: Double) async -> Double {
        guard isFromFlowToCoa() else {
            return max(inputAmount, 0)
        }
        if self.minBalance == nil {
            HUD.loading()
            await fetchMinFlowBalance()
            HUD.dismissLoading()
        }
        // move fee
        let num = max(
            inputAmount - (
                minBalance ?? WalletManager.minDefaultBlance
            ) - WalletManager.moveFee,
            0
        )
        return num
    }

    
    private func updateState() {
        DispatchQueue.main.async {
            self.buttonState = self.isReadyForSend ? .enabled : .disabled
        }
        
    }

    var isReadyForSend: Bool {
        return errorType == .none && showBalance.isNumber && !showBalance.isEmpty
    }

    var currentBalance: String {
        let totalStr = amountBalance.formatCurrencyString()
        return "Balance: \(totalStr)"
    }
}

extension MoveTokenViewModel {
    var fromIsEVM: Bool {
        EVMAccountManager.shared.accounts.contains { $0.showAddress.lowercased() == fromContact.address?.lowercased() }
    }

    var toIsEVM: Bool {
        EVMAccountManager.shared.accounts.contains { $0.showAddress.lowercased() == toContact.address?.lowercased() }
    }

    var balanceAsCurrentCurrencyString: String {
        return inputDollarNum.formatCurrencyString(considerCustomCurrency: true)
    }
    
    var showFee: Bool {
        !(fromContact.walletType == .link || toContact.walletType == .link)
    }
}

extension MoveTokenViewModel {
    func onNext() {
        
        if fromContact.walletType == .link || toContact.walletType == .link {
            Task {
                do {
                    var tid: Flow.ID?
                    let amount = self.inputTokenNum.decimalValue
                    let vaultIdentifier = (fromIsEVM ? (token.flowIdentifier ?? "") : token.contractId + ".Vault")
                    switch (fromContact.walletType, toContact.walletType) {
                    case (.link, .evm):
                        tid = try await FlowNetwork
                            .bridgeChildTokenToCoa(
                                vaultIdentifier: vaultIdentifier,
                                child: fromContact.address ?? "",
                                amount: amount
                            )
                    case (.evm, .link):
                        tid = try await FlowNetwork
                            .bridgeChildTokenFromCoa(
                                vaultIdentifier: vaultIdentifier,
                                child: toContact.address ?? "",
                                amount: amount
                            )
                    default:
                        break
                    }
                    
                    if let txid = tid {
                        let holder = TransactionManager.TransactionHolder(id: txid, type: .moveAsset)
                        TransactionManager.shared.newTransaction(holder: holder)
                    }
                    DispatchQueue.main.async {
                        self.closeAction()
                        self.buttonState = .enabled
                    }
                }
                catch {
                    log.error(" Move Token: \(fromContact.walletType?.rawValue ?? "") to  \(toContact.walletType?.rawValue ?? "") failed. \(error)")
                    log.error(error)
                    buttonState = .enabled
                }
            }
            
        }
        if token.isFlowCoin {
            if WalletManager.shared.isSelectedEVMAccount {
                withdrawCoa()
            } else {
                fundCoa()
            }
        } else {
            bridgeToken()
        }
    }

    func onChooseAccount() {}

    private func withdrawCoa() {
        Task {
            do {
                log.info("[EVM] withdraw Coa balance")
                DispatchQueue.main.async {
                    self.buttonState = .loading
                }
                let amount = self.inputTokenNum.decimalValue
                let txid = try await FlowNetwork.withdrawCoa(amount: amount)
                let holder = TransactionManager.TransactionHolder(id: txid, type: .transferCoin)
                TransactionManager.shared.newTransaction(holder: holder)
                HUD.dismissLoading()

                WalletManager.shared.reloadWalletInfo()
                DispatchQueue.main.async {
                    self.closeAction()
                    self.buttonState = .enabled
                }
            } catch {
                DispatchQueue.main.async {
                    self.buttonState = .enabled
                }
                log.error("[EVM] move transation failed \(error)")
            }
        }
    }

    private func fundCoa() {
        Task {
            do {
                log.info("[EVM] fund Coa balance")
                let maxAmount = await updateAmountIfNeed(
                    inputAmount: amountBalance
                )
                guard maxAmount >= self.inputTokenNum else {
                    HUD.error(title: "Insufficient_balance::message".localized)
                    return
                }
                DispatchQueue.main.async {
                    self.buttonState = .loading
                }
                let amount = self.inputTokenNum.decimalValue
                log.debug("[amount] move \(self.inputTokenNum)")
                log.debug("[amount] move \(amount.description)")
                let txid = try await FlowNetwork.fundCoa(amount: amount)
                let holder = TransactionManager.TransactionHolder(id: txid, type: .transferCoin)
                TransactionManager.shared.newTransaction(holder: holder)

                WalletManager.shared.reloadWalletInfo()
                DispatchQueue.main.async {
                    self.closeAction()
                    self.buttonState = .enabled
                }
            } catch {
                DispatchQueue.main.async {
                    self.buttonState = .enabled
                }
                log.error("[EVM] move transation failed \(error)")
            }
        }
    }

    private func bridgeToken() {
        Task {
            do {
                // TODO:

                DispatchQueue.main.async {
                    self.buttonState = .loading
                }
                log.info("[EVM] bridge token \(fromIsEVM ? "FromEVM" : "ToEVM")")
                let amount = self.inputTokenNum.decimalValue

                let vaultIdentifier = (fromIsEVM ? (token.flowIdentifier ?? "") : token.contractId + ".Vault")
                let txid = try await FlowNetwork.bridgeToken(vaultIdentifier: vaultIdentifier, amount: amount, fromEvm: fromIsEVM, decimals: token.decimal)
                let holder = TransactionManager.TransactionHolder(id: txid, type: .transferCoin)
                TransactionManager.shared.newTransaction(holder: holder)

                WalletManager.shared.reloadWalletInfo()
                DispatchQueue.main.async {
                    self.closeAction()
                    self.buttonState = .enabled
                }
            } catch {
                DispatchQueue.main.async {
                    self.buttonState = .enabled
                }
                log.error("[EVM] move transation bridge token failed \(error)")
            }
        }
    }

    func closeAction() {
        Router.dismiss {
            MoveAssetsAction.shared.endBrowser()
        }
    }
}
