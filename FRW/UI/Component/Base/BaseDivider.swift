//
//  BaseDivider.swift
//  Flow Wallet
//
//  Created by Selina on 19/5/2022.
//

import SwiftUI

struct BaseDivider: View {
    var body: some View {
        Divider().foregroundColor(.LL.Neutrals.background).padding(.horizontal, 8)
    }
}

struct LineView: View {
    var body: some View {
        Divider()
            .foregroundColor(Color.Summer.line)
    }
}
