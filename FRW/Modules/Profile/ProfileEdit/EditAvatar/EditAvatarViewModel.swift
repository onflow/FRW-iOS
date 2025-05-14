//
//  EditAvatarViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 16/6/2022.
//

import Kingfisher

import SwiftUI

extension EditAvatarView {
    enum Mode {
        case preview
        case edit
    }

    struct AvatarItemModel: Identifiable {
        // MARK: Lifecycle

        init(type: ItemType, avatarString: String? = nil, nft: NFTModel? = nil) {
            self.type = type
            self.avatarString = avatarString
            self.nft = nft
        }

        // MARK: Internal

        enum ItemType {
            case string
            case nft
        }

        var type: ItemType
        var avatarString: String?
        var nft: NFTModel?

        var id: String {
            if let avatarString = avatarString {
                return avatarString
            }

            if let tokenID = nft?.id {
                return tokenID
            } else {
                assertionFailure("tokenID should not be nil")
            }

            assertionFailure("AvatarItemModel id should not be nil")
            return ""
        }

        func getCover() -> String {
            if let avatarString = avatarString {
                return avatarString.convertedAvatarString()
            }

            if let nftCover = nft?.image {
                return nftCover.absoluteString.convertedAvatarString()
            }

            return ""
        }

        func getName() -> String {
            if type == .string {
                return "current_avatar".localized
            }

            return nft?.title ?? " "
        }
    }
}

// MARK: - EditAvatarView.EditAvatarViewModel

extension EditAvatarView {
    class EditAvatarViewModel: ObservableObject {
        // MARK: Lifecycle

        init() {
            var cachedItems = [AvatarItemModel]()

            if let currentAvatar = UserManager.shared.userInfo?.avatar {
                cachedItems.append(EditAvatarView.AvatarItemModel(
                    type: .string,
                    avatarString: currentAvatar
                ))
            }

            if let cachedNFTs = NFTUIKitCache.cache.getGridNFTs() {
                for nft in cachedNFTs {
                    let model = NFTModel(nft, in: nil)
                    cachedItems.append(EditAvatarView.AvatarItemModel(
                        type: .nft,
                        avatarString: nil,
                        nft: model
                    ))
                }
            }

            items = cachedItems

            if let first = items.first, first.type == .string {
                selectedItemId = first.id
                oldAvatarItem = first
            }

            loadMoreAvatarIfNeededAction()
        }

        // MARK: Internal

        @Published
        var mode: Mode = .preview
        @Published
        var items: [AvatarItemModel] = []
        @Published
        var selectedItemId: String?

        func currentSelectModel() -> AvatarItemModel? {
            for item in items {
                if item.id == selectedItemId {
                    return item
                }
            }

            return nil
        }

        func save() {
            guard let item = currentSelectModel() else {
                return
            }

            if let idString = oldAvatarItem?.id, item.id == idString {
                mode = .preview
                return
            }

            guard let url = URL(string: item.getCover()) else {
                HUD.error(title: "avatar_info_error".localized)
                return
            }

            let failed = {
                DispatchQueue.main.async {
                    HUD.dismissLoading()
                    HUD.error(title: "change_avatar_error".localized)
                }
            }

            let success: (UIImage) -> Void = { img in
                Task {
                    guard let firebaseURL = await FirebaseStorageUtils.upload(avatar: img) else {
                        failed()
                        return
                    }

                    let result = await self.uploadAvatarURL(firebaseURL)
                    if !result {
                        failed()
                        return
                    }

                    DispatchQueue.main.async {
                        HUD.dismissLoading()
                        UserManager.shared.updateAvatar(firebaseURL)
                        Router.pop()
                    }
                }
            }

            HUD.loading("saving".localized)
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case let .success(r):
                    debugPrint(
                        "EditAvatarViewModel -> save action, did get image from: \(r.cacheType)"
                    )
                    success(r.image)
                case let .failure(e):
                    debugPrint("EditAvatarViewModel -> save action, did failed get image: \(e)")
                    failed()
                }
            }
        }

        // MARK: Private

        private var oldAvatarItem: AvatarItemModel?

        private var isEnd: Bool = false
        private var isRequesting: Bool = false

        private func uploadAvatarURL(_ url: String) async -> Bool {
            guard let nickname = UserManager.shared.userInfo?.nickname else {
                return false
            }

            let request = UserInfoUpdateRequest(nickname: nickname, avatar: url)
            do {
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.Profile.updateInfo(request))
                if response.httpCode != 200 {
                    return false
                }

                return true
            } catch {
                return false
            }
        }
    }
}

extension EditAvatarView.EditAvatarViewModel {
    func loadMoreAvatarIfNeededAction() {
        if let lastItem = items.last, let selectId = selectedItemId, lastItem.id == selectId,
           isRequesting == false, isEnd == false
        {
            isRequesting = true

            Task {
                var currentCount = items.count
                if items.first?.type == .string {
                    currentCount -= 1
                }

                do {
                    try await requestGridAction(offset: currentCount)
                    DispatchQueue.main.async {
                        self.isRequesting = false
                    }
                } catch {
                    debugPrint(
                        "EditAvatarViewModel -> loadMoreAvatarIfNeededAction request failed: \(error)"
                    )
                    DispatchQueue.main.async {
                        self.isRequesting = false
                    }
                }
            }
        }
    }

    private func requestGridAction(offset: Int) async throws {
        let limit = 24
        let nfts = try await requestGrid(offset: offset, limit: limit)
        await MainActor.run {
            self.appendGridNFTsNoDuplicated(nfts)
            self.isEnd = nfts.count < limit
            self.saveToCache()
        }
    }

    private func requestGrid(offset: Int, limit: Int = 24) async throws -> [NFTModel] {
        let address = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? ""
        let request = NFTGridDetailListRequest(address: address, offset: offset, limit: limit)
        let from: VMType = WalletManager.shared.isSelectedEVMAccount ? .evm : .cadence
        let response: Network.Response<NFTListResponse> = try await Network
            .requestWithRawModel(FRWAPI.NFT.gridDetailList(
                request,
                from
            ))

        guard let nfts = response.data?.nfts else {
            return []
        }

        let models = nfts.map { NFTModel($0, in: nil) }
        return models
    }

    private func appendGridNFTsNoDuplicated(_ newNFTs: [NFTModel]) {
        for nft in newNFTs {
            let exist = items.first { $0.type == .nft && $0.nft?.id == nft.id }

            if exist == nil {
                items.append(EditAvatarView.AvatarItemModel(
                    type: .nft,
                    avatarString: nil,
                    nft: nft
                ))
            }
        }
    }

    private func saveToCache() {
        var nfts = [NFTResponse]()

        for item in items {
            if item.type == .nft, let nft = item.nft {
                nfts.append(nft.response)
            }
        }

        NFTUIKitCache.cache.saveGridToCache(nfts)
    }
}
