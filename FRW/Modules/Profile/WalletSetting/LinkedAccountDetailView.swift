//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import Kingfisher
import SwiftUI

struct LinkedAccountDetailView: RouteableView {
    @StateObject var viewModel: LinkedAccountDetailViewModel
    @State private var selectedIndex: Int = 0

    init(account: FlowWalletKit.ChildAccount) {
        _viewModel = StateObject(wrappedValue: LinkedAccountDetailViewModel(childAccount: account))
    }

    var title: String {
        "linked_account".localized
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                AccountInfoCard(account: viewModel.childAccount) {
                    // TODO: Edit
                }

                LineView()
                    .padding(.top, 36)
                    .padding(.bottom, 16)

                accessibleView
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.unlinkConfirmAction()
            } label: {
                Text("unlink_account".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.Theme.Accent.red)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 18)
        }
        .backgroundFill(Color.Theme.Background.white)
        .clipped()
        .applyRouteable(self)
        .tracedView(self)
        .halfSheet(
            showSheet: $viewModel.isPresent,
            autoResizing: true,
            backgroundColor: Color.LL.Neutrals.background
        ) {
            UnlinkConfirmView(childAccount: viewModel.childAccount) {
                viewModel.doUnlinkAction()
            }
        }
    }

    @ViewBuilder
    var accessibleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("accessible_cap".localized)
                    .foregroundColor(Color.Theme.Text.black8)
                    .font(.inter(size: 16, weight: .w500))

                Spacer()

                HStack(spacing: 6) {

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
            .padding(.bottom, 24)
            
            SegmentedControl(
                tabs: [
                    .text("collections".localized),
                    .text("coins_cap".localized)
                ],
                selectedIndex: $selectedIndex,
                height: 32,
                font: .inter(size: 12, weight: .w700),
                activeTint: .Summer.Text.primary,
                inActiveTint: .Summer.Text.primary
            ) { size in
                CapsuleIndicator(color: .Summer.dark10, size: size)
            }
            .onChange(of: selectedIndex) { index in
                viewModel.switchTab(index: index)
            }
            .cardStyle(padding: 0)
            .padding(.bottom, 18)
            
            if viewModel.accessibleItems.isEmpty, !viewModel.isLoading {
                emptyAccessibleView
            }
            VStack(spacing: 0) {
                ForEach(viewModel.accessibleItems.indices, id: \.self) { idx in
                    AccessibleItemView(item: viewModel.accessibleItems[idx]) { item in
                        if let collectionInfo = item as? NFTCollection,
                           let pathId = collectionInfo.collection.path?.storagePathId(),
                           !collectionInfo.isEmpty
                        {
                            let addr = viewModel.childAccount.infoAddress
                            // TODO: #multi-account
//                            Router.route(to: RouteMap.NFT.collectionDetail(
//                                addr,
//                                pathId,
//                                viewModel.childAccount
//                            ))
                        }
                    }
                    if idx != viewModel.accessibleItems.count - 1 {
                        LineView()
                    }
                }
            }
            .cardStyle(padding: EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
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
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            Text(item.title)
                .foregroundColor(Color.Summer.Text.primary)
                .truncationMode(.middle)
                .font(.inter(size: 14))
                .lineLimit(1)

            Spacer(minLength: 14)

            Text(item.subtitle)
                .foregroundColor(Color.Summer.Text.secondary)
                .font(.inter(size: 12))
            
            Image("device_arrow_right")
                .resizable()
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .onTapGesture {
            if let onClick = onClick {
                onClick(item)
            }
        }
    }
}

