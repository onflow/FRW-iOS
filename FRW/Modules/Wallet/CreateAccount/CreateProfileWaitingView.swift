//
//  CreateProfileWaitingView.swift
//  FRW
//
//  Created by cat on 2024/6/5.
//

import Lottie
import SwiftUI
import SwiftUIPager
import SwiftUIX

// MARK: - CreateProfileWaitingView

struct CreateProfileWaitingView: RouteableView {
    // MARK: Lifecycle

    init(_ viewModel: CreateProfileWaitingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    @StateObject
    var viewModel: CreateProfileWaitingViewModel

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var enableSwipeBackGesture: Bool {
        false
    }

    var body: some View {
        VStack(alignment: .center) {
            flowLabel

            Spacer()

            creatingAccount
                .padding(.bottom, 28)

            lottieView

            secureByDesign
                .padding(.bottom, 18)

            hardwareGradeSecurity
                .padding(.bottom, 64)

            allow1to2Minutes

            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.Theme.Background.grey)
        .applyRouteable(self)
        .tracedView(self)
        .onChange(of: viewModel.createFinished) { finished in
            if finished {
                Router.route(to: RouteMap.RestoreLogin.createProfileSuccess(viewModel))
            }
        }
    }
}

extension CreateProfileWaitingView {
    @ViewBuilder
    private var flowLabel: some View {
        HStack {
            Image("lilico-app-icon")
                .resizable()
                .frame(width: 32, height: 32)
            Text("app_name_full".localized)
                .font(.inter(size: 18, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black)
            Spacer()
        }
    }

    @ViewBuilder
    private var creatingAccount: some View {
        Text("creating_account".localized)
            .font(.Ukraine(size: 32, weight: .light))
            .multilineTextAlignment(.center)
            .foregroundColor(Color.LL.text)
    }

    private var lottieView: some View {
        let lottieView = LottieAnimationView(name: "CreatingAccount", bundle: .main)
        lottieView.play(toProgress: .infinity, loopMode: .loop)

        return FlowLottieView(lottieView: lottieView)
            .frame(width: 240, height: 240)
    }

    @ViewBuilder
    private var secureByDesign: some View {
        Text("secure_by_design".localized)
            .font(.inter(size: 14, weight: .semibold))
            .foregroundColor(Color.LL.text)
    }

    @ViewBuilder
    private var hardwareGradeSecurity: some View {
        Text("hardware_grade_security".localized)
            .font(.inter(size: 16))
            .foregroundColor(Color.LL.text)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var allow1to2Minutes: some View {
        Text("allow_1_2_minutes".localized)
            .font(.inter(size: 14))
            .foregroundStyle(Color.Theme.Accent.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.Theme.Accent.green.opacity(0.12))
            .cornerRadius(8)
    }
}

#Preview {
    CreateProfileWaitingView(CreateProfileWaitingViewModel(txId: "", callback: { _, _ in }))
}
