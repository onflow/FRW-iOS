//
//  RecoveryPhraseBackupResultView.swift
//  FRW
//
//  Created by cat on 2024/9/19.
//

import SwiftUI

struct RecoveryPhraseBackupResultView: RouteableView {
    var mnemonic: String
    var deviceInfo: DeviceInfoRequest = IPManager.shared.toParams()

    var title: String {
        "backup".localized
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 27) {
                    Image("icon.recovery.normal")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .background(.Theme.Background.white)
                        .cornerRadius(40)
                        .clipped()

                    Text("backup.status.end.title".localized)
                        .font(.inter(size: 20, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black)

                    BackupedItemView(
                        backupType: .phrase,
                        mnemonic: mnemonic,
                        deviceInfo: deviceInfo
                    )
                }
            }
            .padding(.bottom, 16)

            VPrimaryButton(
                model: ButtonStyle.primary,
                action: {
                    onConfirm()
                },
                title: "done".localized
            )
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 18)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    func onConfirm() {
        Router.popToRoot()
    }
}

#Preview {
    RecoveryPhraseBackupResultView(mnemonic: "")
}
