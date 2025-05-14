//
//  WalletManger+Account.swift
//  FRW
//
//  Created by cat on 5/7/25.
//

import FlowWalletKit
import Foundation

// MARK: - Account

extension WalletManager {
    var selectedChildAccount: FlowWalletKit.ChildAccount? {
        guard isSelectedChildAccount else {
            return nil
        }
        guard let selectedAccountAddress else {
            return nil
        }
        return childs?.first { $0.address.hexAddr == selectedAccountAddress }
    }

    var selectedEVMAccount: COA? {
        guard isSelectedEVMAccount else {
            return nil
        }
        return coa
    }

    var selectedAccountContact: Contact? {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress() else {
            return nil
        }
        if let account = selectedChildAccount {
            return account.toContact()
        } else if let account = selectedEVMAccount {
            return account.toContact()
        } else {
            return toContact()
        }
    }
}

extension WalletManager {
    func toContact() -> Contact? {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddress() else {
            return nil
        }
        let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
        return Contact(
            address: primaryAddr,
            avatar: nil,
            contactName: nil,
            contactType: .user,
            domain: nil,
            id: UUID().hashValue,
            username: user.name,
            user: user,
            walletType: .flow
        )
    }
}

extension FlowWalletKit.ChildAccount {
    func toContact() -> Contact {
        Contact(address: address.hexAddr, avatar: icon?.absoluteString, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: name, walletType: .link)
    }
}

extension COA {
    func toContact() -> Contact {
        let showAddress = address.addHexPrefix()
        let user = WalletManager.shared.walletAccount.readInfo(at: showAddress)
        return Contact(address: showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .evm)
    }
}
