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
    var tokenCount: String { get }
    var nftCount: String { get }
    var isMain: Bool { get }
    var isCoa: Bool { get }
    var walletMetadata: WalletAccount.User { get }

    func avatar(isSelected: Bool, subAvatar: AvatarSource?) -> AvatarView
}

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

    var tokenCount: String {
        "0 Flow"
    }

    var nftCount: String {
        "0 NFT's"
    }

    var isMain: Bool {
        true
    }

    var isCoa: Bool {
        false
    }

    var walletMetadata: WalletAccount.User {
        WalletManager.shared.walletAccount.readInfo(at: hexAddr)
    }
}
