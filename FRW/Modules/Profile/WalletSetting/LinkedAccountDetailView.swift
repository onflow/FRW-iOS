//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import SwiftUI
import Kingfisher

struct LinkedAccountDetailView: RouteableView {
    @StateObject var viewModel: LinkedAccountDetailViewModel
    
    init(account: FlowWalletKit.ChildAccount) {
        _viewModel = StateObject(wrappedValue: LinkedAccountDetailViewModel(childAccount: account))
    }

    var title: String {
        "linked_account".localized
    }
    
    var body: some View {
        ScrollView {
            VStack {
                AccountInfoCard(account: viewModel.childAccount) {
                    //TODO: Edit
                }
                
                LineView()
                    .padding(.top, 36)
                    .padding(.bottom, 16)
                
                accessibleView
                
                
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .backgroundFill(Color.Theme.Background.white)
            
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    @ViewBuilder
    var accessibleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("accessible_cap".localized)
                    .foregroundColor(Color.Theme.Text.black8)
                    .font(.inter(size: 16, weight: .w500))

                Spacer()

                HStack(spacing: 6) {
//                    Image(vm.showEmptyCollection ? "icon-empty-mark" : "icon-right-mark")
//                        .resizable()
//                        .frame(width: 11, height: 11)
                    Text("view_empty".localized)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.text4)
                    Toggle(isOn: $viewModel.showEmptyCollection) {}
                        .tint(.LL.Primary.salmonPrimary)
                        .onChange(of: viewModel.showEmptyCollection) { _ in
                            viewModel.switchEmptyCollection()
                        }
                        .labelsHidden()
                        .contentShape(Rectangle())
                    Spacer()
                        .frame(width: 2)
                }
            }
            .padding(.bottom, 8)
            //TODO: #six #multi-account  segment & cell
            LLSegmenControl(titles: ["collections".localized, "coins_cap".localized]) { idx in
                viewModel.switchTab(index: idx)
            }
            if viewModel.accessibleItems.isEmpty, !viewModel.isLoading {
                emptyAccessibleView
            }
            VStack {
                ForEach(viewModel.accessibleItems.indices, id: \.self) { idx in
                    AccessibleItemView(item: viewModel.accessibleItems[idx]) { item in
                        if let collectionInfo = item as? NFTCollection,
                           let pathId = collectionInfo.collection.path?.storagePathId(),
                           !collectionInfo.isEmpty
                        {
                            let addr = viewModel.childAccount.infoAddress
                            //TODO: #multi-account
    //                        Router.route(to: RouteMap.NFT.collectionDetail(
    //                            addr,
    //                            pathId,
    //                            viewModel.childAccount
    //                        ))
                        }
                    }
                    if idx != viewModel.accessibleItems.count - 1 {
                        LineView()
                    }
                }
            }
            .cardStyle()
            .mockPlaceholder(viewModel.isLoading)
        }
    }
    
    var emptyAccessibleView: some View {
        HStack {
            Text(viewModel.accessibleEmptyTitle)
                .font(Font.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.LL.Neutrals.text4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 18)
        .background(.LL.Neutrals.neutrals6)
        .cornerRadius(16, style: .continuous)
    }
}

struct AccessibleItemView: View {
    var item: ChildAccountAccessible
    var onClick: ((_ item: ChildAccountAccessible) -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            KFImage.url(URL(string: item.img))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 24)
                .cornerRadius(12, style: .continuous)

            Text(item.title)
                .foregroundColor(Color.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .semibold))
                .lineLimit(2)

            Spacer()

            Text(item.subtitle)
                .foregroundColor(Color.LL.Neutrals.text3)
                .font(.inter(size: 12))
            Image("icon-black-right-arrow")
                .renderingMode(.template)
                .foregroundColor(Color.LL.Neutrals.text2)
                .visibility(item.isShowNext ? .visible : .gone)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(Color.LL.background)
        .cornerRadius(16, style: .circular)
        .onTapGesture {
            if let onClick = onClick {
                onClick(item)
            }
        }
    }
}
#Preview {}
