//
//  SurgePricingAlertView.swift
//  FRW
//
//  Created by Codex on 2024/05/20.
//

import SwiftUI

// MARK: - SurgePricingAlertView

/// A SwiftUI representation of the Surge Pricing confirmation card from design specs.
struct SurgePricingAlertView: View {
  // MARK: Internal

  var feeAmount: String
  var networkLoadDescription: String
  var onAgree: () -> Void
  var onClose: () -> Void

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

  // MARK: Private

  private let cardBackground = Color(hex: "2A2A2A")
  private let alertAccent = Color(hex: "F04438")
  private let warningAccent = Color(hex: "FDB022")

  private var header: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(alertAccent)
          .frame(width: 64, height: 64)

        Image(systemName: "exclamationmark.triangle")
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

        Image("flow")
          .scaledToFit()
          .frame(width: 18, height: 18)
      }

      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 10) {
          Image(systemName: "waveform.path.ecg")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(warningAccent)
          Text("Surge price active")
            .font(.inter(size: 14, weight: .semibold))
            .foregroundColor(warningAccent)
        }
        Text(networkLoadDescription)
          .font(.inter(size: 14, weight: .regular))
          .foregroundColor(warningAccent)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(warningAccent.opacity(0.15))
    )
    .frame(maxWidth: .infinity)
  }

  @State var press = false
  @State var isLoading: Bool = false
  @State var allowEnable: Bool = true
  
  private var agreeButton: some View {
    HStack(spacing: 12) {
      ZStack {
          Circle()
              .stroke(
                  Color.LL.outline.opacity(0.3),
                  lineWidth: 4
              )
          Circle()
              .trim(from: press ? 0.001 : 1, to: 1)
              .stroke(
                Color.LL.outline,
                  style: StrokeStyle(
                      lineWidth: 4,
                      lineCap: .round
                  )
              )
              .rotationEffect(.degrees(-90))
              .rotation3DEffect(Angle(degrees: -180), axis: (x: 0, y: 1, z: 0))
              // Magic HERE !
              .animation(.easeInOut)
              .visible(!isLoading)

          Circle()
              .trim(from: 0, to: 0.3)
              .stroke(
                  Color.LL.outline,
                  style: StrokeStyle(
                      lineWidth: 4,
                      lineCap: .round
                  )
              )
              .rotationEffect(.degrees(-90))
              .rotation3DEffect(Angle(degrees: -180), axis: (x: 0, y: 1, z: 0))
              .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
              .animation(
                  .linear(duration: 1).repeatForever(autoreverses: false),
                  value: isLoading
              )
              .visible(isLoading)
      }
      .frame(width: 16, height: 16)

      Text("Hold to agree to surge pricing")
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .allowsTightening(true)
        .font(.inter(size: 16, weight: .semibold))
        
      Spacer()
    }
    .foregroundColor(.white)
    .padding(.horizontal, 16)
    .frame(height: 52)
    .frame(maxWidth: .infinity)
    .scaleEffect(press ? 0.95 : 1)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(alertAccent)
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.black.opacity(0.6), lineWidth: 1)
        )
    )
    .onLongPressGesture(minimumDuration: 1.2, perform: {
        print("Long pressed!")
        self.press.toggle()
        self.isLoading = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onAgree()
    }, onPressingChanged: { inProgress in
        // TODO: Fix animation time, currently animation and duration time are not matched
        self.press = inProgress
        log.debug("Long pressed \(inProgress)")
    })
    .animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0), value: press)
    .disabled(!allowEnable)
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

// MARK: - SurgePricingAlertView_Previews

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
