//
//  TextCheckBox.swift
//  FRW
//
//  Created by cat on 2024/9/14.
//

import SwiftUI

struct TextCheckBox: View {
    var text: String
    var callback: (String,Bool)->()
    
    @State private var isCheck: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            // Body2
            Text(text)
                .font(.inter(size: 14))
                .foregroundStyle(Color.Theme.Text.black3)
                .frame(alignment: .topLeading)
            Spacer()
            Image(isCheck ? "icon_check_rounde_1" : "icon_check_rounde_0")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.Theme.Accent.green)
                .frame(width: 20, height: 20)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cornerRadius(16)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .inset(by: 0.5)
            .stroke(Color.Theme.Accent.green, lineWidth: 1)
        )
        .onTapGesture {
            isCheck.toggle()
            callback(text,isCheck)
        }
    }
}

#Preview {
    TextCheckBox(text: "I understand if I lose my recovery phrase, I may not be able to recover my account.") { text,isSelected in
        
    }
}