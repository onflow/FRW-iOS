//
//  InstabugConfig.swift
//  FRW
//
//  Created by cat on 2024/1/12.
//

import Foundation
import Instabug

class InstabugConfig {
    static func start(token: String) {
        Instabug.start(withToken: token, invocationEvents: [.shake, .screenshot])
        Instabug.trackUserSteps = true
        Instabug.setReproStepsFor(.all, with: .enable)
        Instabug.welcomeMessageMode = .disabled
    }
}
