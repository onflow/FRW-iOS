//
//  BackupedItemView.swift
//  FRW
//
//  Created by cat on 2024/8/9.
//

import SwiftUI

struct BackupedItemView: View {
    // MARK: Internal

    let backupType: MultiBackupType
    var mnemonic: String? = nil
    var deviceInfo: DeviceInfoRequest? = nil

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Image(backupType.iconName())
                    .resizable()
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(backupType.title) Backup")
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.Theme.Text.black8)
                        .foregroundColor(.black.opacity(0.8))
                    Text(showApp())
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black3)
                    Text(showLocation())
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black3)
                }
                Spacer()
                HStack {
                    Image("check_fill_1")
                        .frame(width: 16, height: 16)
                }
                .frame(width: 16)
                .frame(minHeight: 0, maxHeight: .infinity)
            }
            .padding(16)
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 96)

            if backupType == .phrase {
                VStack {
                    Divider()
                        .background(Color.Theme.Line.line)
                        .frame(height: 1)
                        .padding(.horizontal, 18)

                    HStack {
                        Spacer()
                        WordListView(data: Array(mnemonicList().prefix(colum())))
                        Spacer()
                        WordListView(data: Array(mnemonicList().suffix(from: colum())))
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 30)

                    HStack(alignment: .center) {
                        Spacer()
                        Button {
                            UIPasteboard.general.string = validMnemonic()
                            HUD.success(title: "copied".localized)
                        } label: {
                            Image("icon-copy-phrase")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.Theme.Accent.green)
                                .frame(width: 100, height: 40)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PrivateKeyWarning()
                        .padding(.horizontal, 10)
                        .padding(.top)
                        .padding(.bottom)
                }
            }
        }
        .background(.Theme.Background.grey)
        .cornerRadius(16)
    }

    // MARK: Private

    private func showApp() -> String {
        if let info = deviceInfo {
            return info.showApp()
        }
        let item = MultiBackupManager.shared.getTarget(with: backupType)
        return item.registeredDeviceInfo?.deviceInfo.showApp() ?? ""
    }

    private func showLocation() -> String {
        if let info = deviceInfo {
            return info.showLocation()
        }
        let item = MultiBackupManager.shared.getTarget(with: backupType)
        return item.registeredDeviceInfo?.deviceInfo.showLocation() ?? ""
    }

    private func validMnemonic() -> String? {
        if backupType != .phrase {
            return nil
        }
        if let mnemonic = mnemonic {
            return mnemonic
        }
        guard let mnemonic = MultiBackupManager.shared.mnemonic else {
            return nil
        }
        return mnemonic
    }

    private func mnemonicList() -> [WordListView.WordItem] {
        guard let mnemonic = validMnemonic() else {
            return []
        }

        let list = mnemonic.split(separator: " ").enumerated().map { item in
            WordListView.WordItem(id: item.offset + 1, word: String(item.element))
        }
        return list
    }

    private func colum() -> Int {
        Int(ceil(Double(mnemonicList().count) / 2.0))
    }
}

#Preview {
    BackupedItemView(backupType: .google)
}
