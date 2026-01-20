//
//  NotificationDefine.swift
//  Flow Wallet
//
//  Created by Selina on 21/6/2022.
//

import Foundation

public extension Notification.Name {
    static let walletHiddenFlagUpdated = Notification.Name("walletHiddenFlagUpdated")
    static let quoteMarketUpdated = Notification.Name("quoteMarketUpdated")
    static let coinSummarysUpdated = Notification.Name("coinSummarysUpdated")
    static let addressBookDidAdd = Notification.Name("addressBookDidAdd")
    static let addressBookDidEdit = Notification.Name("addressBookDidEdit")
    static let backupTypeDidChanged = Notification.Name("backupTypeDidChanged")
    static let nftFavDidChanged = Notification.Name("nftFavDidChanged")
    static let nftCollectionsDidChanged = Notification.Name("nftCollectionsDidChanged")
    static let nftCacheDidChanged = Notification.Name("nftCacheDidChanged")

    static let transactionManagerDidChanged = Notification.Name("transactionManagerDidChanged")
    static let transactionStatusDidChanged = Notification.Name("transactionStatusDidChanged")

    static let transactionCountDidChanged = Notification.Name("transactionCountDidChanged")

    static let watchAddressDidChanged = Notification.Name("watchAddressDidChanged")

    static let webBookmarkDidChanged = Notification.Name("webBookmarkDidChanged")
    static let willResetWallet = Notification.Name("willResetWallet")
    static let didResetWallet = Notification.Name("didResetWallet")
    static let didFinishAccountLogin = Notification.Name("didFinishedAccountLogin")

    static let networkChange = Notification.Name("networkChange")

    static let openNFTCollectionList = Notification.Name("openNFTCollectionList")
    static let toggleSideMenu = Notification.Name("toggleSideMenu")

    static let nftCountChanged = Notification.Name("nftCountChanged")
    static let childAccountChanged = Notification.Name("childAccountChanged")

    static let syncDeviceStatusDidChanged = Notification.Name("syncDeviceStatusDidChanged")

    static let nftDidChangedByMoving = Notification.Name("nftDidChangedByMoving")

    static let remoteConfigDidUpdate = Notification.Name("remoteConfigDidUpdate")
    static let accountDataDidUpdate = Notification.Name("accountDataDidUpdate")
    static let dropboxCallback = Notification.Name("multiBack.dropboxCallback")
}
