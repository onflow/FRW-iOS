//
//  AccountInfoProtocol.swift
//  FRW
//
//  Created by cat on 5/29/25.
//

import FlowWalletKit
import SwiftUI

protocol AccountInfoProtocol {
    var infoName: String { get }
    var infoAddress: String { get }
    var accountType: FWAccount.AccountType { get }

    var walletMetadata: WalletAccount.User { get }

    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView
}

extension AccountInfoProtocol {
    var walletMetadata: WalletAccount.User {
        WalletManager.shared.walletAccount.readInfo(at: infoAddress)
    }
}

// MARK: Account

extension FlowWalletKit.Account: AccountInfoProtocol {
    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView {
        AvatarView(mainAvatar: .user(walletMetadata), subAvatar: subAvatar, backgroundColor: Color.Summer.cards, isSelected: isSelected)
    }

    var infoName: String {
        walletMetadata.name
    }

    var infoAddress: String {
        hexAddr
    }

    var accountType: FWAccount.AccountType {
        .main
    }
}

// MARK: COA

extension FlowWalletKit.COA: AccountInfoProtocol {
    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView {
        AvatarView(mainAvatar: .user(walletMetadata), subAvatar: subAvatar, backgroundColor: Color.Summer.cards, isSelected: isSelected)
    }

    var infoName: String {
        walletMetadata.name
    }

    var infoAddress: String {
        address
    }

    var accountType: FWAccount.AccountType {
        .coa
    }
}

// MARK: FlowWalletKit.Account of AccountInfoProtocol

extension FlowWalletKit.ChildAccount: AccountInfoProtocol {
    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView {
        AvatarView(mainAvatar: .url(icon ?? AppPlaceholder.imageURL), subAvatar: subAvatar, isSelected: isSelected)
    }

    var infoName: String {
        name ?? "unknown"
    }

    var infoAddress: String {
        address.hexAddr
    }

    var accountType: FWAccount.AccountType {
        .child
    }
}
