//
//  UIColor.swift
//  Flow Wallet
//
//  Created by Selina on 13/9/2022.
//

import UIKit

// MARK: - UIColor.LL

extension UIColor {
    enum LL {
        /// The primary color palette is used across all the iteractive elemets such as CTA’s(Call to The Action), links, inputs,active states,etc
        enum Primary {
            static let salmon1 = UIColor(named: "primary.salmon1")!
            static let salmonPrimary = UIColor(named: "primary.salmonPrimary")!
            static let salmon3 = UIColor(named: "primary.salmon3")!
            static let salmon4 = UIColor(named: "primary.salmon4")!
            static let salmon5 = UIColor(named: "primary.salmon5")!
        }

        /// The neutral color palette is used as supportig secondary colors in backgrounds, text colors,  seperators, models, etc
        enum Secondary {
            static let violet1 = UIColor(named: "secondary.violet1")!
            static let violetDiscover = UIColor(named: "secondary.violetDiscover")!
            static let violet3 = UIColor(named: "secondary.violet3")!
            static let violet4 = UIColor(named: "secondary.violet4")!
            static let violet5 = UIColor(named: "secondary.violet5")!

            static let navy1 = UIColor(named: "secondary.navy1")!
            static let navyWallet = UIColor(named: "secondary.navyWallet")!
            static let navy3 = UIColor(named: "secondary.navy3")!
            static let navy4 = UIColor(named: "secondary.navy4")!
            static let navy5 = UIColor(named: "secondary.navy5")!

            static let mango1 = UIColor(named: "secondary.mango1")!
            static let mangoNFT = UIColor(named: "secondary.mangoNFT")!
            static let mango3 = UIColor(named: "secondary.mango3")!
            static let mango4 = UIColor(named: "secondary.mango4")!
            static let mango5 = UIColor(named: "secondary.mango5")!
        }

        /// The neutral color palette is used as supportig secondary colors in backgrounds, text colors,  seperators, models, etc
        enum Neutrals {
            static let neutrals1 = UIColor(named: "neutrals.1")!
            static let text = UIColor(named: "neutrals.text")!
            static let text2 = UIColor(named: "neutrals.text2")!
            static let text3 = UIColor(named: "neutrals.text3")!
            static let text4 = UIColor(named: "neutrals.text4")!
            static let neutrals3 = UIColor(named: "neutrals.3")!
            static let neutrals4 = UIColor(named: "neutrals.4")!
            static let note = UIColor(named: "neutrals.note")!
            static let neutrals6 = UIColor(named: "neutrals.6")!

            static let neutrals7 = UIColor(named: "neutrals.7")!
            static let neutrals8 = UIColor(named: "neutrals.8")!
            static let neutrals9 = UIColor(named: "neutrals.9")!
            static let neutrals10 = UIColor(named: "neutrals.10")!
            static let outline = UIColor(named: "neutrals.outline")!
            static let background = UIColor(named: "neutrals.background")!
        }

        /// These colors depict an emotion of positivity. Generally used across success, complete states.
        enum Success {
            static let success1 = UIColor(named: "success.1")!
            static let success2 = UIColor(named: "success.2")!
            static let success3 = UIColor(named: "success.3")!
            static let success4 = UIColor(named: "success.4")!
            static let success5 = UIColor(named: "success.5")!
        }

        enum Warning {
            static let warning1 = UIColor(named: "warning.1")!
            static let warning2 = UIColor(named: "warning.2")!
            static let warning3 = UIColor(named: "warning.3")!
            static let warning4 = UIColor(named: "warning.4")!
            static let warning5 = UIColor(named: "warning.5")!
            static let warning6 = UIColor(named: "warning.6")!
        }

        enum Shades {
            static let front = UIColor(named: "shades.front")!
            static let shades2 = UIColor(named: "shades.2")!
        }

        enum Button {
            static let light = UIColor(named: "button.light")!
            static let color = UIColor(named: "button.color")!
            static let text = UIColor(named: "button.text")!
        }

        enum Other {
            static let text1 = UIColor(named: "other.text1")!
            static let text2 = UIColor(named: "other.text2")!
            static let bg1 = UIColor(named: "other.bg1")!
            static let bg2 = UIColor(named: "other.bg2")!
            static let bg3 = UIColor(named: "other.bg3")!
            static let icon1 = UIColor(named: "other.icon1")!
        }

        static let background = UIColor(named: "Background")!
        static let rebackground = UIColor(named: "Rebacground")!
//        static let primary = UIColor(named: "Primary")
        static let orange = UIColor(named: "Orange")!
        static let blue = UIColor(named: "Blue")!
        static let yellow = UIColor(named: "Yellow")!

        static let error = UIColor(named: "Error")!
        static let success = UIColor(named: "Success")!
        static let outline = UIColor(named: "Outline")!
        static let disable = UIColor(named: "Disable")!
        static let note = UIColor(named: "Note")!

        static let frontColor = UIColor(named: "FrontColor")!

        static let text = UIColor(named: "Text")!
        static let flow = UIColor(named: "Flow")!

        static let warning2 = UIColor(named: "Warning2")!
        static let warning6 = UIColor(named: "Warning6")!

        static let bgForIcon = UIColor(named: "BgForIcon")!

        static let deepBg = UIColor(named: "DeepBackground")!

        static let neutrals1 = UIColor(named: "Neutrals1")!

        static let stakeMain = UIColor(named: "other.stakingMain")!
    }
}

// MARK: - UIColor.Theme

extension UIColor {
    enum Theme {
        enum Accent {
            static let green = UIColor(named: "accent.green")
            static let grey = UIColor(named: "accent.grey")
            static let red = UIColor(named: "accent.red")
            static let blue = UIColor(named: "accent.blue")
            static let yellow = UIColor(named: "accent.yellow")
            static let purple = UIColor(named: "accent.purple")
            static let orange = UIColor(named: "accent.orange")
        }

        enum Background {
            /// BG
            static let white = UIColor(named: "bg.white")
            /// BG2
            static let grey = UIColor(named: "bg.grey")
            /// BG3
            static let silver = UIColor(named: "bg.silver")
            static let white8 = UIColor(named: "bg.white8")
            static let black3 = UIColor(named: "bg.black3")
            /// White
            static let pureWhite = UIColor(named: "bg.0")
            /// icon
            static let icon = UIColor(named: "bg.icon.black")
        }

        enum Line {
            static let line = UIColor(named: "line.black")
        }

        enum Text {
            static let black = UIColor(named: "text.black")
            static let black1 = UIColor(named: "text.black.1")
            static let black3 = UIColor(named: "text.black.3")
            static let black8 = UIColor(named: "text.black.8")
            static let white9 = UIColor(named: "text.white.9")
        }

        static let evm = UIColor(named: "evm")

        enum Special {
            static let white1 = UIColor(named: "special.white1")
        }
    }
}
