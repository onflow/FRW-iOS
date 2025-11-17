//
//  EmptyWalletView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 25/12/21.
//

import Kingfisher
import SceneKit
import SPConfetti
import SwiftUI
import SwiftUIX

struct EmptyWalletView: View {
    // MARK: Internal

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Group {
                topContent

                middleContent
            }
            .padding(.leading, 32)

            Spacer()

            bottomContent
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Theme.Background.grey)
        .onAppear {
            vm.tryToRestoreAccountWhenFirstLaunch()
        }
    }

    var bottomContent: some View {
        VStack(spacing: 8) {
            Button {
                vm.createNewAccountAction()
            } label: {
                Text("create_a_new_account".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(.LL.background)
                    .frame(height: 54)
                    .frame(maxWidth: .infinity)
                    .background(Color.LL.Primary.salmonPrimary)
                    .contentShape(Rectangle())
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.12), x: 0, y: 4, blur: 24)
            }

            Button {
                vm.loginAccountAction()
            } label: {
                Text("i_have_an_account".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(.LL.text)
                    .frame(height: 58)
                    .frame(maxWidth: .infinity)
                    .background(.clear)
                    .contentShape(Rectangle())
                    .cornerRadius(29)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.LL.text, lineWidth: 1.5)
                    )
            }
            .padding(.bottom, 16)

            Text(disclaimer)
                .font(.inter(size: 14))
                .foregroundStyle(Color.LL.text)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
    }

    var recentListContent: some View {
        VStack(alignment: .leading, spacing: 0) {
          Text("\(vm.profiles.count) " + "registerd_accounts".localized)
                .font(.inter(size: 16, weight: .bold))
                .foregroundColor(Color.Theme.Text.black8)
                .padding(.top, 4)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                  ForEach(vm.profiles, id: \.uid) { placeholder in
                        Button {
                          vm.switchAccount(placeholder)
                        } label: {
                            createRecentLoginCell(placeholder)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .mockPlaceholder(vm.isLoading)

            ZStack(alignment: .center) {
                Divider().foregroundStyle(Color.Theme.Line.stroke)

                Text("or".localized)
                    .frame(width: 32, height: 32)
                    .background(Color.Theme.Background.grey)
                    .foregroundStyle(Color.Theme.Text.text4)
            }
            .padding(.bottom, 8)
            .padding(.trailing, 37)
            .maxWidth(.infinity)
        }
        .maxWidth(.infinity)
    }

  func createRecentLoginCell(_ placeholder: ProfileModel) -> some View {
        HStack(spacing: 16) {
          KFImage.url(URL(string: placeholder.avatar?.convertedAvatarString() ?? ""))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .cornerRadius(18)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(placeholder.username ?? "")")
                    .lineLimit(1)
                    .font(.inter(size: 12, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black8)

                Text("\(placeholder.accountDes)")
                    .lineLimit(1)
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundStyle(Color.Theme.Text.black3)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }

    // MARK: Private

    @StateObject
    private var vm = EmptyWalletViewModel()

    @State
    private var isSettingNotificationFirst = true

    @ViewBuilder
    private var middleContent: some View {
      if vm.profiles.isEmpty {
            noAccountsMiddleContent
        } else {
            recentListContent
        }
    }

    @ViewBuilder
    private var noAccountsMiddleContent: some View {
        VStack(alignment: .leading) {
            Text("#onFlow.")
                .font(.Ukraine(size: 48, weight: .thin))
                .fontWeight(.thin)
                .foregroundColor(Color("text.white.9"))
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
                .background(Color.Theme.Accent.green)
                .cornerRadius(50)

            Spacer()

            Text("welcome_message".localized)
                .font(.inter(size: 18, weight: .light))
                .foregroundColor(Color.LL.text)
                .frame(alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 32)
        .padding(.bottom, 42)
    }

    @ViewBuilder
    private var horizontalGradient: some View {
        ZStack {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black.opacity(0), location: 0.00),
                    Gradient.Stop(color: Color.Theme.Accent.green.opacity(0.5), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0, y: 0.5),
                endPoint: UnitPoint(x: 1, y: 0.5)
            )

            HStack {
                Image("lilico-app-icon")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text("app_name_full".localized)
                    .font(.inter(size: 18, weight: .semibold))
                    .foregroundColor(Color.LL.text)
                Spacer()
            }
        }
        .frame(height: 91)
    }

    @ViewBuilder
    private var verticalGradient: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: .black.opacity(0), location: 0.00),
                Gradient.Stop(color: Color.Theme.Accent.green, location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 1)
        )
        .frame(width: 79, height: 166)
    }

    @ViewBuilder
    private var gradients: some View {
        ZStack(alignment: .topTrailing) {
            verticalGradient
            horizontalGradient
        }
    }

    @ViewBuilder
    private var letsGetStarted: some View {
        Text("lets_get_started".localized)
            .lineLimit(2)
            .font(.Ukraine(size: 48, weight: .light))
            .padding(.bottom, 32)
            .padding(.top, -40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var topContent: some View {
        VStack(spacing: 0) {
            gradients
            letsGetStarted
        }
        .frame(height: 270)
    }

    private var disclaimer: AttributedString {
        let localizedMarkdown = NSLocalizedString(
            "disclaimer",
            comment: "By using Flow Wallet you agree to the [Terms of Service](https://wallet.flow.com/terms-of-service) and [Privacy Policy](https://wallet.flow.com/privacy-policy)."
        )

        // Convert the markdown string to an AttributedString
        var attributedString: AttributedString
        do {
            attributedString = try AttributedString(markdown: localizedMarkdown)
        } catch {
            attributedString = AttributedString(localizedMarkdown)
        }

        for run in attributedString.runs {
            if run.link != nil {
                attributedString[run.range].foregroundColor = .LL.text
                attributedString[run.range].underlineStyle = .single
            }
        }

        return attributedString
    }
}

#Preview("Dark") {
    ThemeManager.shared.style = .dark
    return EmptyWalletView()
        .preferredColorScheme(.dark)
}

#Preview {
    EmptyWalletView()
}
