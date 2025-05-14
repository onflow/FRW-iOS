//
//  TokenBalanceListView.swift
//  FRW
//
//  Created by Hao Fu on 24/2/2025.
//

import Flow
import Kingfisher
import SwiftUI

// MARK: - TokenBalanceListView

struct TokenBalanceListView: RouteableView {
    // MARK: Lifecycle

    init(vm: TokenBalanceListViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    @StateObject
    var vm: TokenBalanceListViewModel

    var title: String {
        "swap_select_token".localized
    }

    var body: some View {
        listView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(vm)
            .disabled(vm.isRequesting)
            .applyRouteable(self)
            .tracedView(self)
    }

    var listView: some View {
        List {
            ForEach(vm.tokenList) { token in
                Button {
                    vm.selectTokenAction(token)
                } label: {
                    TokenItemCell(token: token)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .buttonStyle(ScaleButtonStyle())
            .environmentObject(vm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .listStyle(.plain)
        .background(Color.LL.background)
        .mockPlaceholder(vm.isRequesting)
    }

    func backButtonAction() {
        Router.dismiss()
    }
}

private let TokenIconWidth: CGFloat = 40
private let TokenCellHeight: CGFloat = 64

// MARK: TokenBalanceListView.TokenItemCell

extension TokenBalanceListView {
    struct TokenItemCell: View {
        let token: TokenModel

        @EnvironmentObject
        var vm: TokenBalanceListViewModel

        var body: some View {
            HStack {
                KFImage.url(token.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: TokenIconWidth, height: TokenIconWidth)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(token.name)
                        .foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .semibold))

                    Text(token.symbol?.uppercased() ?? "")
                        .foregroundColor(.LL.Neutrals.neutrals9)
                        .font(.inter(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let balance = token.readableBalanceStr {
                    Text(balance)
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 12, weight: .medium))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: TokenCellHeight)
            .background {
                Color.Theme.BG.bg3.cornerRadius(16)
            }
        }
    }
}

#Preview {
    let vm = TokenBalanceListViewModel(address: Flow.Address(hex: "0xa71fbead537a2416"))
    TokenBalanceListView(vm: vm)
}
