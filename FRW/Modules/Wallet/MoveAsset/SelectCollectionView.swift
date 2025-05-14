//
//  SelectCollectionView.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Kingfisher
import SwiftUI

struct SelectCollectionView: RouteableView {
    // MARK: Lifecycle

    init(viewModel: SelectCollectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        VStack {
            TitleWithClosedView(title: "select_nfts".localized) {
                viewModel.closeAction()
            }

            ScrollView {
                ForEach(0 ..< viewModel.list.count, id: \.self) { index in
                    card(item: viewModel.list[index])
                }
            }

//            Button {
//                viewModel.confirmAction()
//            } label: {
//                Text("next".localized)
//                    .font(.inter(size: 16))
//                    .foregroundStyle(Color.Theme.Text.black8)
//                    .frame(height: 48)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.Theme.Accent.green)
//                    .cornerRadius(16)
//            }
//            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 18)
        .mockPlaceholder(viewModel.isMock)
        .applyRouteable(self)
        .tracedView(self)
    }

    @ViewBuilder
    func card(item: CollectionMask) -> some View {
        Button {
            viewModel.select(item: item)
        } label: {
            HStack(spacing: 16) {
                KFImage.url(item.maskLogo)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(item.maskName)
                            .font(.inter(size: 14))
                            .foregroundStyle(Color.Theme.Text.black)
                            .padding(.trailing, 4)

                        viewModel.logo()
                            .resizable()
                            .frame(width: 12, height: 12)
                    }

                    Text("\(item.maskCount) NFTs")
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black8)
                }

                Spacer()

                Image("check_fill_1")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(.trailing, 16)
                    .visibility(viewModel.isSelected(item) ? .visible : .invisible)
            }
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .background(Color.Theme.Background.silver)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Private

    @StateObject
    private var viewModel: SelectCollectionViewModel
}

#Preview {
    SelectCollectionView(viewModel: SelectCollectionViewModel(
        selectedItem: nil,
        list: nil,
        callback: { _ in
        }
    ))
}
