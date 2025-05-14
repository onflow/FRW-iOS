//
//  RestoreWalletView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 31/12/21.
//

import SwiftUI

// MARK: - RestoreWalletView

struct RestoreWalletView: RouteableView {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("import_btn_text".localized)
                        .foregroundColor(Color.LL.orange)
                        .bold()
                    Text("wallet".localized)
                        .foregroundColor(Color.LL.text)
                        .bold()
                }
                .font(.LL.largeTitle)

                Text("import_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: 1, height: 32)

            ScrollView(showsIndicators: false) {
                RestoreWalletView.Item(backupType: .google)
                    .onTapGesture {
                        viewModel.restoreWithCloudAction(type: .googleDrive)
                    }

                RestoreWalletView.Item(backupType: .phrase)
                    .onTapGesture {
                        viewModel.restoreWithManualAction()
                    }
                RestoreWalletView.Item(backupType: .keyStore)
                    .onTapGesture {
                        viewModel.restoreWithKeyStore()
                    }
                RestoreWalletView.Item(backupType: .privateKey)
                    .onTapGesture {
                        viewModel.resteroWithPrivateKey()
                    }
                Spacer()
            }
            .sn_introspectScrollView { scrollView in
                scrollView.alwaysBounceVertical = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .backgroundFill(Color.Theme.Background.grey)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    private var viewModel = RestoreWalletViewModel()
}

extension RestoreWalletView {
    var title: String {
        ""
    }
}

// MARK: RestoreWalletView.Item

extension RestoreWalletView {
    struct Item: View {
        let backupType: RestoreWalletViewModel.ImportType

        var body: some View {
            HStack(spacing: 16) {
                Image(backupType.icon40)
                    .resizable()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(backupType.title)
                        .font(.inter(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(Color.Theme.Text.black)

                    Text(backupType.importDesc)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black3)
                }
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.Theme.Background.bg2)
            .cornerRadius(16)
        }
    }
}

// MARK: - RestoreWalletViewModel.ImportType

extension RestoreWalletViewModel {
    enum ImportType {
        case google
        case iCloud
        case phrase
        case keyStore
        case privateKey
        case seedPhrase

        // MARK: Internal

        var title: String {
            switch self {
            case .google:
                return "google_drive".localized
            case .iCloud:
                return "iCloud"
            case .phrase:
                return "Seed Phrase"
            case .keyStore:
                return "Key Store"
            case .privateKey:
                return "Private Key"
            case .seedPhrase:
                return "Seed Phrase"
            }
        }

        var icon40: String {
            switch self {
            case .google:
                return "icon_import_google_40"
            case .iCloud:
                return "icon_import_icloud_40"
            case .phrase:
                return "icon_import_phrase_40"
            case .keyStore:
                return "icon_import_keystore_40"
            case .privateKey:
                return "icon_import_privatekey_40"
            case .seedPhrase:
                return "icon_import_phrase_40"
            }
        }

        var importDesc: String {
            switch self {
            case .google:
                return "import_google_desc".localized
            case .iCloud:
                return "import_icloud_desc".localized
            case .phrase:
                return "import_phrase_desc".localized
            case .keyStore:
                return "import_keystore_desc".localized
            case .privateKey:
                return "import_privatekey_desc".localized
            case .seedPhrase:
                return "import_phrase_desc".localized
            }
        }
    }
}

// MARK: - RestoreWalletView_Previews

struct RestoreWalletView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreWalletView()
    }
}
