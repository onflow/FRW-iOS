//
//  AccountStyle.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

struct AccountStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color.Brain.Core.cards)
    }
}

extension View {
    func accountStyle() -> some View {
        modifier(AccountStyle())
    }
}

#Preview {
    Text("Hello, World!")
        .accountStyle()
}
