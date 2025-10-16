//
//  AlertOverlayView.swift
//  FRW

import SwiftUI

/// Hosts global alert content and actions on top of the current hierarchy.
struct AlertOverlayView: View {
    @ObservedObject var alertCenter: AlertCenter = .shared

    var body: some View {
        Group {
            if let model = alertCenter.model {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if model.actions.contains(where: { $0.id == "cancel" }) {
                                alertCenter.cancel()
                            }
                        }

                    if let custom = model.customContent, !model.wrapsInDefaultContainer {
                        VStack(spacing: 16) {
                            custom

                            actionStack(for: model)
                        }
                        .padding(.horizontal, 28)
                    } else {
                        VStack(spacing: 16) {
                            if let custom = model.customContent {
                                custom
                            } else {
                                if let title = model.title {
                                    Text(title)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                }
                                if let message = model.message {
                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            actionStack(for: model)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
                        )
                        .padding(.horizontal, 28)
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: alertCenter.model != nil)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private func actionStack(for model: AlertModel) -> some View {
        if !model.actions.isEmpty {
            VStack(spacing: 10) {
                ForEach(model.actions) { action in
                    Button {
                        alertCenter.resolve(selection: action.id)
                    } label: {
                        Text(action.title)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(AlertButtonStyle(kind: action.style))
                }
            }
        }
    }
}

struct AlertButtonStyle: SwiftUI.ButtonStyle {
    let kind: AlertButtonStyleKind

    func makeBody(configuration: Configuration) -> some View {
        switch kind {
        case .primary:
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        case .secondary:
            configuration.label
                .font(.body)
                .foregroundColor(Color.accentColor)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        case .destructive:
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
}

