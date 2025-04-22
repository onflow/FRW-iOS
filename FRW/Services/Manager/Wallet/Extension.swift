//
//  Extension.swift
//  FRW
//
//  Created by Hao Fu on 7/4/2025.
//

import Foundation
import Flow

extension Flow.AccountKey {
    func toCodableModel() -> AccountKey {
        AccountKey(
            hashAlgo: hashAlgo.index,
            publicKey: publicKey.hex,
            signAlgo: signAlgo.index,
            weight: weight
        )
    }
}
