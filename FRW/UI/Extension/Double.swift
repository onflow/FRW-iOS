//
//  Double.swift
//  Flow Wallet
//
//  Created by Selina on 24/6/2022.
//

import Foundation

extension Double {
    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.maximumFractionDigits = 3
        f.minimumFractionDigits = 0
        return f
    }()

    func formatCurrencyString(
        digits: Int = 2,
        roundingMode: NumberFormatter.RoundingMode = .down,
        considerCustomCurrency: Bool = false
    ) -> String {
        let value = NSNumber(
            value: considerCustomCurrency ? self * CurrencyCache.cache
                .currentCurrencyRate : self
        ).decimalValue

        let f = NumberFormatter()
        f.maximumFractionDigits = digits
        f.minimumFractionDigits = digits
        f.roundingMode = roundingMode
        return f.string(for: value) ?? "?"
    }

    var decimalValue: Decimal {
        // Deal with precision issue with swift decimal
        Decimal(string: String(self)) ?? Decimal(self)
    }
}

extension Int {
    func formattedToSubscriptNotion() -> String {
        let subscriptNumbers: [Character] = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        return String(self).compactMap { String(subscriptNumbers[$0.wholeNumberValue ?? 0]) }.joined()
    }
}

extension Double {
    func formattedCurrency() -> String? {
        let threshold = 0.0001
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        
        if self >= threshold {
            return formatter.string(from: NSNumber(value: self))
        } else {
            let numberString = String(format: "%.18f", self)
            let components = numberString.split(separator: ".")
            guard components.count == 2 else { return nil }
            
            let decimalPart = components[1]
            var leadingZeros = 0
            for char in decimalPart {
                if char == "0" {
                    leadingZeros += 1
                } else {
                    break
                }
            }
            
            let subscriptZeros = leadingZeros.formattedToSubscriptNotion()
            let significantDigits = decimalPart.dropFirst(leadingZeros).prefix(3)
            
            return "0.0\(subscriptZeros)\(significantDigits)"
        }
    }
}
