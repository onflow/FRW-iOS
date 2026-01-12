//
//  BackupListViewModel.swift
//  FRW
//
//  Created by cat on 2024/1/6.
//

import Flow
import SwiftUI
import WalletCore

// MARK: - BackupListViewModel

class BackupListViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

//    @Published var muiltList: [BackupListViewModel.Item] = []
    @Published
    var isLoading = true

    @Published
    var backupList: [KeyDeviceModel] = []
    @Published
    var deviceList: [DeviceInfoModel] = []
    @Published
    var phraseList: [KeyDeviceModel] = []
    @Published
    var showCurrent: Bool = false
    @Published
    var showOther: Bool = false
    @Published
    var current: DeviceInfoModel?
    @Published
    var showAllUITag = true
    @Published
    var showAllDevices = false
    @Published
    var showDevicesCount = 0

    @Published
    var showRemoveTipView = false
    var removeIndex: Int?

    func fetchData() {
        Task {
            await MainActor.run {
                self.isLoading = true
            }
            await fetchDeviceBackup()
            await fetchMultiBackup()

            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func onShowMultiBackup() {
        if isValidAddress() {
            Router.route(to: RouteMap.Backup.multiBackup([]))
        }
    }

    func onCreatePhrase() {
        if isValidAddress() {
            Router.route(to: RouteMap.Backup.thingsNeedKnowOnBackup)
        }
    }

    func onShowDeviceBackup() {
        if isValidAddress() {
            Router.route(to: RouteMap.Profile.devices)
        }
    }

    func onAddMultiBackup() {
        let list = currentMultiBackup()
        Router.route(to: RouteMap.Backup.multiBackup(list))
    }

    func onDelete(index: Int) {
        removingPhrase = false
        if showRemoveTipView {
            showRemoveTipView = false
        }

        removeIndex = index
        withAnimation(.easeOut(duration: 0.2)) {
            showRemoveTipView = true
        }
    }

    func onDeletePhrase(index: Int) {
        guard phraseList.count > index else { return }
        removeIndex = index
        let item = phraseList[index]
        if item.pubkey.publicKey == WalletManager.shared.getCurrentPublicKey() {
            HUD.info(title: "account_key_current_tips".localized)
            return
        }
        removingPhrase = true
        if showRemoveTipView {
            showRemoveTipView = false
        }

        removeIndex = index
        withAnimation(.easeOut(duration: 0.2)) {
            showRemoveTipView = true
        }
    }

    func onCancelTip() {
        showRemoveTipView = false
    }

    func removeBackup() {
        if removingPhrase {
            removePhraseBackup()
        } else {
            removeMultiBackup()
        }
    }

    func removeMultiBackup() {
        guard let index = removeIndex, backupList.count > index else { return }
        let item = backupList[index]
        guard let type = item.multiBackupType(),
              let keyIndex = item.backupInfo?.keyIndex else { return }
        if keyIndex == 0 {
            log.error("[Flow] don't revoke key at index 0")
            return
        }
        Task {
            HUD.loading()
            let res = try await AccountKeyManager.revokeKey(at: keyIndex)
            if res {
                try await MultiBackupManager.shared.removeItem(with: type)
                await fetchMultiBackup()
                await MainActor.run {
                    self.showRemoveTipView = false
                }
            }

            HUD.dismissLoading()
        }
    }

    func removePhraseBackup() {
        guard let index = removeIndex, phraseList.count > index else { return }
        let item = phraseList[index]
        guard let keyIndex = item.backupInfo?.keyIndex else { return }
        if keyIndex == 0 {
            log.error("[Flow] don't revoke key at index 0")
            return
        }
        Task {
            HUD.loading()
            let res = try await AccountKeyManager.revokeKey(at: keyIndex)
            if res {
                await fetchMultiBackup()
                showRemoveTipView = false
            }

            HUD.dismissLoading()
        }
    }

    // MARK: Private

    private var removingPhrase = false

    private let showCount = 2

    private func isValidAddress() -> Bool {
        guard WalletManager.shared.getPrimaryWalletAddress() != nil else {
            HUD.error(title: "invalid_address".localized)
            return false
        }
        return true
    }
}

// MARK: - UI

extension BackupListViewModel {
    var hasDeviceBackup: Bool {
        !deviceList.isEmpty || showCurrent
    }

    var hasMultiBackup: Bool {
        !backupList.isEmpty
    }

    var hasPhraseBackup: Bool {
        !phraseList.isEmpty
    }
    
    var hasSomeBackup: Bool {
        //TODO: MU: this one isn't working properly, it reports device backups even if there is none.
//        hasDeviceBackup ||
        hasMultiBackup ||
        hasPhraseBackup
    }
}

extension BackupListViewModel {
    var showAllTagTitle: String {
        showAllDevices ? "view_all".localized : "hide".localized
    }

    func fetchDeviceBackup() async {
        do {
            let result = try await DeviceManager.shared.fetch()
            DispatchQueue.main.async {
                self.deviceList = result.1
                self.current = result.0
                self.showCurrent = (self.current != nil)
                self.showOther = self.deviceList.count > 0
                self.showAllDevices = false
                self.showAllUITag = self.deviceList.count > self.showCount
                self.showDevicesCount = min(self.showCount, self.deviceList.count)
            }
        } catch {
            DispatchQueue.main.async {
                self.deviceList = []
                self.current = nil
                self.showCurrent = false
            }
            log.error("Fetch Devices \(error)")
        }
    }

    func onShowAllDevices() {
        showAllDevices.toggle()
        showDevicesCount = showAllDevices ? deviceList.count : min(showCount, deviceList.count)
    }
}

extension BackupListViewModel {
    func fetchMultiBackup() async {
        func phraseAction(model: KeyDeviceModel) -> Bool {
            if model.pubkey.weight < 1000 {
                return false
            }
            if let info = model.backupInfo, info.backupType() == .fullWeightSeedPhrase {
                return true
            }
            return false
        }

        func multiBackupAction(model: KeyDeviceModel) -> Bool {
            if model.pubkey.weight >= 1000 {
                return false
            }
            if let info = model.backupInfo {
                return info.backupType() != .undefined
            }
            return false
        }

        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        do {
            let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
            let devices: KeyResponse = try await Network.request(FRWAPI.User.keys)
            let deviceList = devices.result?.reversed() ?? []

            let phraseFilterList = filterBackup(
                account: account,
                deviceList: deviceList,
                by: phraseAction
            )
            let multiBackFilterList = filterBackup(
                account: account,
                deviceList: deviceList,
                by: multiBackupAction
            )

            DispatchQueue.main.async {
                self.phraseList = phraseFilterList
                self.backupList = multiBackFilterList
                if multiBackFilterList.count >= 2, let uid = UserManager.shared.activatedUID {
                    MultiAccountStorage.shared.setBackupType(.multi, uid: uid)
                }
            }

        } catch {
            log.error("[backup] fetch multi \(error.localizedDescription)")
        }
    }

    func filterBackup(
        account: Flow.Account,
        deviceList: [KeyDeviceModel],
        by action: (KeyDeviceModel) -> Bool
    ) -> [KeyDeviceModel] {
        let allBackupList = deviceList.filter { model in
            action(model)
        }

        let validBackupList = allBackupList.filter { model in

            let flowAccount = account.keys.last { accountkey in
                model.pubkey.publicKey == accountkey.publicKey.description && !accountkey.revoked
            }
            if flowAccount != nil {
                return true
            }
            return false
        }
        let fixBackupList = validBackupList.map { model in
            var item = model
            let flowAccount = account.keys.first { accountkey in
                model.pubkey.publicKey == accountkey.publicKey.description
            }
            item.backupInfo?.keyIndex = flowAccount?.index
            return item
        }
        return fixBackupList
    }

    func currentMultiBackup() -> [MultiBackupType] {
        backupList.compactMap { $0.multiBackupType() }
    }
}

extension KeyDeviceModel {
    func multiBackupType() -> MultiBackupType? {
        switch backupInfo?.backupType() {
        case .google:
            return MultiBackupType.google
        case .iCloud:
            return MultiBackupType.icloud
        case .manual:
            return MultiBackupType.phrase
        case .passkey:
            return MultiBackupType.passkey
        case .fullWeightSeedPhrase:
            return MultiBackupType.phrase
        case .dropbox:
            return MultiBackupType.dropbox
        default:
            return nil
        }
    }
}
