//
//  NFTDetailPageViewModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 6/9/2022.
//

import Foundation
import Kingfisher
import Lottie
import SwiftUI

class NFTDetailPageViewModel: ObservableObject {
    // MARK: Lifecycle

    init(nft: NFTModel) {
        self.nft = nft
        if nft.isSVG {
            guard let rawSVGURL = nft.response.postMedia?.image,
                  let rawSVGURL = URL(string: rawSVGURL.replacingOccurrences(
                      of: "https://lilico.app/api/svg2png?url=",
                      with: ""
                  ))
            else {
                return
            }

            Task {
                if let svg = await SVGCache.cache.getSVG(rawSVGURL) {
                    await MainActor.run {
                        self.svgString = svg
                    }
                } else if let svg = nft.imageSVGStr {
                    await MainActor.run {
                        self.svgString = svg
                    }
                } else {
                    await MainActor.run {
                        self.nft.isSVG = false
                        self.nft.response.postMedia?.image = self.nft.response.postMedia?.image?
                            .convertedSVGURL()?.absoluteString
                    }
                }
            }
        }
        updateCollectionIfNeed()
        fetchNFTStatus()
        updateSendButton()
    }

    // MARK: Internal

    @Published
    var nft: NFTModel
    @Published
    var svgString: String = ""
    @Published
    var movable: Bool = false
    @Published
    var showSendButton: Bool = false

    @Published
    var isPresentMove = false

    let animationView = AnimationView(name: "inAR", bundle: .main)

    func sendNFTAction(fromChildAccount: ChildAccount? = nil) {
        Router.route(to: RouteMap.AddressBook.pick { [weak self] contact in
            Router.dismiss(animated: true) {
                guard let self = self else {
                    return
                }
                Router.route(to: RouteMap.NFT.send(self.nft, contact, fromChildAccount))
            }
        })
    }

    func image() async -> UIImage {
        guard let image = await ImageHelper.image(from: nft.imageURL.absoluteString) else {
            return UIImage(imageLiteralResourceName: "placeholder")
        }

        return image
    }

    func showMoveAction() {
        isPresentMove = true
    }

    func fetchNFTStatus() {
        if nft.isDomain {
            movable = false
            return
        }
        movable = true
    }

    // MARK: Private

    private func updateSendButton() {
        let remote = RemoteConfigManager.shared.config?.features.nftTransfer ?? false
        if remote == true {
            if nft.isDomain {
                showSendButton = false
            } else {
                showSendButton = true
            }
        } else {
            showSendButton = false
        }
    }

    private func updateCollectionIfNeed() {
        guard let contractAddress = nft.response.contractAddress else {
            return
        }
        Task { [weak self] in
            let nftCollection = await NFTCollectionConfig.share.get(from: contractAddress)
            guard let self = self else { return }
            if self.nft.collection == nil {
                self.nft.collection = nftCollection
            }
        }
    }
}
