//
//  NFTCollectionEnableView.swift
//  Flow Wallet
//
//  Created by cat on 2022/6/27.
//

import Kingfisher
import SwiftUI

extension NFTAddCollectionView {
    struct NFTCollectionEnableView: View {
        @EnvironmentObject var vm: AddCollectionViewModel

        var item: NFTCollectionItem

        @State private var showButton = true
        @State private var offset: CGFloat = 0
        @State private var topOpacity: CGFloat = 0.72

        var buttonState: VPrimaryButtonState {
            if vm.isAddingCollection {
                return .loading
            }
            return item.status == .own ? .disabled : .enabled
        }

        var body: some View {
            VStack(spacing: 0) {
                SheetHeaderView(title: "confirmation".localized) {
                    vm.isConfirmSheetPresented = false
                }

                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                KFImage
                                    .url(item.collection.logoURL)
                                    .placeholder {
                                        Image("placeholder")
                                            .resizable()
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)

                                HStack(alignment: .center, spacing: 6) {
                                    Text(item.collection.name ?? "")
                                        .font(.LL.largeTitle3)
                                        .fontWeight(.w700)
                                        .foregroundColor(.LL.Neutrals.text)
                                    Image("Flow")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                }

                                Text(item.collection.description ?? "")
                                    .font(.LL.body, weight: .w400)
                                    .foregroundColor(.LL.Neutrals.neutrals7)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack {
                                Text(item.processName())
                                    .font(Font.inter(size: 12, weight: .w600))
                                    .foregroundColor(.LL.Primary.salmonPrimary)
                                    .frame(height: 24)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 2)
                                    .background(Color.LL.Primary.salmon5)
                                    .cornerRadius(24)
                                    .opacity(item.processName().isEmpty ? 0 : 1)
                                    .animation(.easeInOut, value: item.processName())
                            }
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: (screenWidth - 38) / 1.4)
                    .background(
                        ZStack {
                            HStack {
                                Spacer()
                                KFImage
                                    .url(item.collection.bannerURL)
                                    .placeholder {
                                        Image("placeholder")
                                            .resizable()
                                    }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: (screenWidth - 38) / 1.4,
                                           height: (screenWidth - 38) / 1.4)
                                    .padding(-10)
                            }
                            .blur(radius: 6)
                            LinearGradient(colors:
                                [
                                    .LL.Shades.front,
                                    .LL.Shades.front,
                                    .LL.Shades.front.opacity(0.88),
                                    .LL.Shades.front.opacity(0.32),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing)
                        }
                    )
                    .cornerRadius(16)
                    .padding(.top, 22)

                    Spacer()

                    if item.status == .idle {
                        VPrimaryButton(model: ButtonStyle.primary,
                                       state: buttonState,
                                       action: {
                                           vm.addCollectionAction(item: item)
                                       }, title: buttonState == .loading ? "working_on_it".localized : "enable_collection".localized)
                            .padding(.bottom)
                    }
                }
                .padding(.horizontal, 18)
            }
            .backgroundFill(Color.LL.Neutrals.background)
        }
    }
}

// struct NFTCollectionEnableView_Previews: PreviewProvider {
//    static let item = NFTCollectionItem(collection: NFTCollectionInfo(logo: "https://raw.githubusercontent.com/Outblock/assets/main/nft/nyatheesovo/ovologo.jpeg", name: "OVO", contractName: "", address: ContractAddress(mainnet: "", testnet: ""), secureCadenceCompatible: SecureCadenceCompatible(mainnet: true, testnet: true), banner: nil, officialWebsite: nil, marketplace: nil, description: "hhhhhhhh", path: ContractPath(storagePath: "", publicPath: "", publicCollectionName: "")))
//
//    static var previews: some View {
//        NFTAddCollectionView.NFTCollectionEnableView(item: item, isPresented: .constant(true))
//
//    }
// }
