//
//  LottieView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 21/8/2022.
//

import Foundation
import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    var name = "success"
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context _: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.frame = view.bounds
        animationView.center.x = view.frame.width / 2
        animationView.center.y = view.frame.height / 2
        animationView.loopMode = loopMode
        animationView.play()

//        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
//        NSLayoutConstraint.activate([
//            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
//            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
//        ])

        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}
