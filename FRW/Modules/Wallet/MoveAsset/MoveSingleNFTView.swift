//
//  MoveSingleNFTView.swift
//  FRW
//
//  Created by cat on 2024/5/22.
//

import Kingfisher
import SwiftUI
import SwiftUIX

struct MoveSingleNFTView: RouteableView, PresentActionDelegate {
    // MARK: Lifecycle

    init(nft: NFTModel, fromChildAccount: ChildAccount? = nil, callback: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: MoveSingleNFTViewModel(
            nft: nft,
            fromChildAccount: fromChildAccount,
            callback: callback
        ))
    }

    // MARK: Internal

    @StateObject
    var viewModel: MoveSingleNFTViewModel

    var changeHeight: (() -> Void)?

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        VStack {
            HStack {
                Text("move_single_nft".localized)
                    .font(.inter(size: 18, weight: .w700))
                    .foregroundStyle(Color.LL.Neutrals.text)
                    .frame(height: 28)
                Spacer()

                Button {
                    viewModel.closeAction()
                } label: {
                    Image("icon_close_circle_gray")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .offset(x: -3)
                }
            }
            .padding(.top, 18)

            VStack(spacing: 8) {
                ContactRelationView(
                    fromContact: viewModel.fromContact,
                    toContact: viewModel.toContact,
                    clickable: .to,
                    clickTo: { contact in
                        let model = MoveAccountsViewModel(
                            selected: viewModel.toContact
                                .address ?? ""
                        ) { contact in
                            if let contact = contact {
                                viewModel.updateToContact(contact)
                            }
                        }
                        Router.route(to: RouteMap.Wallet.chooseChild(model))
                    }
                )

                VStack(spacing: 12) {
                    HStack(spacing: 40) {
                        KFImage.url(viewModel.nft.imageURL)
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()

                        VStack(alignment: .leading, spacing: 0) {
                            Text(viewModel.nft.title)
                                .font(.inter(size: 16, weight: .bold))
                                .foregroundColor(.Theme.Text.black)
                                .frame(height: 26)

                            HStack(alignment: .center, spacing: 4) {
                                KFImage
                                    .url(viewModel.nft.logoUrl)
                                    .placeholder {
                                        Image("placeholder")
                                            .resizable()
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .cornerRadius(10)
                                    .clipped()
                                Text(viewModel.nft.collectionName)
                                    .font(.inter(size: 14))
                                    .lineLimit(1)
                                    .foregroundColor(.Theme.Text.black6)
                                viewModel.logo()
                                    .resizable()
                                    .frame(width: 12, height: 12)
                            }
                        }

                        Spacer()
                    }

                    VStack(spacing: 12) {
                        Divider()
                            .foregroundStyle(Color.Theme.Line.stroke)
                        MoveFeeView(isFree: viewModel.isFeeFree)
                    }
                    .visibility(viewModel.showFee ? .visible : .gone)
                }
                .padding(16)
                .background(.Theme.BG.bg3)
                .cornerRadius(16)
            }

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.buttonState,
                action: {
                    viewModel.moveAction()
                },
                title: "move".localized
            )
//                .padding(.horizontal, 18)
        }
        .padding(.horizontal, 18)
        .hideKeyboardWhenTappedAround()
        .cornerRadius([.topLeading, .topTrailing], 16)
        .edgesIgnoringSafeArea(.bottom)
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview {
    MoveSingleNFTView(
        nft: NFTModel(NFTResponse(
            id: "",
            name: "",
            description: "",
            thumbnail: "",
            externalURL: "",
            contractAddress: "",
            evmAddress: "",
            address: "",
            collectionID: "",
            collectionName: "",
            collectionDescription: "",
            collectionSquareImage: "",
            collectionExternalURL: "",
            collectionContractName: "",
            collectionBannerImage: "",
            traits: [],
            postMedia: NFTPostMedia(title: "", description: "", video: "", isSvg: false)
        ), in: nil),
        callback: {}
    )
}
