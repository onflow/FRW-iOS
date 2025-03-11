//
//  NFTUIKitListView.swift
//  Flow Wallet
//
//  Created by Selina on 11/8/2022.
//

import SwiftUI

struct NFTUIKitListView: UIViewControllerRepresentable {
    var vm: NFTTabViewModel

    func makeUIViewController(context _: Context) -> NFTUIKitListViewController {
        let vc = NFTUIKitListViewController()
        vc.listStyleHandler.vm = vm
        return vc
    }

    func updateUIViewController(_: NFTUIKitListViewController, context _: Context) {}
}

#Preview {
    NFTUIKitListView(vm: NFTTabViewModel())
}
