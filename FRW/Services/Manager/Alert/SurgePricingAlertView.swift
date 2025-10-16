//
//  SurgePricingAlertView.swift
//  FRW
//
//  Created by Codex on 2024/05/20.
//

import SwiftUI

/// A SwiftUI representation of the Surge Pricing confirmation card from design specs.
struct SurgePricingAlertView: View {
    var feeAmount: String
    var networkLoadDescription: String
    var onAgree: () -> Void
    var onClose: () -> Void

    private let cardBackground = Color(hex: "2A2A2A")
    private let alertAccent = Color(hex: "F04438")
    private let warningAccent = Color(hex: "FDB022")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 16) {
                header
                separator
                surgeInfoCard
                agreeButton
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBackground)
            )
            .accessibilityElement(children: .contain)

            closeButton
                .padding(.trailing, 18)
                .padding(.top, 18)
        }
        .padding(.horizontal, 28)
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(alertAccent)
                    .frame(width: 64, height: 64)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Are you really sure that you want to continue with surge pricing?")
                .font(.inter(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    private var surgeInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Your transaction fee")
                    .font(.inter(size: 14, weight: .regular))
                    .foregroundColor(.white)

                Spacer()

                Text(feeAmount)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(warningAccent)
            }

            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(warningAccent.opacity(0.14))
                        .frame(width: 32, height: 32)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(warningAccent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Surge price active")
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundColor(warningAccent)

                    Text(networkLoadDescription)
                        .font(.inter(size: 14, weight: .regular))
                        .foregroundColor(warningAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(warningAccent.opacity(0.15))
        )
        .frame(maxWidth: .infinity)
    }

    private var agreeButton: some View {
        Button(action: onAgree) {
            HStack(spacing: 12) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 18, weight: .semibold))
                Text("Hold to agree to surge pricing")
                    .font(.inter(size: 16, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(alertAccent)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.6), lineWidth: 1)
                )
        )
        .accessibilityIdentifier("surge-pricing-agree-button")
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

struct SurgePricingAlertView_Previews: PreviewProvider {
    static var previews: some View {
        SurgePricingAlertView(
            feeAmount: "- 500.00",
            networkLoadDescription: "Due to high network activity, transaction fees are elevated, and Flow Wallet is temporarily not paying for your gas. Current network fees are 4× higher than usual.",
            onAgree: {},
            onClose: {}
        )
        .preferredColorScheme(.dark)
        .background(Color.black.opacity(0.9))
    }
}
