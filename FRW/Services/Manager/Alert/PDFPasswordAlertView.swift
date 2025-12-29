//
//  PDFPasswordAlertView.swift
//  FRW
//
//  Created by cat on 12/20/25.
//

import SwiftUI

// MARK: - View Model

class PDFPasswordAlertViewModel: ObservableObject {
    @Published var password: String = ""
}

// MARK: - Content View

struct PDFPasswordAlertContentView: View {
    @ObservedObject var viewModel: PDFPasswordAlertViewModel
    let message: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(message)
                .font(.inter(size: 14))
                .foregroundColor(Color.LL.Neutrals.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            
            LL.TextField(
                placeHolder: "password".localized,
                text: $viewModel.password,
                style: .constant(.secure)
            )
            .frame(height: 50)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Alert Presenter

enum PDFPasswordAlertView {
    
    /// Show password input alert
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message (optional, defaults to generic message)
    ///   - completion: Callback with entered password or nil if cancelled
    static func show(
        title: String = "Password Required",
        message: String? = nil,
        completion: @escaping (String?) -> Void
    ) {
        let viewModel = PDFPasswordAlertViewModel()
        let displayMessage = message ?? "This PDF is password protected. Please provide a password."
        
        runOnMain {
            let confirmBtn = AlertView.ButtonItem(
                type: .primaryAction,
                title: "Unlock"
            ) {
                completion(viewModel.password)
            }
            
            let cancelBtn = AlertView.ButtonItem(
                type: .normal,
                title: "action_cancel".localized
            ) {
                completion(nil)
            }
            
            AlertViewController.presentOnRoot(
                title: title,
                customContentView: AnyView(
                    PDFPasswordAlertContentView(
                        viewModel: viewModel,
                        message: displayMessage
                    )
                ),
                buttons: [cancelBtn, confirmBtn],
                useDefaultCancelButton: false,
                buttonsLayout: .horizontal,
                textAlignment: .center
            )
        }
    }
}