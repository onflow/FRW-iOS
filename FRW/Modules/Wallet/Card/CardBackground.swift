//
//  CardBackground.swift
//  Flow Wallet
//
//  Created by Hao Fu on 21/8/2022.
//

import Foundation
import SwiftUI

enum CardBackground: CaseIterable {
    enum Style {
        case flow
        case evm
    }

    static var dynamicCases: [CardBackground] = [
        .fluid,
        .matrix,
        .fade(imageIndex: 0),
        .fluidGradient
    ]

    static var imageCases: [CardBackground] = [
        .image(imageIndex: 0),
        .image(imageIndex: 1),
        .image(imageIndex: 2),
        .image(imageIndex: 3),
        .image(imageIndex: 4),
        .image(imageIndex: 5),
    ]

    static var allCases: [CardBackground] = [
        .fluid,
        .matrix,
        .color(color: UIColor.LL.Primary.salmonPrimary),
        .fluidGradient,
        .fade(imageIndex: 0),
    ]

    case color(color: UIColor)
    case image(imageIndex: Int)
    case fade(imageIndex: Int)
    case fluid
    case matrix
    case fluidGradient

    @ViewBuilder
    func renderView() -> some View {
        switch self {
        case .fluid:
            FluidView()
        case .matrix:
            MatrixRainView()
        case let .color(color):
            ZStack {
                Color(color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Image("bg-circles")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        case let .fade(imageIndex):
            FadeAnimationBackground(image: fadeList[safe: imageIndex] ?? fadeList[0], color: fadeColor)
        case let .image(imageIndex):
            (imageList[safe: imageIndex] ?? imageList[0])
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .fluidGradient:
            FluidGradient(blobs: [.green, .blue, .red, .pink, .purple, .indigo],
                          highlights: [.green, .yellow, .orange, .blue, .pink, .indigo],
                          speed: 0.8)
        }
    }

    var imageList: [Image] {
        return [Image("wallpaper_0"), Image("wallpaper_1"), Image("wallpaper_2"), Image("wallpaper_3"), Image("wallpaper_4"), Image("wallpaper_5")]
    }

    var fadeList: [Image] {
        switch self {
        case .fade:
            switch cardStyle {
            case .evm:
                return [Image("evm-line")]
            default:
                return [Image("flow-line")]
            }
        default:
            return [Image("flow-line")]
        }
    }

    var fadeColor: Color {
        switch self {
        case .fade:
            switch cardStyle {
            case .evm:
                return Color.Theme.Accent.blue
            default:
                return Color.Theme.Accent.green
            }
        default:
            return Color.Theme.Accent.green
        }
    }

    private var cardStyle: CardBackground.Style {
        WalletManager.shared.isSelectedEVMAccount ? CardBackground.Style.evm : CardBackground.Style.flow
    }

    var rawValue: String {
        switch self {
        case let .color(color):
            return identify + ":" + color.hex
        case let .image(imageIndex):
            return identify + ":" + String(imageIndex)
        case let .fade(imageIndex):
            return identify + ":" + String(imageIndex)
        case .fluid:
            return identify
        case .matrix:
            return identify
        case .fluidGradient:
            return identify
        }
    }

    var identify: String {
        switch self {
        case .color:
            return "color"
        case .image:
            return "image"
        case .fade:
            return "fade"
        case .fluid:
            return "fluid"
        case .matrix:
            return "matrix"
        case .fluidGradient:
            return "fluidGradient"
        }
    }

    var color: Color {
        switch self {
        case let .color(color):
            return Color(color)
        case .fade:
            return Color.LL.flow
        case .matrix:
            return Color(hex: "#00EF8B")
        default:
            return Color.LL.outline
        }
    }

    init(value: String) {
        let list = value.split(separator: ":", omittingEmptySubsequences: true)
        switch list[0] {
        case CardBackground.fluid.identify:
            self = .fluid
        case CardBackground.matrix.identify:
            self = .matrix
        case CardBackground.color(color: .clear).identify:
            guard let hex = list[safe: 1] else {
                self = .color(color: UIColor.LL.bgForIcon)
                return
            }
            self = .color(color: UIColor(hex: String(hex)))

        case CardBackground.fade(imageIndex: 0).identify:
            guard let imageString = list[safe: 1], let index = Int(imageString) else {
                self = .fade(imageIndex: 0)
                return
            }
            self = .fade(imageIndex: index)

        case CardBackground.image(imageIndex: 0).identify:
            guard let imageString = list[safe: 1], let index = Int(imageString) else {
                self = .image(imageIndex: 0)
                return
            }
            self = .image(imageIndex: index)
        case CardBackground.fluidGradient.identify:
            self = .fluidGradient
        default:
            self = .fade(imageIndex: 0)
        }
    }

    struct Key: PreferenceKey {
        public typealias Value = CardBackground
        public static var defaultValue = CardBackground.fluid
        public static func reduce(value: inout Value, nextValue: () -> Value) {
            value = nextValue()
        }
    }
}
