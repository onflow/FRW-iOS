//
//  EVMEnableView.swift
//  FRW
//
//  Created by cat on 2024/2/26.
//

import SwiftUI

struct EVMEnableView: RouteableView {
    @StateObject
    var viewModel = EVMEnableViewModel()

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    viewModel.onSkip()
                } label: {
                    Text("not_now".localized)
                        .font(.inter(size: 14))
                        .foregroundStyle(
                            ThemeManager.shared.style == .light ? Color.Theme.Text
                                .black : Color.Theme.Text.black8
                        )
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background(
                            ThemeManager.shared.style == .light ? Color.Theme.Text.black3
                                .opacity(0.24) : Color.Theme.Text.black8.opacity(0.24)
                        )
                        .cornerRadius(24)
                }
                .transition(.opacity)
            }
            .padding(.horizontal, 24)

            Image("evm_big_planet")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("Enable the path")
                .font(.inter(size: 30, weight: .w700))
                .foregroundStyle(Color.Theme.Text.black8)
                .multilineTextAlignment(.center)
            HStack(spacing: 0) {
                Text("to ")
                    .font(.inter(size: 30, weight: .w700))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .multilineTextAlignment(.center)
                Text("evm_on_flow".localized)
                    .font(.inter(size: 30, weight: .w700))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.Theme.Accent.blue, Color.Theme.Accent.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text("enable_evm_tip".localized)
                .font(.inter(size: 14))
                .foregroundStyle(Color.Theme.Text.black8)
                .multilineTextAlignment(.center)
            Spacer()

            VPrimaryButton(
                model: ButtonStyle.evmEnable,
                state: viewModel.state,
                action: {
                    viewModel.onClickEnable()
                },
                title: "enable".localized
            )
            .frame(width: 160)

            Button {
                viewModel.onClickLearnMore()
            } label: {
                Text("Learn__more::message".localized)
                    .font(.inter(size: 16))
                    .foregroundStyle(Color.Theme.Text.black8)
            }
            .padding(.top)
            .padding(.bottom)
        }
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview {
    EVMEnableView()
}
