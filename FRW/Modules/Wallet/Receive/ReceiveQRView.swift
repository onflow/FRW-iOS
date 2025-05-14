//
//  ReceiveQRView.swift
//  FRW
//
//  Created by cat on 2024/2/26.
//

import QRCode
import SwiftUI

// MARK: - ReceiveQRView

struct ReceiveQRView: RouteableView {
    @StateObject
    var viewModel: ReceiveQRViewModel = .init()

    var title: String {
        "receiving_qr".localized
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: 1, height: 8)

            VStack(spacing: 8) {
                Text("current_chain".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black8)

                ReceiveQRView.SwitchText { isOn in
                    viewModel.onChangeChain(isEvm: isOn)
                }
            }
            .visibility(viewModel.hasEVM)

            qrCodeView
                .padding(.top, 32)

            Text(viewModel.name)
                .font(.inter(size: 18, weight: .w700))
                .foregroundStyle(Color.Theme.Text.black)
                .padding(.top, 16)

            Button {
                viewModel.onClickCopy()
            } label: {
                HStack {
                    Text(viewModel.address)
                        .font(.inter(size: 16))
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Theme.Text.black8)
                        .lineLimit(1)

                    Spacer()
                    Image("icon_copy")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.Theme.Text.black3)
                        .frame(width: 24, height: 24)
                }
                .frame(height: 48)
                .padding(.horizontal, 24)
                .background(Color.Theme.Background.grey)
                .cornerRadius(12)
            }
            .padding(.top, 8)

            shareButton
                .frame(height: 48)
                .padding(.top, 24)
                .padding(.bottom)

            if self.viewModel.isEVM {
                evmWarning
                    .padding(.horizontal, -38)
            }

            Spacer()
        }
        .padding(.horizontal, 54)
        .backgroundFill(.Theme.Background.silver)
        .applyRouteable(self)
        .tracedView(self)
    }

    var qrCodeView: some View {
        VStack(spacing: 0) {
            ZStack {
                QRCodeView(content: viewModel.address, eyeColor: (
                    viewModel.isEVM ?
                        Color.Theme.Accent.blue : Color.Theme.Accent.green
                ).toUIColor()!)
            }
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        currentNetwork == .mainnet ? Color.LL.Neutrals.background : currentNetwork
                            .color,
                        lineWidth: 5
                    )
                    .colorScheme(.light)
            )
            .aspectRatio(1, contentMode: .fit)
        }
        .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.75)
        .aspectRatio(1, contentMode: .fill)
    }

    var shareButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()

            let image = qrCodeView.snapshot()

            let itemSource = ShareActivityItemSource(
                shareText: viewModel.address,
                shareImage: image
            )

            let activityController = UIActivityViewController(
                activityItems: [image, viewModel.address, itemSource],
                applicationActivities: nil
            )
            activityController.isModalInPresentation = true
            UIApplication.shared.windows.first?.rootViewController?.presentedViewController?
                .present(
                    activityController,
                    animated: true,
                    completion: nil
                )

        } label: {
            Text("share_qr_code".localized)
                .font(.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black)
                .padding(.vertical, 15)
                .padding(.horizontal, 24)
                .background(.Theme.Background.grey)
                .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var evmWarning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("Warning")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .width(16)

            Text(.init("deposit_evm_warning"))
        }
        .font(Font.LL.body3).fontWeight(.regular)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .foregroundColor(Color.Theme.Accent.grey)
        .padding(16)
        .background(Color.Theme.Background.grey)
        .cornerRadius(16)
    }

    func backButtonAction() {
        Router.dismiss()
    }
}

// MARK: ReceiveQRView.SwitchText

extension ReceiveQRView {
    struct SwitchText: View {
        @State
        private var isOn = false
        var callback: ((Bool) -> Void)?

        var body: some View {
            ZStack {
                HStack(spacing: 0) {
                    HStack {
                        Image("icon_qr_flow")
                            .resizable()
                            .frame(width: 24, height: 24)
                        if !isOn {
                            Text("Cadence")
                                .font(.inter(size: 14, weight: .w600))
                                .foregroundStyle(Color.Theme.Text.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(!isOn ? .Theme.Background.silver : .clear)
                    .cornerRadius(24)

                    HStack {
                        Image("icon_qr_evm")
                            .resizable()
                            .frame(width: 24, height: 24)
                        if isOn {
                            Text("evm_on_flow".localized)
                                .font(.inter(size: 14, weight: .w600))
                                .foregroundStyle(Color.Theme.Text.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isOn ? .Theme.Background.silver : .clear)
                    .cornerRadius(24)
                }
                .padding(4)
            }
            .background(Color.black)
            .cornerRadius(24)
            .onTapGesture {
                withAnimation(Animation.linear(duration: 0.3)) {
                    isOn.toggle()
                    callback?(isOn)
                }
            }
        }
    }
}

#Preview("light") {
    ReceiveQRView()
        .preferredColorScheme(.light)
//    ReceiveQRView.SwitchText { isOne in
//
//    }
}

#Preview("dark") {
    ReceiveQRView()
        .preferredColorScheme(.dark)
}
