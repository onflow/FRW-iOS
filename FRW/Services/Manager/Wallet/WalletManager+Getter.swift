//
//  WalletManager+Getter.swift
//  FRW
//
//  Created by Hao Fu on 9/4/2025.
//

import FlowWalletKit
import Foundation

// MARK: - Getter

extension WalletManager {
    var isSelectedChildAccount: Bool {
        selectedAccount?.type == .child
    }

    var isSelectedEVMAccount: Bool {
        selectedAccount?.type == .coa
    }

    var isSelectedFlowAccount: Bool {
        selectedAccount?.type == .main
    }

    var selectedAccountAddress: String? {
        return selectedAccount?.address.hexAddr
    }

    func getCurrentMnemonic() -> String? {
        guard let provider = keyProvider as? SeedPhraseKey else {
            return nil
        }
        return provider.hdWallet.mnemonic
    }

    func getCurrentPublicKey() -> String? {
        return mainAccount?.fullWeightKey?.publicKey.hex
    }

    func getCurrentPrivateKey() -> String? {
        guard let signAlgo = mainAccount?.fullWeightKey?.signAlgo else {
            return nil
        }
        return keyProvider?.privateKey(signAlgo: signAlgo)?.hexValue
    }

    func getPrimaryWalletAddress() -> String? {
        return mainAccount?.address.hexAddr
    }

    func getAddress() -> String? {
        return selectedAccount?.address.hexAddr
    }

    /// get custom watch address first, then primary address, this method is only used for tab2.
    func getPrimaryWalletAddressOrCustomWatchAddress() -> String? {
        LocalUserDefaults.shared.customWatchAddress ?? getAddress()
    }

    /// watch address -> child account address -> primary address
    func getWatchAddressOrChildAccountAddressOrPrimaryAddress() -> String? {
        if let customAddress = LocalUserDefaults.shared.customWatchAddress, !customAddress.isEmpty {
            return customAddress
        }

        return getAddress()
    }

    func isTokenActivated(model: TokenModel) -> Bool {
        for token in activatedCoins {
            if token.vaultIdentifier?.uppercased() == model.vaultIdentifier?.uppercased() {
                return true
            }
        }
        return false
    }

    func getToken(by vaultIdentifier: String?) -> TokenModel? {
        guard let identifier = vaultIdentifier else {
            return flowToken
        }
        for token in activatedCoins {
            if token.vaultIdentifier?.lowercased() == identifier.lowercased() {
                return token
            }
        }
        return nil
    }

    func getBalance(with token: TokenModel?) -> Decimal {
        guard let token else {
            return Decimal(0.0)
        }
        return token.showBalance ?? Decimal(0.0)
    }

    func currentContact() -> Contact {
        let address = getWatchAddressOrChildAccountAddressOrPrimaryAddress()
        var user: WalletAccount.User?
        if let addr = address {
            user = WalletManager.shared.walletAccount.readInfo(at: addr)
        }

        let contact = Contact(
            address: address,
            avatar: nil,
            contactName: nil,
            contactType: .user,
            domain: nil,
            id: UUID().hashValue,
            username: nil,
            user: user
        )
        return contact
    }
}
