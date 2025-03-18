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
        #expect(0.00000000000000023.formatCurrencyString(digits: 2) == "0.0₁₅23")
        #expect(0.00000023.formatCurrencyString(digits: 2) == "0.0₆23")
        #expect(0.000000000109.formatCurrencyString(digits: 2) == "0.0₉109")
        #expect(0.00000000099.formatCurrencyString(digits: 2) == "0.0₉99")
        #expect(0.000003345.formatCurrencyString(digits: 2) == "0.0₅335")
        #expect(0.0000123.formatCurrencyString(digits: 2) == "0.0₄123")
        #expect(0.0000999.formatCurrencyString(digits: 2) == "0.0₄999")
        #expect(0.0001.formatCurrencyString(digits: 2) == "0")
        #expect(0.001.formatCurrencyString(digits: 2) == "0")
        #expect(1.23.formatCurrencyString(digits: 2) == "1.23")
        #expect(0.000000093948585837.formatCurrencyString(digits: 2) == "0.0₇939")
        #expect(0.formatCurrencyString(digits: 2) == "0")
        #expect(0.000010074.formatCurrencyString(digits: 2) == "0.0₄101")
        #expect(0.000010044.formatCurrencyString(digits: 2) == "0.0₄1")
    }
}
