//
//  NFTUIKitCollectionPinnedSectionView.swift
//  Flow Wallet
//
//  Created by Selina on 11/8/2022.
//

import SwiftUI
import UIKit

class NFTUIKitCollectionPinnedSectionView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.Theme.BG.bg1
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
