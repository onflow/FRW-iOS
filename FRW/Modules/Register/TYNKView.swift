//
//  TYNKView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 3/1/22.
//

import SwiftUI
import SwiftUIX

// MARK: - TYNKView

struct TYNKView: RouteableView {
    @StateObject
    var viewModel = TYNKViewModel()
    @State
    var stateList: [Bool] = [false, false, false]

    var title: String {
        ""
    }

    var buttonState: VPrimaryButtonState {
        stateList.contains(false) ? .disabled : .enabled
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("things_you".localized)
                    .font(.LL.largeTitle)
                    .bold()
                    .foregroundColor(Color.LL.rebackground)
                HStack {
                    Text("need_to".localized)
                        .bold()
                        .foregroundColor(Color.LL.rebackground)

                    Text("know".localized)
                        .bold()
                        .foregroundColor(Color.LL.orange)
                }
                .font(.LL.largeTitle)

                Text("secret_phrase_tips".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()

            VStack(spacing: 12) {
                ConditionView(
                    isOn: $stateList[0],
                    text: "secret_phrase_tips_1".localized
                )
                ConditionView(
                    isOn: $stateList[1],
                    text: "secret_phrase_tips_2".localized
                )
                ConditionView(
                    isOn: $stateList[2],
                    text: "secret_phrase_tips_3".localized
                )
            }
            .padding(.bottom, 40)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: buttonState,
                action: {
                    viewModel.chooseBackupMethodAction()
                },
                title: buttonState == .loading ? "almost_there".localized : "next"
                    .localized
            )
            .padding(.bottom)
        }
        .padding(.horizontal, 28)
        .background(Color.LL.background, ignoresSafeAreaEdges: .all)
        .applyRouteable(self)
        .tracedView(self)
    }
}

// MARK: - ConditionView

struct ConditionView: View {
    @Binding
    var isOn: Bool

    var text: String

    var model: VCheckBoxModel = {
        var model = VCheckBoxModel()
        model.layout.dimension = 20
        model.layout.cornerRadius = 6
        model.layout.contentMarginLeading = 15

        model.colors.textContent = .init(
            off: Color.LL.text,
            on: Color.LL.text,
            indeterminate: Color.LL.text,
            pressedOff: Color.LL.text,
            pressedOn: Color.LL.text,
            pressedIndeterminate: Color.LL.text,
            disabled: Color.LL.text
        )

        model.colors.fill = .init(
            off: .clear,
            on: Color.LL.orange,
            indeterminate: Color.LL.orange,
            pressedOff: Color.LL.orange.opacity(0.5),
            pressedOn: Color.LL.orange.opacity(0.5),
            pressedIndeterminate: Color.LL.orange,
            disabled: .gray
        )

        model.colors.icon = .init(
            off: .clear,
            on: Color.LL.background,
            indeterminate: Color.LL.background,
            pressedOff: Color.LL.background.opacity(0.5),
            pressedOn: Color.LL.background.opacity(0.5),
            pressedIndeterminate: Color.LL.background,
            disabled: Color.LL.background
        )
        return model
    }()

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                VCheckBox(
                    model: model,
                    isOn: $isOn
                )
                .padding(.horizontal, 12)
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 30, alignment: .leading)
                .allowsHitTesting(false)
                .frame(width: 30, height: 30, alignment: .center)

                Text(text)
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.LL.body)
                    .foregroundColor(.LL.text)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(lineWidth: 1)
                    .foregroundColor(isOn ? Color.LL.orange : .separator)
            }
        }
    }
}
