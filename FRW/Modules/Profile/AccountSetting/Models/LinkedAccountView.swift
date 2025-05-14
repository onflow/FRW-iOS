//
//  LinkedAccountView.swift
//  FlowCore
//
//  Created by cat on 2023/9/11.
//

import Combine
import Kingfisher
import SwiftUI

// MARK: - LinkedAccountView

struct LinkedAccountView: RouteableView {
    // MARK: Internal

    var title: String {
        "linked_account".localized.capitalized
    }

    var body: some View {
        ZStack {
            if cm.sortedChildAccounts.isEmpty && !cm.isLoading {
                emptyView
            } else {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(cm.sortedChildAccounts, id: \.addr) { childAccount in
                            Button {
                                Router.route(to: RouteMap.Profile.accountDetail(childAccount))
                            } label: {
                                childAccountCell(childAccount)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .mockPlaceholder(cm.isLoading)
                }
                .padding(.top, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
        .onAppear(perform: {
            cm.refresh()
        })
    }

    func childAccountCell(_ childAccount: ChildAccount) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 18) {
                KFImage.url(URL(string: childAccount.icon))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .cornerRadius(18)

                VStack(alignment: .leading, spacing: 5) {
                    Text(childAccount.aName)
                        .foregroundColor(Color.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .semibold))

                    Text(childAccount.addr ?? "")
                        .foregroundColor(Color.LL.Neutrals.text3)
                        .font(.inter(size: 12))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                withAnimation(.none) {
                    cm.togglePinStatus(childAccount)
                }
            } label: {
                Image("icon-pin")
                    .renderingMode(.template)
                    .foregroundColor(
                        childAccount.isPinned ? Color.LL.Primary
                            .salmonPrimary : Color(hex: "#00B881")
                    )
                    .frame(width: 32, height: 32)
                    .background {
                        if childAccount.isPinned {
                            LinearGradient(
                                colors: [Color.clear, Color(hex: "#00B881").opacity(0.15)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                            .cornerRadius([.topTrailing, .bottomLeading], 16)
                        } else {
                            Color.clear
                        }
                    }
                    .contentShape(Rectangle())
            }
        }
        .padding(.leading, 20)
        .frame(height: 66)
        .background(Color.LL.background)
        .contentShape(Rectangle())
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), x: 0, y: 12, blur: 16)
    }

    // MARK: Private

    @StateObject
    private var cm = ChildAccountManager.shared
}

extension LinkedAccountView {
    var emptyView: some View {
        VStack {
            Image("empty_linked_account")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 148)

            Text("No Linked Account")
                .font(Font.inter(size: 18))
                .foregroundStyle(
                    Color(UIColor(hex: "#8C9BAB"))
                )
        }
    }
}
