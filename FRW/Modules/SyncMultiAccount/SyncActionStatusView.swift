//
//  SyncActionStatusView.swift
//  FRW
//
//  Created by cat on 6/9/25.
//

import SwiftUI

struct SyncActionStatusView: RouteableView {
    enum Source {
        case old, new

        var status: String {
            switch self {
            case .old:
                "sync_status_old".localized
            case .new:
                "sync_status_new".localized
            }
        }

        var hintMessage: String {
            switch self {
            case .old:
                "sync_from_old".localized
            case .new:
                "sync_from_new".localized
            }
        }
    }

    var title: String {
        "action_required".localized
    }

    var source: SyncActionStatusView.Source

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                Image("import.device")
                    .resizable()
                    .frame(width: 42, height: 42)
                Image("switch-horizontal")
                    .resizable()
                    .frame(width: 24, height: 24)
                Image("import.device")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Accent.green)
                    .frame(width: 42, height: 42)
            }
            .padding(.top, 30)

            Text(source.status)
                .font(.inter(size: 16))
                .foregroundStyle(Color.Summer.Text.secondary)

            Text(source.hintMessage)
                .font(.inter(size: 24))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Text.text1)
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .backgroundFill(Color.Theme.Background.white)
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview {
    SyncActionStatusView(source: .old)
}
