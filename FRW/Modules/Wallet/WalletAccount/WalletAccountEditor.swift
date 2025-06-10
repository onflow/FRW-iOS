//
//  WalletAccountEditor.swift
//  FRW
//
//  Created by cat on 2024/5/28.
//

import SwiftUI
import SwiftUIX

// MARK: - WalletAccountEditor

struct WalletAccountEditor: View {
    // MARK: Lifecycle

    init(address: String, callback: @escaping () -> Void) {
        let user = WalletManager.shared.walletAccount.readInfo(at: address)
        self.address = address
        current = user
        emojis = WalletUserProfile.Emoji.allCases
        walletName = user.name
        self.callback = callback
    }

    // MARK: Internal

    @State
    var address: String
    var callback: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Edit Wallet")
                .font(.inter(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Text.black8)
                .padding(.top, 24)

            current.emoji.icon(size: 80)

            VStack(spacing: 8) {
                // Calculate number of full rows
                let rows = emojis.count / columns
                let remainingItems = emojis.count % columns

                // Create grid for full rows
                ForEach(0 ..< rows, id: \.self) { rowIndex in
                    HStack(spacing: spacing) {
                        ForEach(0 ..< columns, id: \.self) { columnIndex in
                            let index = rowIndex * columns + columnIndex
                            let emoji = emojis[index]
                            WalletAccountEditor.EmojiView(
                                emoji: emoji,
                                isSelected: self.current.emoji == emoji
                            ) {
                                updateEmoji(emoji: emoji)
                            }
                        }
                    }
                }

                // Create grid for remaining items
                if remainingItems > 0 {
                    HStack(spacing: spacing) {
                        Spacer()
                        ForEach(0 ..< remainingItems, id: \.self) { columnIndex in
                            let index = rows * columns + columnIndex
                            let emoji = emojis[index]
                            WalletAccountEditor.EmojiView(
                                emoji: emoji,
                                isSelected: self.current.emoji == emoji
                            ) {
                                updateEmoji(emoji: emoji)
                            }
                        }
                        Spacer()
                    }
                }
            }

            // Text Field
            TextField("Wallet Name", text: $walletName)
                .font(.inter(size: 14, weight: .semibold))
                .frame(height: 56)
                .padding(.horizontal, 16)
                .border(Color.Theme.Text.black3, cornerRadius: 16)

            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.inter(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.Theme.Text.black8)
                        .background(Color.Theme.Background.grey)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: {
                    onSave()
                }) {
                    Text("Save")
                        .font(.inter(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.Theme.Accent.green)
                        .foregroundColor(.Theme.Text.white9)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 18)
        .background {
            Rectangle()
                .foregroundColor(.clear)
                .background(.Theme.Background.pureWhite)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 24)
        }
        .padding(.horizontal, 18)
    }

    func onCancel() {
        callback()
    }

    func onSave() {
        WalletManager.shared.walletAccount.update(
            at: current.address,
            emoji: current.emoji,
            name: walletName
        )
        onCancel()
    }

    // MARK: Private

    @State
    private var current: WalletUserProfile.User
    @State
    private var walletName: String

    private var emojis: [WalletUserProfile.Emoji]
    private let columns: Int = 7
    private let spacing: CGFloat = 8.0

    private func updateEmoji(emoji: WalletUserProfile.Emoji) {
        if current.emoji.name == walletName {
            walletName = emoji.name
        }
        current.emoji = emoji
        current.name = walletName
    }
}

// MARK: WalletAccountEditor.EmojiView

extension WalletAccountEditor {
    struct EmojiView: View {
        var emoji: WalletUserProfile.Emoji
        var isSelected: Bool
        var action: () -> Void

        var body: some View {
            emoji.icon(size: 32)
                .padding(2)
                .background(isSelected ? Color.Theme.Accent.green : Color.clear)
                .clipShape(Circle())
                .onTapGesture {
                    action()
                }
        }
    }
}

#Preview {
    WalletAccountEditor(address: "0x", callback: {})
        .padding(.horizontal, 16)
}
