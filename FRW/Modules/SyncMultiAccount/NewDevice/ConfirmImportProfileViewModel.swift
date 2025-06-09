//
//  ConfirmImportProfileViewModel.swift
//  FRW
//
//  Created by cat on 6/9/25.
//

import Foundation

class ConfirmImportProfileViewModel: ObservableObject {
    @Published var list: [String]

    init(list: [String]) {
        self.list = list
    }
}
