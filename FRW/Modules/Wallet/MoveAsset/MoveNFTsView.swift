//
//  MoveNFTsView.swift
//  FRW
//
//  Created by cat on 2024/5/17.
//

import Kingfisher
import SwiftUI

// MARK: - MoveNFTsView

struct MoveNFTsView: RouteableView, PresentActionDelegate {
    // MARK: Internal

    var changeHeight: (() -> Void)?
    @StateObject
    var viewModel = MoveNFTsViewModel()

    @State private var isSearchFocused: Bool = false

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var detents: [UISheetPresentationController.Detent] {
        [.large()]
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleWithClosedView(title: "select_nfts".localized) {
                viewModel.closeAction()
            }
            .padding(.top, 18)

            accountView()

            Divider()
                .frame(height: 1)
                .foregroundStyle(Color.Theme.Line.line)
                .padding(.vertical, 12)

            NFTListView()

            VStack(spacing: 0) {
                InsufficientStorageToastView<MoveNFTsViewModel>()
                    .environmentObject(self.viewModel)
                    .background(Color.clear)

                VPrimaryButton(
                    model: ButtonStyle.primary,
                    state: viewModel.buttonState,
                    action: {
                        viewModel.moveAction()
                    },
                    title: viewModel.moveButtonTitle
                )
            }
            .background(Color.clear)
        }
        .padding(.horizontal, 18)
        .applyRouteable(self)
        .background(Color.Theme.Background.grey)
    }

    var hintView: some View {
        HStack(spacing: 4) {
            Image("icon_move_waring")
                .resizable()
                .frame(width: 20, height: 20)
            Text("move_nft_limit_x".localized(String(viewModel.limitCount)))
                .font(.inter(size: 14))
                .foregroundStyle(Color.Theme.Text.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.Theme.Accent.orange)
        .cornerRadius(24)
        .offset(y: -8)
    }

    func configNavigationItem(_: UINavigationItem) {}

    @ViewBuilder
    func accountView() -> some View {
        VStack(spacing: 16) {
            HStack {
                titleView(title: "account".localized)
                Spacer()
            }

            ContactRelationView(
                fromContact: viewModel.fromContact,
                toContact: viewModel.toContact,
                clickable: .all
            ) { contract in
                viewModel.handleFromContact(contract)
            } clickTo: { contract in
                viewModel.handleToContact(contract)
            } clickSwap: {
                viewModel.handleSwap()
            }

            MoveFeeView(isFree: viewModel.fromContact.walletType == viewModel.toContact.walletType)
                .visibility(viewModel.showFee ? .visible : .gone)
        }
    }

    @ViewBuilder
    func titleView(title: String) -> some View {
        Text(title)
            .font(.inter(size: 16))
            .foregroundStyle(Color.Theme.Text.black8)
    }

    @ViewBuilder
    func accountInfo(isFirst: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    viewModel.accountIcon(isFirst: isFirst)
                        .padding(.trailing, 4)
                    Text(viewModel.accountName(isFirst: isFirst))
                        .font(.inter(size: 14))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Theme.Text.black)
                        .padding(.trailing, 8)
                    EVMTagView()
                        .visibility(viewModel.showEVMTag(isFirst: isFirst) ? .visible : .gone)
                    Spacer()
                }

                Text(viewModel.accountAddress(isFirst: isFirst))
                    .font(.inter(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(Color.Theme.Text.black8)
            }

            Image("icon-arrow-bottom")
                .resizable()
                .frame(width: 12, height: 8)
                .visibility(isFirst ? .gone : .visible)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.Theme.Background.silver)
        .cornerRadius(12)
    }

    @ViewBuilder
    func NFTListView() -> some View {
        VStack(spacing: 0) {
            HStack {
                titleView(title: "collection".localized)
                Spacer()
                if let info = viewModel.selectedCollection {
                    Button {
                        viewModel.selectCollectionAction()
                    } label: {
                        HStack {
                            KFImage.url(info.maskLogo)
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .cornerRadius(8)
                                .clipped()
                                .padding(.trailing, 8)

                            Text(info.maskName)
                                .font(.inter(size: 14))
                                .foregroundStyle(Color.Theme.Text.black)
                                .padding(.trailing, 4)

                            viewModel.logo()
                                .resizable()
                                .frame(width: 12, height: 12)

                            Image("icon-arrow-bottom")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .padding(.bottom, 12)

            if viewModel.nfts.isEmpty && viewModel.loadingState == .success {
                HStack {
                    Spacer()
                    Text("0 NFTs")
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.Theme.Text.black3)
                    Spacer()
                }
                .padding(.top, 24)
            }

            if !viewModel.nfts.isEmpty {
                SearchBar(placeholder: "search_nft_name".localized, searchText: $viewModel.searchText, isFocused: $isSearchFocused)
                    .padding(.bottom)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.filteredNFTItems) { nft in
                        NFTView(
                            nft: nft,
                            reachMax: viewModel.showHint,
                            collection: self.viewModel.selectedCollection
                        ) { model in
                            viewModel.toggleSelection(of: model)
                        }
                    }
                }
                Spacer()
            }
            .overlay(alignment: .bottom) {
                hintView
                    .visibility(viewModel.showHint ? .visible : .gone)
                    .animation(.easeInOut, value: viewModel.selectedCount)
            }
        }
        .overlay {
            switch viewModel.loadingState {
            case .loading:
                NFTLoadingView(loadedCount: viewModel.loadedCount, totalCount: viewModel.totalCount)
            case .failure:
                ErrorWithTryView(
                    message: .check,
                    retryAction: viewModel.retry
                )
            case .idle, .success:
                EmptyView()
            }
        }
    }

    func customViewDidDismiss() {
        MoveAssetsAction.shared.endBrowser()
    }

    // MARK: Private

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 4),
    ]
}

// MARK: MoveNFTsView.NFTView

extension MoveNFTsView {
    struct NFTView: View {
        // MARK: Internal

        var nft: MoveNFTsViewModel.NFT
        var reachMax: Bool
        var collection: CollectionMask?
        var click: (MoveNFTsViewModel.NFT) -> Void

        var body: some View {
            VStack {
                KFImage.url(URL(string: nft.imageUrl))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .padding(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(16)
            .clipped()
            .overlay(alignment: .topTrailing) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(showMask() ? Color.clear : Color.Theme.Accent.green, lineWidth: 1)
                        .background(Color.black.opacity(0.6))
                        .zIndex(101)
                        .visibility(nft.isSelected || showMask() ? .visible : .gone)

                    Image(nft.isSelected ? "evm_check_1" : "evm_check_0")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding([.top, .trailing], 8)
                        .visibility(allowSelect() ? .visible : .gone)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                if allowSelect() {
                    click(nft)
                }
            }
        }

        // MARK: Private

        private func showMask() -> Bool {
            if nft.isSelected {
                return false
            }
            if reachMax {
                return true
            }
            return !allowSelect()
        }

        private func allowSelect() -> Bool {
            guard let model = collection else {
                return false
            }
            return !model.maskContractName.isEmpty
        }
    }
}

#Preview {
    MoveNFTsView()
}
