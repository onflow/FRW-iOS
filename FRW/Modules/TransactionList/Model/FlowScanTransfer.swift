//
//  FlowScanTransfer.swift
//  Flow Wallet
//
//  Created by Selina on 9/9/2022.
//

import SwiftUI
import UIKit

// MARK: - FlowScanTransfer.TransferType

extension FlowScanTransfer {
    enum TransferType: Int, Codable {
        case unknown = 0
        case send = 1
        case receive = 2
    }
}

// MARK: - FlowScanTransfer

struct FlowScanTransfer: Codable {
    let additional_message: String?
    let amount: String?
    let error: Bool?
    let image: String?
    let receiver: String?
    let sender: String?
    let status: String?
    let time: String?
    let title: String?
    let token: String?
    let transferType: FlowScanTransfer.TransferType?
    let txid: String?
    let type: Int?
    let contractAddress: String?

    private var isSealed: Bool {
        status?.lowercased() == "Sealed".lowercased() || status?.lowercased() == "success"
    }

    var statusColor: UIColor {
        guard isSealed else {
            return UIColor.LL.Neutrals.text3
        }

        if let error = error, error == true {
            return UIColor.LL.Warning.warning2
        } else {
            return UIColor.LL.Success.success3
        }
    }

    var swiftUIStatusColor: Color {
        guard isSealed else {
            return Color.LL.Neutrals.text3
        }

        if let error = error, error == true {
            return Color.LL.Warning.warning2
        } else {
            return Color.LL.Success.success3
        }
    }

    var statusText: String {
        guard isSealed else {
            return "transaction_pending".localized
        }

        if let error = error, error == true {
            return "transaction_error".localized
        } else {
            return status ?? "transaction_pending".localized
        }
    }

    var transferDesc: String {
        var dateString = ""
        if let time = time, let df = ISO8601Formatter.date(from: time) {
            dateString = df.mmmddString
        }

        var targetStr = ""
        if transferType == TransferType.send {
            targetStr = "transfer_to_x".localized("")
        } else if sender != nil {
            targetStr = "transfer_from_x".localized("")
        }

        return "\(dateString) \(targetStr)"
    }

    var transferAddress: String {
        return (transferType == .send ? receiver : sender) ?? ""
    }

    var amountString: String {
        if let amountString = amount, !amountString.isEmpty {
            return amountString
        } else {
            return "-"
        }
    }

    var iconURL: URL {
        if let logoString = image {
            if logoString.hasSuffix("svg") {
                return logoString.convertedSVGURL() ?? URL(string: placeholder)!
            }

            return URL(string: logoString) ?? URL(string: placeholder)!
        }

        return URL(string: placeholder)!
    }
}
