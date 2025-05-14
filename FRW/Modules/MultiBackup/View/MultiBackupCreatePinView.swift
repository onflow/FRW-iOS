//
//  MultiBackupCreatePinView.swift
//  FRW
//
//  Created by cat on 2024/2/6.
//

import Foundation
import SwiftUI

// MARK: - MultiBackupCreatePinView

struct MultiBackupCreatePinView: RouteableView {
    // MARK: Internal

    @StateObject
    var viewModel = MultiBackupCreatePinViewModel()
    @State
    var text: String = ""
    @State
    var focuse: Bool = false

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(alignment: .leading) {
                HStack {
                    Text("create_a".localized)
                        .bold()
                        .foregroundColor(Color.Theme.Text.black8)

                    Text("pin".localized)
                        .bold()
                        .foregroundColor(Color.Theme.Accent.green)
                }
                .font(.LL.largeTitle)

                Text("multi_backup_create_pin".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 30)

            PinCodeTextField(text: $text)
                .keyboardType(.numberPad)
                .fixedSize()
                .focused($pinCodeViewIsFocus)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pinCodeViewIsFocus = true
                    }
                }
                .onChange(of: text) { value in
                    viewModel.onCreate(pin: value)
                }

            Spacer()
        }
        .padding(.horizontal, 28)
        .backgroundFill(.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @FocusState
    private var pinCodeViewIsFocus: Bool
}

// MARK: - MultiBackupCreatePinView_Previews

struct MultiBackupCreatePinView_Previews: PreviewProvider {
    static var previews: some View {
        MultiBackupCreatePinView()
    }
}
