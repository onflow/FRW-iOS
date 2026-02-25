//
//  EnvDefine.swift
//  Flow Wallet
//
//  Created by Selina on 22/12/2022.
//

import Foundation

let AppGroupName = "group.com.flowfoundation.wallet"
let AppBundleName = "com.flowfoundation.wallet"
let isDevMode = false
let FirstFavNFTImageURL = "FirstFavNFTImageURL"

func groupUserDefaults() -> UserDefaults? {
    UserDefaults(suiteName: AppGroupName)
}
