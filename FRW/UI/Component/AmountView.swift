//
//  AmountView.swift
//  FRW
//
//  Created by cat on 7/3/25.
//

import SwiftUI

struct AmountView: View {
    @Binding var value: Int

    var minValue: Int = 0
    var maxValue: Int = .max
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Button(action: {
                if value > minValue {
                    value -= 1
                    inputText = "\(value)"
                }
            }) {
                Image(systemName: "minus")
                    .font(.inter(size: 24, weight: .bold))
                    .foregroundColor(Color.Brain.Text.primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(value <= minValue)

            Spacer()

            TextField("0", text: $inputText)
                .font(.inter(size: 24, weight: .bold))
                .foregroundColor(Color.Brain.Text.primary)
                .multilineTextAlignment(.center)
                .frame(minWidth: 60)
                .focused($isFocused)
                .onChange(of: inputText) { _ in
                    commitInput()
                }
                .onSubmit {
                    commitInput()
                }
                .onChange(of: isFocused) { focused in
                    if !focused {
                        commitInput()
                    }
                }

            Spacer()

            Button(action: {
                if value < maxValue {
                    value += 1
                    inputText = "\(value)"
                }
            }) {
                Image(systemName: "plus")
                    .font(.inter(size: 24, weight: .bold))
                    .foregroundColor(Color.Brain.Text.primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(value >= maxValue)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.LL.bgForIcon)
        .cornerRadius(12)
        .onAppear {
            inputText = "\(value)"
        }

        .accessibilityElement(children: .contain)
    }

    private func commitInput() {
        let num = Int(inputText) ?? minValue
        let clamped = min(max(num, minValue), maxValue)
        value = clamped
        inputText = "\(clamped)"
    }
}

#if DEBUG
    struct AmountView_Previews: PreviewProvider {
        @State static var value: Int = 0
        static var previews: some View {
            ZStack {
                Color(.sRGB, white: 0.1, opacity: 1).edgesIgnoringSafeArea(.all)
                AmountView(value: $value)
                    .padding()
            }
            .preferredColorScheme(.dark)
        }
    }
#endif
