//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import SwiftUI

struct LinkedAccountDetailView: RouteableView {
    let account: FlowWalletKit.ChildAccount

    var title: String {
        "linked_account".localized
    }

    var body: some View {
        ScrollView {
            VStack {
                infoView
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .backgroundFill(Color.Theme.Background.white)
            .applyRouteable(self)
            .tracedView(self)
        }
    }

    @ViewBuilder
    var infoView: some View {
        VStack {
            AccountInfoWithEditView(account: account) {}

            LineView()
        }
        .cardStyle()
    }
}

#Preview {}
