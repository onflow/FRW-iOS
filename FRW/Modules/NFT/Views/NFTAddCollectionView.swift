//
//  NFTAddCollectionView.swift
//  Flow Wallet
//
//  Created by cat on 2022/6/19.
//

import Kingfisher
import SwiftUI

// MARK: - NFTAddCollectionView

struct NFTAddCollectionView: RouteableView {
    @State
    private var offset: CGFloat = 0

    @StateObject
    var addViewModel = AddCollectionViewModel()

    @State
    private var selectItem: NFTCollectionItem?

    var title: String {
        "add_collection".localized
    }

    var body: some View {
        VStack(spacing: 0) {
            // TODO: show page by the status: empty, loading, net error, list

            OffsetScrollView(offset: $offset) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(addViewModel.liveList, id: \.self) { it in
                        NFTAddCollectionView.CollectionItem(item: it) { item in
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                            self.selectItem = item
                            if self.selectItem != nil {
                                addViewModel.isConfirmSheetPresented.toggle()
                            }
                        }
                    }
                }
            }
            .searchable(text: $addViewModel.searchQuery, prompt: "search_NFT_collection".localized)
        }
        .background(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
        .halfSheet(showSheet: $addViewModel.isConfirmSheetPresented, autoResizing: true, backgroundColor: Color.LL.Neutrals.background) {
            if let item = self.selectItem {
                NFTAddCollectionView.NFTCollectionEnableView(item: item)
                    .environmentObject(addViewModel)
            }
        }
        .mockPlaceholder(addViewModel.isMock)
    }

    private func title(title: String) -> some View {
        Text(title.localized.uppercased())
            .foregroundColor(.LL.Neutrals.neutrals6)
            .font(.LL.body.weight(.w600))
    }
}

// MARK: NFTAddCollectionView.CollectionItem

extension NFTAddCollectionView {
    struct CollectionItem: View {
        // MARK: Internal

        var item: NFTCollectionItem
        var onAdd: (_ item: NFTCollectionItem) -> Void

        var body: some View {
            HStack(alignment: .center) {
                Button {
                    if let website = item.collection.officialWebsite,
                       let url = URL(string: website)
                    {
                        if let isOn = RemoteConfigManager.shared.config?.features.browser, isOn {
                            Router.route(to: RouteMap.Explore.browser(url))
                        }
                    }

                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text(item.collection.name ?? "")
                                .font(.LL.largeTitle3)
                                .fontWeight(.w700)
                                .foregroundColor(.LL.Neutrals.text)
                            Image("Flow")
                                .resizable()
                                .frame(width: 12, height: 12)
                            Image("arrow_right_grey")
                                .resizable()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.LL.text)
                        }
                        .frame(height: 26)

                        Text(item.collection.description ?? "")
                            .font(Font.inter(size: 12, weight: .w400))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.LL.Neutrals.neutrals7)
                            .padding(.bottom, 18)
                            .lineLimit(2)
                    }
                    .padding(.leading, 18)
                }

                Spacer(minLength: 88)
                Button {
                    onAdd(item)

                } label: {
                    Image("icon_nft_add")
                        .foregroundColor(.LL.Primary.salmonPrimary)
                        .frame(width: 26, height: 26, alignment: .center)
                        .padding(6)
                        .background(.LL.Shades.front)
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .visibility(
                    isEVMAccount ? .invisible :
                        (item.status == .own ? .invisible : .visible)
                )
            }
            .frame(height: 88)
            .background(
                ZStack {
                    HStack {
                        Spacer()
                        KFImage
                            .url(item.collection.logoURL)
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 148, height: 148, alignment: .trailing)
                            .clipped()
                    }
                    .blur(radius: 6)

                    LinearGradient(
                        colors:
                        [
                            .LL.Shades.front,
                            .LL.Shades.front.opacity(0.88),
                            .LL.Shades.front.opacity(0.32),

                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .padding(.top, 12)
            .padding(.horizontal, 18)
        }

        var isEVMAccount: Bool {
            WalletManager.shared.isSelectedEVMAccount
        }

        // MARK: Private

        @State
        private var isPresented = false
    }
}

extension NFTAddCollectionView {
    // TODO:
    struct ErrorView: View {
        var body: some View {
            Text("Error Net")
        }
    }

    struct EmptyView: View {
        var body: some View {
            Text("Empty")
        }
    }
}

// struct NFTAddCollectionView_Previews: PreviewProvider {
//
//
//
//    static let item = NFTCollectionItem(collection: NFTCollectionInfo(logo:"https://raw.githubusercontent.com/Outblock/assets/main/nft/nyatheesovo/ovologo.jpeg", name: "OVO", contractName: "", address: ContractAddress(mainnet: "", testnet: ""), secureCadenceCompatible: SecureCadenceCompatible(mainnet: true, testnet: true), banner: nil, officialWebsite: nil, marketplace: nil, description: "hhhhhhhh", path: ContractPath(storagePath: "", publicPath: "", publicCollectionName: "")))
//
//
//
//
//    static let list: [NFTCollectionItem] = [
//        item
//    ]
//    static var previews: some View {
//        NavigationView {
//            NFTAddCollectionView()
//        }
//    }
// }
