//
//  BackupUploadViewModel.swift
//  FRW
//
//  Created by cat on 2023/12/14.
//

import Foundation
import SwiftUI

enum BackupProcess {
    case idle, upload, regist, finish, end

    var title: String {
        switch self {
        case .idle:
            "backup.status.create".localized
        case .upload:
            "backup.status.upload".localized
        case .regist:
            "backup.status.regist".localized
        case .finish:
            "backup.status.finish".localized
        case .end:
            "backup.status.end".localized
        }
    }

    var icon: String {
        switch self {
        case .finish:
            return "backup.status.finish"
        default:
            return ""
        }
    }

    var next: BackupProcess {
        switch self {
        case .idle:
            return .upload
        case .upload:
            return .regist
        case .regist:
            return .finish
        case .finish:
            return .idle
        case .end:
            return .end
        }
    }
}

// MARK: - BackupUploadViewModel

class BackupUploadViewModel: ObservableObject {
    let items: [MultiBackupType]

    @Published var currentIndex: Int = 0 {
        didSet {
            if currentIndex < items.count {
                currentType = items[currentIndex]
            }
        }
    }

    @Published var process: BackupProcess = .idle
    @Published var hasError: Bool = false
    @Published var mnemonicBlur: Bool = true

    // TODO:
    @Published var checkAllPhrase: Bool = true {
        didSet {
            if checkAllPhrase {
                buttonState = .enabled
            }
        }
    }

    var currentType: MultiBackupType = .google
    init(items: [MultiBackupType]) {
        self.items = items
        currentIndex = 0
        if !self.items.isEmpty {
            currentType = self.items[0]
        }
        if currentType == .phrase {
            buttonState = .disabled
        }
    }

    func reset() {
        hasError = false
        process = .idle
    }

    // MARK: UI element

    var currentIcon: String {
        currentType.iconName()
    }

    var currentTitle: String {
        switch process {
        case .idle:
            return "backup".localized + " \(currentIndex + 1):\(currentType.title) " + "backup".localized
        case .upload:
            return "backup.status.upload".localized
        case .regist:
            return "backup.status.upload".localized
        case .finish:
            return "backup.status.finish.title".localized
        case .end:
            return "backup.status.end.title".localized
        }
    }

    @Published var buttonState: VPrimaryButtonState = .enabled

    var currentNote: String {
        currentType.noteDes
    }

    var currentButton: String {
        if process == .upload, hasError {
            return "upload_again".localized
        }
        return process.title
    }

    func showTimeline() -> Bool {
        return process == .upload || process == .regist
    }

    func learnMore() {
        let closure = {}
        Router.route(to: RouteMap.Backup.introduction(.aboutRecoveryPhrase, closure, true))
    }

    func onClickButton() {
        switch process {
        case .idle:
            Task {
                do {
                    DispatchQueue.main.async {
                        self.buttonState = .loading
                        self.mnemonicBlur = true
                    }
                    try await MultiBackupManager.shared.preLogin(with: currentType)
                    let result = try await MultiBackupManager.shared.registerKeyToChain(on: currentType)
                    if result {
                        toggleProcess(process: .upload)
                        onClickButton()
                    } else {
                        buttonState = .enabled
                        HUD.error(title: "create error on chain")
                    }
                } catch {
                    buttonState = .enabled
                }
            }
        case .upload:
            Task {
                do {
                    DispatchQueue.main.async {
                        self.buttonState = .loading
                    }
                    
                    try await MultiBackupManager.shared.backupKey(on: currentType)
                    toggleProcess(process: .regist)
                    onClickButton()
                } catch {
                    buttonState = .enabled
                    hasError = true
                    log.error(error)
                }
            }
        case .regist:
            Task {
                do {
                    DispatchQueue.main.async {
                        self.buttonState = .loading
                    }
                    
                    try await MultiBackupManager.shared.syncKeyToServer(on: currentType)
                    DispatchQueue.main.async {
                        self.mnemonicBlur = false
                        self.buttonState = .enabled
                    }
                    toggleProcess(process: .finish)
//                    onClickButton()
                    
                } catch {
                    buttonState = .enabled
                    HUD.dismissLoading()
                    log.error(error)
                }
            }
        case .finish:
            let nextIndex = currentIndex + 1
            if items.count <= nextIndex {
                currentIndex = nextIndex
                toggleProcess(process: .end)
            } else {
                currentIndex = nextIndex
                toggleProcess(process: .idle)
            }
        case .end:
            Router.popToRoot()
        }
    }

    func toggleProcess(process: BackupProcess) {
        DispatchQueue.main.async {
            self.hasError = false
            self.process = process
        }
    }
}
