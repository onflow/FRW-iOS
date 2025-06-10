//
//  ConfirmImportProfileView.swift
//  FRW
//
//  Created by cat on 6/9/25.
//

import SwiftUI

/// import multi-account: New Device
struct ConfirmImportProfileView: View {
    @StateObject var viewModel: ConfirmImportProfileViewModel

    init(list: [String]) {
        _viewModel = StateObject(wrappedValue: ConfirmImportProfileViewModel(list: list))
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("confirm_which_import")
                .font(.inter(size: 24, weight: .w700))
            VStack(spacing: 16) {
                ForEach(0 ..< viewModel.list.count, id: \.self) { _ in
                }
            }
        }
    }

    @ViewBuilder func profileCard() -> some View {
        VStack {
            HStack {}
        }
        .cardStyle()
    }
}

#Preview {
    ConfirmImportProfileView(list: [])
}
