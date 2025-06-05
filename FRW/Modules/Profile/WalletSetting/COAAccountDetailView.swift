//
//  COAAccountDetailView.swift
//  FRW
//
//  Created by cat on 6/6/25.
//

import FlowWalletKit
import SwiftUI

struct COAAccountDetailView: RouteableView {
    var account: FlowWalletKit.COA

    var title: String {
        "linked_account".localized
    }

    var body: some View {
        ScrollView {
            VStack {
                AccountInfoCard(account: account) {
                    // TODO: Edit
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .backgroundFill(Color.Theme.Background.white)
        }
        .applyRouteable(self)
        .tracedView(self)
    }
}
