//
//  RequestSecureView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 6/1/22.
//

import SwiftUI

extension RequestSecureView {
    struct ViewState {
        var biometric: Biometric = .none
    }

    enum Action {
        case faceID
        case pin
    }
}

// MARK: - RequestSecureView

struct RequestSecureView: RouteableView {
    enum Biometric {
        case none
        case faceId
        case touchId
    }

    @StateObject
    var viewModel = RequestSecureViewModel()

    var model: VPrimaryButtonModel = {
        var model = ButtonStyle.border
        model.colors.border = .init(
            enabled: Color.LL.outline,
            pressed: Color.LL.outline,
            loading: Color.LL.outline,
            disabled: Color.LL.outline
        )
        model.layout.height = 64
        return model
    }()

    var pinModel: VPrimaryButtonModel = {
        var model = ButtonStyle.primary
        model.layout.height = 64
        return model
    }()

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(alignment: .leading) {
                Text("add_extra".localized)
                    .bold()
                    .font(.LL.largeTitle)

                HStack {
                    Text("protection".localized)
                        .bold()
                        .foregroundColor(Color.LL.orange)

                    Text("to".localized)
                        .bold()
                        .foregroundColor(Color.LL.text)
                }
                .font(.LL.largeTitle)

                Text("your_wallet".localized)
                    .bold()
                    .font(.LL.largeTitle)

                Text("extra_protection_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 30)

            Spacer()

            if viewModel.state.biometric != .none {
                VPrimaryButton(model: model) {
                    viewModel.trigger(.faceID)
                } content: {
                    HStack(spacing: 15) {
                        Image(
                            systemName: viewModel.state
                                .biometric == .faceId ? "faceid" : "touchid"
                        )
                        .font(.title2)
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 30, alignment: .leading)
                        .foregroundColor(Color.LL.orange)
                        VStack(alignment: .leading) {
                            Text(
                                viewModel.state.biometric == .faceId ? "face_id"
                                    .localized : "touch_id".localized
                            )
                            .font(.LL.body)
                            .fontWeight(.semibold)
                            Text("recommend".localized)
                                .foregroundColor(Color.LL.orange)
                                .font(.LL.footnote)
                        }
                        Spacer()
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 18)
                    .foregroundColor(Color.LL.text)
                }
            }

            VPrimaryButton(model: model) {
                viewModel.trigger(.pin)
            } content: {
                HStack(spacing: 15) {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .foregroundColor(Color.LL.orange)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, alignment: .leading)
                    Text("pin_code".localized)
                        .font(.LL.body)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.forward.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 18)
                .foregroundColor(Color.LL.text)
            }
            .padding(.bottom)
        }
        .padding(.horizontal, 28)
        .backgroundFill(.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }
}

// MARK: - RequestSecureView_Previews

struct RequestSecureView_Previews: PreviewProvider {
    static var previews: some View {
        RequestSecureView()
    }
}
