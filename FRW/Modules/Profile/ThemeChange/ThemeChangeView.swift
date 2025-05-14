//
//  ThemeChangeView.swift
//  Flow Wallet
//
//  Created by Selina on 18/5/2022.
//

import Foundation
import SwiftUI

// MARK: - ThemeChangeView

struct ThemeChangeView: RouteableView {
    // MARK: Lifecycle

    init() {
        let value = UserDefaults.standard.string(forKey: "WalletCardBackrgound") ?? "fade:0"
        let card = CardBackground(value: value)
        cardColor = card.color
    }

    // MARK: Internal

    var title: String {
        "theme".localized
    }

    var body: some View {
        ZStack {
            ScrollView {
                Section {
                    Button {
                        Router.route(to: RouteMap.Profile.wallpaper)
                    } label: {
                        HStack {
                            Text("Wallpaper".localized)
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundColor(.LL.Neutrals.text)

                            Spacer()

                            CardBackground(value: walletCardBackrgound)
                                .renderView()
                                .frame(width: 32, height: 32)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 64)
                        .background(.LL.bgForIcon)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                Section {
                    VStack {
                        themeItemView.padding(.vertical, 24)
                        BaseDivider()
                        autoItemView
                            .hoverEffect(SwiftUI.HoverEffect.lift)
                    }
                    //            .roundedBg(cornerRadius: 16, fillColor: .LL.bgForIcon)
                    .background(.LL.bgForIcon)
                    .cornerRadius(16)
                    .frame(maxHeight: .infinity, alignment: .top)
                } header: {
                    Text("theme".localized)
                        .font(.LL.body)
                        .foregroundColor(.LL.Neutrals.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .backgroundFill(.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @StateObject
    private var vm = ThemeChangeViewModel()

    @AppStorage("WalletCardBackrgound")
    private var walletCardBackrgound: String = "fade:0"

    @State
    private var cardColor: Color
}

// MARK: - Previews_ThemeChangeView_Previews

struct Previews_ThemeChangeView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeChangeView()
    }
}

extension ThemeChangeView {
    var themeItemView: some View {
        HStack(spacing: 0) {
            ThemePreviewItemView(
                imageName: "preview-theme-light",
                title: "light".localized,
                isSelected: $vm.state.isLight
            ) {
                vm.trigger(.change(.light))
            }

            ThemePreviewItemView(
                imageName: "preview-theme-dark",
                title: "dark".localized,
                isSelected: $vm.state.isDark
            ) {
                vm.trigger(.change(.dark))
            }
        }
    }

    var autoItemView: some View {
        VStack {
            Toggle(isOn: $vm.state.isAuto) {
                HStack(spacing: 8) {
                    Image(systemName: .sun).font(.system(size: 25))
                        .foregroundColor(.LL.Secondary.mango4)
                    Text("auto".localized).foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 16, weight: .medium))
                }
            }
            .tint(.Flow.accessory)
            .onChange(of: vm.state.isAuto) { value in
                if value == true {
                    vm.trigger(.change(nil))
                } else {
                    if ThemeManager.shared.style == nil {
                        vm.trigger(.change(.light))
                    } else {
                        vm.trigger(.change(ThemeManager.shared.style))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }
}

// MARK: - ThemeChangeView.ThemePreviewItemView

extension ThemeChangeView {
    struct ThemePreviewItemView: View {
        let imageName: String
        let title: String
        @Binding
        var isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button {
                action()
            } label: {
                VStack(spacing: 0) {
                    Image(imageName).padding(.bottom, 16).aspectRatio(contentMode: .fit)
                    Text(title).foregroundColor(.LL.Neutrals.text).font(.inter(
                        size: 16,
                        weight: .medium
                    )).padding(.bottom, 9)
                    if isSelected {
                        Image(systemName: .checkmarkSelected).foregroundColor(.Flow.accessory)
                    } else {
                        Image(systemName: .checkmarkUnselected)
                            .foregroundColor(.LL.Neutrals.neutrals1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - ThemeChangeView.Cell

extension ThemeChangeView {
    struct Cell<Content>: View where Content: View {
        // MARK: Lifecycle

        init(
            isSelected: Bool,
            title: String,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.isSelected = isSelected
            self.title = title
            self.content = content()
        }

        // MARK: Internal

        let isSelected: Bool
        let title: String
        let content: Content

        var body: some View {
            HStack {
                Image(systemName: isSelected ? .checkmarkSelected : .checkmarkUnselected)
                    .foregroundColor(isSelected ? .Flow.accessory : .LL.Neutrals.neutrals1)
                Text(title)
                    .font(.inter())
                    .foregroundColor(.LL.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                content
            }
            .frame(height: 64)
            .padding(.horizontal, 16)
        }
    }
}
