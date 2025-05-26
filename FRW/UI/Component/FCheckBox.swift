//
//  FCheckBox.swift
//  FRW
//
//  Created by cat on 5/26/25.
//

import SwiftUI

struct FCheckBox: View {
    @Binding var isSelected: Bool
    var size: CGFloat = 24

    var body: some View {
        Image(isSelected ? .checkBoxSelected : .checkBoxNormal)
            .resizable()
            .frame(width: size, height: size)
    }
}

#Preview {
    Group {
        FCheckBox(isSelected: .constant(true))
        FCheckBox(isSelected: .constant(false))
    }
}
