//
//  CurrencyFormattingTests.swift
//  FRWTests
//
//  Created by Marty Ulrich on 3/14/25.
//

import Testing
@testable import FRW_dev

struct CurrencyFormattingTests {
    
    @Test func testCurrencyFormatting() async throws {
        // Example Usage:
        let values = [
            0.00000000000000023: "0.0₁₅230",
            0.00000023: "0.0₆230",
            0.000000000109: "0.0₉109",
            0.00000000099: "0.0₉990",
            0.000003345: "0.0₅334",
            0.0000123: "0.0₄123",
            0.0000999: "0.0₄999",
            0.0001: "0.0001",
            0.001: "0.001",
            1.23: "1.23",
            0.000000093948585837: "0.0₇939"
        ]
        
        for (number, formattedNumber) in values {
            #expect(number.formattedCurrency()! == formattedNumber)
        }
    }
    
}
