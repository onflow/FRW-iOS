//
//  WalletSendButtonView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 1/9/2022.
//

import SwiftUI

// MARK: - WalletSendButtonView

struct WalletSendButtonView: View {
    @GestureState
    var tap = false

    @State
    var press = false

    @State
    var isLoading: Bool = false

    @Binding
    var allowEnable: Bool

    var buttonText: String = "hold_to_send".localized
    var activeColor = Color.LL.Button.color
    var action: () -> Void

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(
                        Color.LL.outline.opacity(0.3),
                        lineWidth: 4
                    )
                Circle()
                    .trim(from: press ? 0.001 : 1, to: 1)
                    .stroke(
                        Color.LL.outline,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .rotation3DEffect(Angle(degrees: -180), axis: (x: 0, y: 1, z: 0))
                    // Magic HERE !
                    .animation(.easeInOut)
                    .visible(!isLoading)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        Color.LL.outline,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .rotation3DEffect(Angle(degrees: -180), axis: (x: 0, y: 1, z: 0))
                    .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: isLoading
                    )
                    .visible(isLoading)
            }
            .frame(width: 25, height: 25)
            Text(buttonText)
                .foregroundColor(Color.LL.Button.text)
                .font(.inter(size: 14, weight: .bold))
                .allowsHitTesting(false)
        }
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(allowEnable ? activeColor : Color.LL.Neutrals.neutrals6)
        .cornerRadius(12)
        .scaleEffect(press ? 0.95 : 1)
//        .gesture(
//            LongPressGesture(minimumDuration: 0.1)
//                .updating($tap) { currentState, gestureState, _ in
//                    gestureState = currentState
//                }
//                .onEnded { _ in
//                    self.press.toggle()
//                    self.isLoading = true
//
//                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//
//                    action()
//                }
//        )
        .onLongPressGesture(minimumDuration: 0.8, perform: {
            print("Long pressed!")
            self.press.toggle()
            self.isLoading = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }, onPressingChanged: { inProgress in
            // TODO: Fix animation time, currently animation and duration time are not matched
            self.press = inProgress
            log.debug("Long pressed \(inProgress)")
        })
        .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0), value: press)
        .disabled(!allowEnable)
        //            .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - MyAnimations

class MyAnimations: NSObject, ObservableObject {
    // MARK: Internal

    @Published
    var progress: Double = 0

    func createDisplayLink() {
        if displaylink == nil {
            displaylink = CADisplayLink(target: self, selector: #selector(step))
            displaylink.add(to: .main, forMode: .common)
        }
    }

    @objc
    func step(link _: CADisplayLink) {
        progress += 0.05
    }

    func stop() {
        if displaylink != nil {
            displaylink.invalidate()
        }
    }

    // MARK: Private

    private var displaylink: CADisplayLink! // << here !!
}

// MARK: - WalletSendButtonView_Previews

struct WalletSendButtonView_Previews: PreviewProvider {
    @State
    static var isEnable = true
    @State
    static var isNot = false

    static var previews: some View {
        WalletSendButtonView(allowEnable: $isEnable) {}
            .previewLayout(.sizeThatFits)
        WalletSendButtonView(allowEnable: $isNot) {}
            .previewLayout(.sizeThatFits)
    }
}
