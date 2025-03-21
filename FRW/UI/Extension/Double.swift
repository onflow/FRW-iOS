//
//  Double.swift
//  Flow Wallet
//
//  Created by Selina on 24/6/2022.
//

import Foundation

extension Double {
    private var maxDigitsAllowed: Int { 4 }

    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 3
        f.minimumFractionDigits = 0
        return f
    }()

    func formatCurrencyString(
        digits: Int = 3,
        roundingMode: NumberFormatter.RoundingMode = .halfUp,
        considerCustomCurrency: Bool = false
    ) -> String {
        let value = considerCustomCurrency ? self * CurrencyCache.cache
            .currentCurrencyRate : self

        if abs(value) < 0.0001, value != 0 {
            return value.formattedCurrency() ?? "?"
        } else {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = min(digits, maxDigitsAllowed)
            formatter.roundingMode = roundingMode
            return formatter.string(from: NSNumber(value: value)) ?? "?"
        }
    }

    var decimalValue: Decimal {
        // Deal with precision issue with swift decimal
        Decimal(string: String(self)) ?? Decimal(self)
    }
}

extension Int {
    func formattedToSubscriptNotion() -> String {
        let subscriptNumbers: [Character] = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        return String(self).compactMap { $0.wholeNumberValue }.map { String(subscriptNumbers[$0]) }.joined()
    }
}

extension Double {
    private func formattedCurrency() -> String? {
        guard self != 0 else { return "0" }

        let threshold = 0.0001

        if abs(self) >= threshold {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 8
            formatter.roundingMode = .halfUp
            return formatter.string(from: NSNumber(value: self))
        }

        let decimalString = String(format: "%.20f", abs(self)).split(separator: ".")[1]
        var leadingZeros = 0

        for char in decimalString {
            guard char == "0" else { break }
            leadingZeros += 1
        }

        var significantDigits = decimalString.dropFirst(leadingZeros)
        let requiredDigits = 4

        while significantDigits.count < requiredDigits {
            significantDigits += "0"
        }

        var roundedNumber = Int(significantDigits.prefix(requiredDigits)) ?? 0
        roundedNumber = (roundedNumber + 5) / 10

        var roundedString = String(roundedNumber)

        while roundedString.last == "0" {
            roundedString.removeLast()
        }

        let subscriptZeros = leadingZeros.formattedToSubscriptNotion()

        return "0.0\(subscriptZeros)\(roundedString)"
    }
}
