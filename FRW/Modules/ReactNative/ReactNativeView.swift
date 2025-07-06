//
//  ReactNativeView.swift
//  FRW
//
//  Created by Claude on 2025-07-06.
//

import SwiftUI

struct ReactNativeView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let reactViewController = ReactNativeViewController()
        let navigationController = UINavigationController(rootViewController: reactViewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

struct ReactNativeView_Previews: PreviewProvider {
    static var previews: some View {
        ReactNativeView()
    }
}