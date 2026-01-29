//
//  AccountSwitchView.swift
//  Flow Wallet
//
//  Created by Selina on 13/6/2023.
//

import Combine
import Kingfisher
import SwiftUI

// MARK: - AccountSwitchView

struct AccountSwitchView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 20) {
            titleView
            contentView
            bottomView
        }
        .padding(.horizontal, 18)
//        .backgroundFill(Color.Brain.Core.cards)
    }

    var titleView: some View {
        Text("accounts".localized)
            .font(.inter(size: 18, weight: .bold))
            .foregroundColor(Color.Brain.Text.primary)
    }

    var bottomView: some View {
        VStack(spacing: 0) {
            Button {
                if currentNetwork != .mainnet {
                    showAlert = true
                } else {
                    Router.dismiss {
                        vm.createNewAccountAction()
                    }
                }

            } label: {
                HStack(spacing: 8) {
                    Image("user-circle-plus")
                        .renderingMode(.template)
                        .foregroundColor(Color.Brain.Core.icons)
                        .frame(width: 24, height: 24)

                    Text("create_new_account".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundColor(Color.Brain.Text.primary)

                    Spacer()
                }
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .alert("wrong_network_title".localized, isPresented: $showAlert) {
                Button("switch_to_mainnet".localized) {
                    WalletManager.shared.changeNetwork(.mainnet)
                    Router.dismiss {
                        vm.createNewAccountAction()
                    }
                }
                Button("action_cancel".localized, role: .cancel) {}
            } message: {
                Text("wrong_network_des".localized)
            }
            .buttonStyle(ScaleButtonStyle())
            
          Divider()
            .background(Color.Brain.Light.lines10)
          
            Button {
                Router.dismiss {
                    vm.loginAccountAction()
                }
            } label: {
                HStack(spacing: 8) {
                    Image("user-circle-recover")
                        .renderingMode(.template)
                        .foregroundColor(Color.Brain.Core.icons)
                        .frame(width: 24, height: 24)

                    Text("add_existing_account".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundColor(Color.Brain.Text.primary)

                    Spacer()
                }
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 18)
        .background(Color.Brain.Light.lines10)
        .cornerRadius(16)
        .padding(.bottom, 20)
    }

    var contentView: some View {
        GeometryReader { geometry in
            ScrollViewOffset { offset in
                self.offset = offset
            } content: {
                LazyVStack(spacing: 20) {
                  ForEach(0..<vm.profiles.count, id: \.self) { index in
                      let placeholder = vm.profiles[index]
                        Button {
                          vm.selectedProfile = placeholder
                            if currentNetwork != .mainnet {
                                showSwitchUserAlert = true
                            } else {
                                Router.dismiss {
                                  vm.switchAccount(placeholder)
                                }
                            }

                        } label: {
                            createAccountCell(placeholder)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .alert("wrong_network_title".localized, isPresented: $showSwitchUserAlert) {
                            Button("switch_to_mainnet".localized) {
                                WalletManager.shared.changeNetwork(.mainnet)
                              if let profile = vm.selectedProfile {
                                    Router.dismiss {
                                      vm.switchAccount(profile)
                                    }
                                }
                            }
                            Button("action_cancel".localized, role: .cancel) {}
                        } message: {
                            Text("wrong_network_des".localized)
                        }
                      if index < vm.profiles.count - 1 {
                        Divider()
                          .background(Color.Brain.Light.lines.opacity(0.15))
                      }
                    }
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                    .onPreferenceChange(SizePreferenceKey.self, perform: { value in
                        self.contentHeight = value.height
                    })
                }
            }
            .overlay(alignment: .bottom) {
                moreView
                    .opacity(offset < 10 ? max(0, 1 - (-offset / 50.0)) : 1)
                    .visibility(self.contentHeight > geometry.size.height ? .visible : .gone)
            }
        }
        .frame(minHeight: CGFloat(84 * min(5, vm.profiles.count)))
    }

    var moreView: some View {
        Button {
            
        } label: {
            HStack {
                Text("view_more".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Accent.grey)
                Image("icon_arrow_double_down")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(.Theme.Background.grey)
            .cornerRadius(16)
        }
    }

  func createAccountCell(_ placeholder: ProfileModel) -> some View {
        HStack(alignment: .top, spacing: 16) {
          KFImage.url(URL(string: placeholder.avatar?.convertedAvatarString() ?? ""))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .cornerRadius(8)

          HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(placeholder.username ?? "")")
                    .lineLimit(1)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.Brain.Text.primary)
              
              if !placeholder.amountDes.isEmpty {
                Text("\(placeholder.amountDes)")
                    .lineLimit(1)
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundColor(Color.Brain.Text.secondary)
              }
              
              HStack(spacing: 2) {
                Text("\(placeholder.countDes)")
                    .lineLimit(1)
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundColor(Color.Brain.Text.secondary)
                let flattenedAccounts = placeholder.accounts.flatMap({ $0 }).filter{ !$0.isHidden}
                if !flattenedAccounts.isEmpty {
                  ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                      ForEach(flattenedAccounts.indices, id: \.self) { index in
                        let account = flattenedAccounts[index]
                        WalletAvatarView(
                          emoji: account.user?.emoji,
                          avatar: account.childInfo?.avatar, // WalletUser does not have avatar,
                          size: .small,
                          showBorder: false
                        )
                      }
                    }
                  }
                }
              }
            }

            Spacer()
            Image("check_circle_border")
              .resizable()
              .renderingMode(.template)
              .foregroundColor( placeholder.uid == UserManager.shared
                .activatedUID ? Color.Brain.Primary.main : Color.Brain.Core.icons)
              .frame(width: 24, height: 24)
          }
        }
        .frame(height: 56)
    }

    // MARK: Private

    @StateObject
    private var vm = AccountSwitchViewModel()
    @State
    private var showAlert = false
    @State
    private var showSwitchUserAlert = false

    @State
    private var offset: CGFloat = 0
    @State
    private var contentHeight: CGFloat = 0
}

// MARK: - ScrollViewOffset

struct ScrollViewOffset<Content: View>: View {
    // MARK: Lifecycle

    init(
        onOffsetChange: @escaping (CGFloat) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onOffsetChange = onOffsetChange
        self.content = content
    }

    // MARK: Internal

    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            offsetReader
            content()
                .padding(.top, -8)
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self, perform: onOffsetChange)
    }

    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("frameLayer")).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - SizePreferenceKey

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - OffsetPreferenceKey

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value _: inout CGFloat, nextValue _: () -> CGFloat) {}
}
