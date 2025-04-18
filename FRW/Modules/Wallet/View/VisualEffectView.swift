//
//  VisualEffectView.swift
//  FRW
//
//  Created by Hao Fu on 5/4/2025.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - VisualEffectView

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context _: UIViewRepresentableContext<Self>)
        -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context _: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

// MARK: - VisualEffectBlur

struct VisualEffectBlur: UIViewRepresentable {
    var effect: UIBlurEffect.Style

    func makeUIView(context _: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: effect)
    }
}
