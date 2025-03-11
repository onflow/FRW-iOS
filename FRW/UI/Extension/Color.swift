//
//  Color.swift
//  Flow Wallet-lite
//
//  Created by Hao Fu on 27/11/21.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: UInt64, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hex: String, alpha: Double = 1) {
//        if (hex.hasPrefix("#")) {
//
//        }
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: int, alpha: alpha)
    }
}

extension UIColor {
    func adjustbyTheme(by percentage: CGFloat = 30.0) -> UIColor {
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            return lighter(by: percentage)
        }
        return darker(by: percentage)
    }

    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        adjust(by: -1 * abs(percentage))
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(
                red: min(red + percentage / 100, 1.0),
                green: min(green + percentage / 100, 1.0),
                blue: min(blue + percentage / 100, 1.0),
                alpha: alpha
            )
        } else {
            return self
        }
    }
}

extension Color {
    func adjustbyTheme(by percentage: CGFloat = 30.0) -> Color {
        Color(UIColor(self).adjustbyTheme(by: percentage))
    }
}

// MARK: - Color.LL

extension Color {
    enum LL {
        /// The primary color palette is used across all the iteractive elemets such as CTA’s(Call to The Action), links, inputs,active states,etc
        enum Primary {
            static let salmon1 = Color("primary.salmon1")
            static let salmonPrimary = Color("primary.salmonPrimary")
            static let salmon3 = Color("primary.salmon3")
            static let salmon4 = Color("primary.salmon4")
            static let salmon5 = Color("primary.salmon5")
        }

        /// The neutral color palette is used as supportig secondary colors in backgrounds, text colors,  seperators, models, etc
        enum Secondary {
            static let violet1 = Color("secondary.violet1")
            static let violetDiscover = Color("secondary.violetDiscover")
            static let violet3 = Color("secondary.violet3")
            static let violet4 = Color("secondary.violet4")
            static let violet5 = Color("secondary.violet5")

            static let navy1 = Color("secondary.navy1")
            static let navyWallet = Color("secondary.navyWallet")
            static let navy3 = Color("secondary.navy3")
            static let navy4 = Color("secondary.navy4")
            static let navy5 = Color("secondary.navy5")

            static let mango1 = Color("secondary.mango1")
            static let mangoNFT = Color("secondary.mangoNFT")
            static let mango3 = Color("secondary.mango3")
            static let mango4 = Color("secondary.mango4")
            static let mango5 = Color("secondary.mango5")
        }

        /// The neutral color palette is used as supportig secondary colors in backgrounds, text colors,  seperators, models, etc
        enum Neutrals {
            static let neutrals1 = Color("neutrals.1")
            static let text = Color("neutrals.text")
            static let text2 = Color("neutrals.text2")
            static let text3 = Color("neutrals.text3")
            static let text4 = Color("neutrals.text4")
            static let neutrals3 = Color("neutrals.3")
            static let neutrals4 = Color("neutrals.4")
            static let note = Color("neutrals.note")
            static let neutrals6 = Color("neutrals.6")

            static let neutrals7 = Color("neutrals.7")
            static let neutrals8 = Color("neutrals.8")
            static let neutrals9 = Color("neutrals.9")
            static let neutrals10 = Color("neutrals.10")
            static let outline = Color("neutrals.outline")
            static let background = Color("neutrals.background")
        }

        /// These colors depict an emotion of positivity. Generally used across success, complete states.
        enum Success {
            static let success1 = Color("success.1")
            static let success2 = Color("success.2")
            static let success3 = Color("success.3")
            static let success4 = Color("success.4")
            static let success5 = Color("success.5")
        }

        enum Warning {
            static let warning1 = Color("warning.1")
            static let warning2 = Color("warning.2")
            static let warning3 = Color("warning.3")
            static let warning4 = Color("warning.4")
            static let warning5 = Color("warning.5")
            static let warning6 = Color("warning.6")
        }

        enum Shades {
            static let front = Color("shades.front")
            static let shades2 = Color("shades.2")
        }

        enum Button {
            enum Elevated {
                enum Secondary {
                    static let background = Color("button.elevated.secondary.background")
                }

                static let text = Color("button.elevated.text")
            }

            enum Primary {
                static let text = Color("button.primary.text")
            }

            enum Warning {
                static let background = Color("button.warning.background")
            }

            static let light = Color("button.light")
            static let color = Color("button.color")
            static let text = Color("button.text")
            static let send = Color("button.send")
        }

        enum Other {
            static let text1 = Color("other.text1")
            static let text2 = Color("other.text2")
            static let bg1 = Color("other.bg1")
            static let bg2 = Color("other.bg2")
            static let bg3 = Color("other.bg3")
            static let icon1 = Color("other.icon1")
        }

        static let background = Color("Background")
        static let rebackground = Color("Rebacground")
//        static let primary = Color("Primary")
        static let orange = Color("accent.green")
        static let blue = Color("Blue")
        static let yellow = Color("Yellow")

        static let error = Color("Error")
        static let success = Color("Success")
        static let outline = Color("Outline")
        static let disable = Color("Disable")
        static let note = Color("Note")

        static let frontColor = Color("FrontColor")

        static let text = Color("Text")
        static let flow = Color("Flow")

        static let warning2 = Color("Warning2")
        static let warning6 = Color("Warning6")

        static let bgForIcon = Color("BgForIcon")

        static let deepBg = Color("DeepBackground")

        static let neutrals1 = Color("Neutrals1")

        static let stakeMain = Color("other.stakingMain")
    }
}

// MARK: - Color.Flow

extension Color {
    // 2023-08-21
    enum Flow {
        enum Font {
            static let ascend = Color("font.ascend")
            static let descend = Color("font.descend")
            static let inaccessible = Color("font.inaccessible")
        }

        static let accessory = Color("accessory")
        static let blue = Color("tip.blue")
    }
}

// MARK: - Color.Theme

extension Color {
    enum Theme {
        enum Accent {
            static let green = Color("accent.green")
            static let grey = Color("accent.grey")
            static let red = Color("accent.red")
            static let blue = Color("accent.blue")
            static let yellow = Color("accent.yellow")
            static let purple = Color("accent.purple")
            static let orange = Color("accent.orange")
        }

        enum Background {
            /// BG
            static let white = Color("bg.white")
            /// BG2
            static let grey = Color("bg.grey")
            /// BG3
            static let silver = Color("bg.silver")
            static let white8 = Color("bg.white8")
            static let black3 = Color("bg.black3")
            /// White
            static let pureWhite = Color("bg.0")
            /// icon
            static let icon = Color("bg.icon.black")

            static let bg2 = Color("BG.2")
            static let bg3 = Color("BG.3")

            static let fill1 = Color("bg.fill1")
        }

        enum BG {
            static let bg1 = Color("bg1")
            static let bg2 = Color("bg2")
            static let bg3 = Color("bg3")
        }

        enum Line {
            static let line = Color("line.black")
            static let stroke = Color("line.stoke")
        }

        enum Text {
            static let black = Color("text.black")
            static let black1 = Color("text.black.1")
            static let black3 = Color("text.black.3")
            static let black8 = Color("text.black.8")
            static let black6 = Color("text.black.6")
            static let white9 = Color("text.white.9")
            static let text1 = Color("text.1")
            static let text4 = Color("text.4")
        }

        enum Foreground {
            static let black3 = Color("foreground/black3")
            static let white4Text = Color("foreground/white4-text")
        }

        enum Fill {
            static let fill1 = Color("fill.1")
        }

        static let evm = Color("evm")
    }

    enum TabIcon {
        static var unselectedTint: Color { ThemeManager.shared.getUIKitStyle() == .dark ? Color.Theme.Foreground.white4Text : Color.Theme.Foreground.black3 }
    }
}

extension Color {
    /// opacity is 0.16
    func fixedOpacity() -> Color {
        opacity(0.16)
    }
}
