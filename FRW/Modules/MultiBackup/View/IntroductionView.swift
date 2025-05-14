//
//  IntroductionView.swift
//  FRW
//
//  Created by cat on 2024/9/14.
//

import SwiftUI

// MARK: - IntroductionView

struct IntroductionView: RouteableView {
    var topic: IntroductionView.Topic
    var confirmClosure: EmptyClosure

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading) {
                Text(topic.titleTop)
                    .font(.Montserrat(size: 32, weight: .semibold))
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.Theme.Text.black)
                Text(topic.titleBottom)
                    .font(.Montserrat(size: 32, weight: .semibold))
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.Theme.Accent.green)
            }
            .padding(.top, 32)
            ScrollView {
                Text(topic.content)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black8)
            }

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: .enabled,
                action: {
                    onClick()
                },
                title: "OK".localized
            )
        }
        .padding(.horizontal, 28)
        .applyRouteable(self)
        .tracedView(self)
    }

    func onClick() {
        Router.pop()
        confirmClosure()
    }
}

// MARK: IntroductionView.Topic

extension IntroductionView {
    enum Topic {
        case whatMultiBackup
        case aboutRecoveryPhrase

        // MARK: Internal

        var titleTop: String {
            switch self {
            case .whatMultiBackup:
                return "what_is".localized
            case .aboutRecoveryPhrase:
                return "about_phrase_title_top".localized
            }
        }

        var titleBottom: String {
            switch self {
            case .whatMultiBackup:
                return "multi_backup".localized
            case .aboutRecoveryPhrase:
                return "about_phrase_title_bottom".localized
            }
        }

        var content: String {
            switch self {
            case .whatMultiBackup:
                return "multi_backup_detail".localized
            case .aboutRecoveryPhrase:
                return "about_phrase_title_content".localized
            }
        }
    }
}

#Preview {
    IntroductionView(topic: .whatMultiBackup) {}
}
