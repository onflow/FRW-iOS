//
//  RestoreErrorView.swift
//  FRW
//
//  Created by cat on 2024/7/9.
//

import SwiftUI

// MARK: - RestoreErrorView

struct RestoreErrorView: RouteableView {
    // MARK: Internal

    var error: RestoreErrorView.RestoreError = .notfound

    var title: String {
        "import_wallet".localized
    }

    var body: some View {
        VStack(spacing: 0) {
            Image("import_error_cover")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 107)

            Text(error.title)
                .font(.inter(size: 20, weight: .bold))
                .foregroundStyle(Color.Theme.Text.black)
                .padding(.top, 40)

            Text(error.descresption)
                .font(.inter(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Accent.grey)
                .padding(.top, 24)

            VPrimaryButton(
                model: ButtonStyle.blackMini,
                state: .enabled,
                action: {
                    onClickButton()
                },
                title: error.buttonTitle
            )
            .frame(height: 40)
            .padding(.top, 72)
            .padding(.horizontal, 62)
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    private func onClickButton() {
        switch error {
        case .notfound:
            Router.pop()
        case .noAccountFound:
            Router.popToRoot()
        case .decryption:
            Router.pop()
        }
    }
}

// MARK: RestoreErrorView.RestoreError

extension RestoreErrorView {
    enum RestoreError: Error {
        case notfound
        case noAccountFound
        case decryption

        // MARK: Internal

        var title: String {
            switch self {
            case .notfound:
                "Backup_Not_Found".localized
            case .noAccountFound:
                "No_Backup_Account_Found".localized
            case .decryption:
                "Backup_Decryption_Failed".localized
            }
        }

        var descresption: String {
            switch self {
            case .notfound:
                "Backup_Not_Found_Desc".localized
            case .noAccountFound:
                "No_Backup_Account_Found_Desc".localized
            case .decryption:
                "Backup_Decryption_Failed_Desc".localized
            }
        }

        var buttonTitle: String {
            switch self {
            case .notfound:
                return "go_back".localized
            case .noAccountFound:
                return "go_back".localized
            case .decryption:
                return "try_again".localized
            }
        }
    }
}

#Preview {
    RestoreErrorView()
}
