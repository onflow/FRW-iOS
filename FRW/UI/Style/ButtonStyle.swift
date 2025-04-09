//
//  ButtonStyle.swift
//  Flow Wallet
//
//  Created by Hao Fu on 2/1/22.
//

import SwiftUI

class ButtonStyle {
    public static let stakePrimary: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()

        model.fonts.title = Font.LL.body.bold()

        model.colors.textContent = .init(
            enabled: Color.white,
            pressed: Color.white.opacity(0.5),
            loading: Color.white,
            disabled: Color.white
        )

        model.colors.background = .init(
            enabled: Color.LL.stakeMain,
            pressed: Color.LL.stakeMain.opacity(0.5),
            loading: Color.LL.stakeMain,
            disabled: Color.LL.disable
        )

        model.layout.cornerRadius = 16
        return model
    }()

    public static let primary: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()

        model.fonts.title = Font.LL.body.bold()

        model.colors.textContent = .init(
            enabled: Color.LL.frontColor,
            pressed: Color.LL.frontColor.opacity(0.5),
            loading: Color.LL.frontColor,
            disabled: Color.LL.frontColor
        )

        model.colors.background = .init(
            enabled: Color.LL.rebackground,
            pressed: Color.LL.rebackground.opacity(0.5),
            loading: Color.LL.rebackground,
            disabled: Color.LL.disable
        )

        model.layout.cornerRadius = 16
        return model
    }()

    public static let border: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()

        model.fonts.title = Font.LL.body.bold()
        model.layout.borderWidth = 1
        model.colors.textContent = .init(
            enabled: Color.LL.rebackground,
            pressed: Color.LL.rebackground.opacity(0.5),
            loading: Color.LL.rebackground,
            disabled: Color.LL.rebackground
        )

        model.colors.background = .clear

        model.colors.border = .init(
            enabled: Color.LL.rebackground,
            pressed: Color.LL.rebackground.opacity(0.5),
            loading: Color.LL.rebackground,
            disabled: Color.LL.rebackground
        )

        model.layout.cornerRadius = 16
        return model
    }()

    public static let plain: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()

        model.fonts.title = Font.LL.body.bold()
//        model.layout.borderWidth = 1
        model.colors.textContent = .init(
            enabled: Color.LL.rebackground,
            pressed: Color.LL.rebackground.opacity(0.5),
            loading: Color.LL.rebackground,
            disabled: Color.LL.rebackground
        )

        model.colors.background = .clear

        model.layout.cornerRadius = 16
        return model
    }()

    public static let evmEnable: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()
        model.layout.height = 48
        model.fonts.title = Font.inter(size: 16, weight: .w600)
        let textColor = Color.Theme.Text.white9
        model.colors.textContent = .init(
            enabled: textColor,
            pressed: textColor.opacity(0.5),
            loading: textColor,
            disabled: textColor
        )
        let backgroundColor = Color.Theme.Accent.green
        model.colors.background = .init(
            enabled: backgroundColor,
            pressed: backgroundColor.opacity(0.5),
            loading: backgroundColor,
            disabled: backgroundColor
        )

        model.layout.cornerRadius = 16
        return model
    }()

    public static let green: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()
        model.layout.height = 48
        model.fonts.title = Font.inter(size: 16, weight: .w600)
        let textColor = Color.Theme.Text.black8
        model.colors.textContent = .init(
            enabled: textColor,
            pressed: textColor.opacity(0.5),
            loading: textColor,
            disabled: textColor
        )
        let backgroundColor = Color.Theme.Accent.green
        model.colors.background = .init(
            enabled: backgroundColor,
            pressed: backgroundColor.opacity(0.5),
            loading: backgroundColor,
            disabled: backgroundColor
        )

        model.layout.cornerRadius = 16
        return model
    }()

    public static let blackMini: VPrimaryButtonModel = {
        var model: VPrimaryButtonModel = .init()

        model.fonts.title = Font.LL.body.bold()
        model.layout.height = 40
        model.colors.textContent = .init(
            enabled: Color.LL.frontColor,
            pressed: Color.LL.frontColor.opacity(0.5),
            loading: Color.LL.frontColor,
            disabled: Color.LL.frontColor
        )

        model.colors.background = .init(
            enabled: Color.LL.rebackground,
            pressed: Color.LL.rebackground.opacity(0.5),
            loading: Color.LL.rebackground,
            disabled: Color.LL.disable
        )

        model.layout.cornerRadius = 24
        return model
    }()
}


// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.linear(duration: 0.2), value: configuration.isPressed)
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}


struct PressButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .animation(.linear(duration: 0.2), value: configuration.isPressed)
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}
