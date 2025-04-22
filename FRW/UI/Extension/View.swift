//
//  View.swift
//  Flow Wallet-lite
//
//  Created by Hao Fu on 27/11/21.
//

import Combine
import SwiftUI
import UIKit

extension View {
    var screenBounds: CGRect {
        UIScreen.main.bounds
    }

    var screenWidth: CGFloat {
        screenBounds.width
    }

    var screenHeight: CGFloat {
        screenBounds.height
    }
}

extension View {
    /// Applies modifier and transforms view if condition is met.
    @ViewBuilder
    public func `if`<Content>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View
        where Content: View {
        switch condition {
        case false: self
        case true: transform(self)
        }
    }

    /// Applies modifier and transforms view if condition is met, or applies alternate modifier.
    @ViewBuilder
    public func `if`<IfContent, ElseContent>(
        _ condition: Bool,
        ifTransform: (Self) -> IfContent,
        elseTransform: (Self) -> ElseContent
    ) -> some View
        where
        IfContent: View,
        ElseContent: View {
        switch condition {
        case false: ifTransform(self)
        case true: elseTransform(self)
        }
    }

    /// Applies modifier and transforms view if value is non-nil.
    @ViewBuilder
    public func ifLet<Value, Content>(
        _ value: Value?,
        transform: (Self, Value) -> Content
    ) -> some View
        where Content: View {
        switch value {
        case let value?: transform(self, value)
        case nil: self
        }
    }

    /// Applies modifier and transforms view if value is non-nil, or applies alternate modifier.
    @ViewBuilder
    public func ifLet<Value, IfContent, ElseContent>(
        _ value: Value?,
        ifTransform: (Self, Value) -> IfContent,
        elseTransform: (Self) -> ElseContent
    ) -> some View
        where
        IfContent: View,
        ElseContent: View {
        switch value {
        case let value?: ifTransform(self, value)
        case nil: elseTransform(self)
        }
    }
}

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size

//    static let screenWidth = UIScreen.main.bounds.size.width +
}

extension View {
    func keyboardSensible(_ offsetValue: Binding<CGFloat>) -> some View {
        padding(.bottom, offsetValue.wrappedValue)
            .animation(.spring())
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in

                    let keyWindow = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .map { $0 as? UIWindowScene }
                        .compactMap { $0 }
                        .first?.windows
                        .filter { $0.isKeyWindow }.first

                    let bottom = keyWindow?.safeAreaInsets.bottom ?? 0

                    let value = notification
                        .userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                    let height = value.height

                    offsetValue.wrappedValue = height - bottom
                }

                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    offsetValue.wrappedValue = 0
                }
            }
    }

    func hideKeyboardWhenTappedAround() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

// MARK: - ViewVisibility

enum ViewVisibility: CaseIterable {
    case visible
    case invisible
    case gone
}

extension View {
    @ViewBuilder
    func visibility(_ visibility: ViewVisibility) -> some View {
        if visibility != .gone {
            if visibility == .visible {
                self
            } else {
                hidden()
            }
        }
    }
    
    @ViewBuilder
    func visibility(_ isVisible: Bool) -> some View {
        if isVisible {
            self
        }
    }

    @ViewBuilder
    func roundedBg(
        cornerRadius: CGFloat = 16,
        fillColor: Color = .LL.bgForIcon,
        strokeColor: Color? = nil,
        strokeLineWidth: CGFloat? = nil
    ) -> some View {
        let fillBg = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)

        if let strokeColor = strokeColor, let lineWidth = strokeLineWidth {
            let strokeAndFillBg = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: lineWidth)
                .background(fillBg)

            background(strokeAndFillBg)
        } else {
            background(fillBg)
        }
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(
            content: self,
            modifier: CornerRadiusStyle(radius: radius, corners: corners)
        )
    }

    func roundedButtonStyle(bgColor: Color = .LL.Secondary.violet5) -> some View {
        background(bgColor).clipShape(Circle())
    }
}

// MARK: - CornerRadiusStyle

struct CornerRadiusStyle: ViewModifier {
    struct CornerRadiusShape: Shape {
        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }

    var radius: CGFloat
    var corners: UIRectCorner

    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

// MARK: - NavigationBar back button

extension View {
    private func backBtn(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: "arrow.backward")
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.LL.Neutrals.neutrals1)
            }
        }
    }

    @ViewBuilder
    func addBackBtn(action: (() -> Void)? = nil) -> some View {
        let defaultAction = {
            Router.pop()
        }

        navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: backBtn(action: action == nil ? defaultAction : action!))
    }
}
