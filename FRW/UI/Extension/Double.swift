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
        roundingMode: NumberFormatter.RoundingMode = .down,
        considerCustomCurrency: Bool = false
    ) -> String {
        return formatCurrency(digits, roundingMode: roundingMode, minimunFractionDigits: digits, considerCustomCurrency: considerCustomCurrency)
    }

    func formatCurrency(_ digits: Int = 3, roundingMode: NumberFormatter.RoundingMode = .down, minimunFractionDigits _: Int = 0, considerCustomCurrency: Bool = false) -> String {
        let value = NSNumber(
            value: considerCustomCurrency ? self * CurrencyCache.cache
                .currentCurrencyRate : self
        ).decimalValue

        let f = NumberFormatter()
        f.maximumFractionDigits = digits
        f.minimumFractionDigits = 0
        f.roundingMode = roundingMode
        return f.string(for: value) ?? "?"
    }

    var decimalValue: Decimal {
        // Deal with precision issue with swift decimal
        Decimal(string: String(self)) ?? Decimal(self)
    }

    var formatDisplayFlowBalance: String {
        formatCurrencyString() + " FLOW"
    }
}
