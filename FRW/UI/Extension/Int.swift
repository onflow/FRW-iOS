//
//  Int.swift
//  FRW
//
//  Created by cat on 5/21/25.
//

import Foundation

extension Int {
    func digitalSubscript() -> String {
        let subscriptNumbers: [Character] = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        return String(self).compactMap { $0.wholeNumberValue }.map { String(subscriptNumbers[$0]) }.joined()
    }
}
