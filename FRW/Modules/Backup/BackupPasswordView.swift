//
//  BackupPasswordView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 6/1/22.
//

import SwiftUI
import SwiftUIX

// MARK: - BackupPasswordView

struct BackupPasswordView: RouteableView {
    // MARK: Lifecycle

    init(backupType: BackupManager.BackupType) {
        _vm = StateObject(wrappedValue: BackupPasswordViewModel(backupType: backupType))
    }

    // MARK: Internal

    @StateObject
    var vm: BackupPasswordViewModel

    @State
    var isTick: Bool = false
    @State
    var highlight: VTextFieldHighlight = .none
    @State
    var confrimHighlight: VTextFieldHighlight = .none
    @State
    var text: String = ""
    @State
    var confrimText: String = ""

    var model: VTextFieldModel = {
        var model = TextFieldStyle.primary
        model.misc.textContentType = .newPassword
        return model
    }()

    var title: String {
        ""
    }

    var canGoNext: Bool {
        if confrimText.count < 8 || text.count < 8 {
            return false
        }

        return confrimText == text && isTick
    }

    var buttonState: VPrimaryButtonState {
        canGoNext ? .enabled : .disabled
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading) {
                Text("create_backup".localized)
                    .bold()
                    .foregroundColor(Color.LL.text)
                    .font(.LL.largeTitle)

                Text("password".localized)
                    .bold()
                    .foregroundColor(Color.LL.orange)
                    .font(.LL.largeTitle)

                Text("password_use_tips".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 25) {
                VTextField(
                    model: model,
                    type: .secure,
                    highlight: highlight,
                    placeholder: "backup_password".localized,
                    footerTitle: "minimum_8_char".localized,
                    text: $text,
                    onChange: {}
                )

                VTextField(
                    model: model,
                    type: .secure,
                    highlight: confrimHighlight,
                    placeholder: "confirm_password".localized,
                    footerTitle: "",
                    text: $confrimText,
                    onChange: {},
                    onReturn: .returnAndCustom {}
                )
            }.padding(.bottom, 25)

            VCheckBox(
                model: CheckBoxStyle.secondary,
                isOn: $isTick
            ) {
                VText(
                    type: .oneLine,
                    font: .footnote,
                    color: Color.LL.rebackground,
                    title: "can_not_recover_pwd_tips".localized
                )
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: buttonState,
                action: {
                    UIApplication.shared.endEditing()
                    vm.backupToCloudAction(password: confrimText)
                },
                title: "secure_backup".localized
            )
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    func backButtonAction() {
        UIApplication.shared.endEditing()
        Router.pop()
    }
}

// MARK: - BackupPasswordView_Previews

struct BackupPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        BackupPasswordView(backupType: .googleDrive)
    }
}
