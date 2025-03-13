//
//  SearchBar.swift
//  FRW
//
//  Created by cat on 2024/5/17.
//

import SwiftUI

struct SearchBar: View {
    var placeholder: String
    @Binding var searchText: String
    @Binding var isFocused: Bool
    @FocusState private var isFocusedState: Bool

    var body: some View {
        HStack {
            TextField(placeholder, text: $searchText)
                .font(.inter())
                .foregroundStyle(Color.Theme.Text.black3)
                .submitLabel(.search)
                .focused($isFocusedState)
                .onSubmit {
                    isFocusedState = false
                }
                .onChange(of: isFocusedState) { newValue in
                    isFocused = newValue
                }
                .frame(height: 24)

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        searchText = ""
                    }
                }) {
                    Image("icon_close_circle_gray")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.Theme.Fill.fill1)
        .cornerRadius(16)
    }
}
