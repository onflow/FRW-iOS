//
//  BackupListView.swift
//  FRW
//
//  Created by cat on 2023/12/8.
//

import SwiftUI

// MARK: - BackupListView

struct BackupListView: RouteableView {
    @StateObject
    private var viewModel = BackupListViewModel()

    @State
    private var deletePhrase = false

    @State
    private var showBackWarning = false

    private static var notificationToken: AnyObject?

    var title: String {
        "select_backup".localized
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Color.clear
                    .frame(width: 1, height: 24)
                BackupPatternItem(style: .device) { _ in
                    onClickDeviceBackup()
                }
                .visibility(viewModel.hasDeviceBackup ? .gone : .visible)
                .mockPlaceholder(viewModel.isLoading)

                BackupPatternItem(style: .multi) { _ in
                    onClickMultiBackup()
                }
                .visibility(viewModel.hasMultiBackup ? .gone : .visible)
                .mockPlaceholder(viewModel.isLoading)

                BackupPatternItem(style: .phrase) { _ in
                    onClickPhrase()
                }
                .visibility(viewModel.hasPhraseBackup ? .gone : .visible)
                .mockPlaceholder(viewModel.isLoading)

                Divider()
                    .foregroundStyle(.clear)
                    .background(Color.Theme.Line.line)
                    .visibility(
                        (viewModel.hasDeviceBackup && viewModel.hasMultiBackup) ? .gone :
                            .visible
                    )

                deviceListView
                    .visibility(viewModel.hasDeviceBackup ? .visible : .gone)

                multiListView
                    .visibility(viewModel.hasMultiBackup ? .visible : .gone)

                phraseView
                    .visibility(viewModel.hasPhraseBackup ? .visible : .gone)
                Spacer()
            }
            .padding(.horizontal, 18)
        }
        .applyRouteable(self)
        .tracedView(self)
        .backgroundFill(Color.LL.Neutrals.background)
        .halfSheet(showSheet: $viewModel.showRemoveTipView, autoResizing: true, backgroundColor: Color.LL.Neutrals.background) {
            DangerousTipSheetView(
                title: "account_key_revoke_title".localized,
                detail: "account_key_revoke_content".localized,
                buttonTitle: "hold_to_revoke".localized
            ) {
                viewModel.removeBackup()
            } onCancel: {
                viewModel.onCancelTip()
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
        .customAlertView(
            isPresented: $showBackWarning,
            title: "no_backup_warning_title".localized,
            desc: "no_backup_warning_desc".localized,
            buttons: [
                AlertView
                    .ButtonItem(
                        type: .destructive,
                        title: "im_sure".localized,
                        action: {
                            showBackWarning = false
                            Router.pop()
                        }
                    ),
                AlertView
                    .ButtonItem(
                        type: .primaryAction,
                        title: "make_backup".localized,
                        action: {
                            showBackWarning = false
                        }
                    ),
            ],
            useDefaultCancelButton: false
        )
        .onAppear {
            Self.notificationToken = NotificationCenter.default
                .addObserver(forName: NSNotification.Name(backTappedNotification), object: nil, queue: nil) { _ in
                    handleBackButtonAction()
                }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(Self.notificationToken as Any)
        }
    }

    var deviceListView: some View {
        VStack {
            HStack {
                Text("device_backup".localized)
                    .font(.inter(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Button {
                    onAddDevice()
                } label: {
                    Image("icon-wallet-coin-add")
                        .renderingMode(.template)
                        .foregroundColor(.LL.Neutrals.neutrals1)
                }
            }
            .padding(.top, 24)

            if viewModel.current != nil {
                DevicesView.Cell(model: viewModel.current!, isCurrent: true)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("other_device".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black3)
                    Spacer()
                    Button {
                        onShowAll()
                    } label: {
                        Text("view_all".localized)
                            .font(.inter(size: 14, weight: .bold))
                            .foregroundStyle(Color.Theme.Text.black3)
                    }
                    .visibility(viewModel.showAllUITag ? .visible : .gone)
                }

                ForEach(0 ..< viewModel.showDevicesCount, id: \.self) { index in
                    DevicesView.Cell(model: viewModel.deviceList[index])
                }
            }
            .padding(.top, 24)
            .visibility(viewModel.showOther ? .visible : .gone)
        }
    }

    var multiListView: some View {
        VStack {
            HStack {
                Text("multi_backup".localized)
                    .font(.inter(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Button {
                    onAddMulti()
                } label: {
                    Image("icon-wallet-coin-add")
                        .renderingMode(.template)
                        .foregroundColor(.LL.Neutrals.neutrals1)
                }
            }
            .padding(.top, 24)

            ForEach(0 ..< viewModel.backupList.count, id: \.self) { index in
                let item = viewModel.backupList[index]
                BackupListView.BackupFinishItem(item: item, index: index) { _, deleteIndex in
                    deletePhrase = false
                    viewModel.onDelete(index: deleteIndex)
                }
            }
        }
    }

    var phraseView: some View {
        VStack {
            HStack {
                Text("Seed Phrase Backup".localized)
                    .font(.inter(size: 16, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Button {
                    onClickPhrase()
                } label: {
                    Image("icon-wallet-coin-add")
                        .renderingMode(.template)
                        .foregroundColor(.LL.Neutrals.neutrals1)
                }
            }
            .padding(.top, 24)

            ForEach(0 ..< viewModel.phraseList.count, id: \.self) { index in
                let item = viewModel.phraseList[index]
                BackupListView.BackupFinishItem(item: item, index: index) { _, deleteIndex in
                    deletePhrase = true
                    viewModel.onDeletePhrase(index: deleteIndex)
                }
            }
        }
    }

    func onAddDevice() {
        Router.route(to: RouteMap.Profile.devices)
    }

    func onShowAll() {
        viewModel.onShowAllDevices()
    }

    func onClickDeviceBackup() {
        viewModel.onShowDeviceBackup()
    }

    func onClickMultiBackup() {
        if !LocalUserDefaults.shared.clickedWhatIsBack {
            let closure = {
//                Router.pop()
                viewModel.onShowMultiBackup()
            }
            Router.route(to: RouteMap.Backup.introduction(.whatMultiBackup, closure, true))
            LocalUserDefaults.shared.clickedWhatIsBack = true
        } else {
            viewModel.onShowMultiBackup()
        }
    }

    func onClickPhrase() {
        viewModel.onCreatePhrase()
    }

    func onAddMulti() {
        viewModel.onAddMultiBackup()
    }
}

// MARK: - BackupPatternItem

struct BackupPatternItem: View {
    enum ItemStyle {
        case device
        case multi
        case phrase
    }

    var style: ItemStyle = .device
    var onClick: (ItemStyle) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 56)
                Spacer()
                Text("Recommended".localized)
                    .font(.inter(size: 10, weight: .bold))
                    .kerning(0.16)
                    .foregroundStyle(Color.Brain.Primary.main)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.Brain.Primary.main10)
                    .visibility(style != .phrase ? .visible : .gone)
                    .cornerRadius(12)
            }

            Text(title)
                .font(.inter(size: 24, weight: .w700))
                .foregroundStyle(Color.Brain.Text.primary)

            Text(note)
                .font(.inter(size: 14))
                .foregroundStyle(Color.Brain.Text.secondary)
        }
        .padding(24)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [color.opacity(0.2), .white.opacity(0.0)]),
                startPoint: UnitPoint(x: 0.18, y: 0.18),
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.2)]),
                        startPoint: UnitPoint(x: 0.18, y: 0.18),
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(16)
        .onTapGesture {
            onClick(style)
        }
    }

    var iconName: String {
        switch style {
        case .device:
            return "icon.device"
        case .multi:
            return "icon.multi"
        case .phrase:
            return "icon.phrase"
        }
    }

    var title: String {
        switch style {
        case .device:
            return "create_device_backup_title".localized
        case .multi:
            return "create_multi_backup_title".localized
        case .phrase:
            return "create_phrase_backup_title".localized
        }
    }

    var note: String {
        switch style {
        case .device:
            return "create_device_backup_note".localized
        case .multi:
            return "create_multi_backup_note".localized
        case .phrase:
            return "create_phrase_backup_note".localized
        }
    }

    var color: Color {
        switch style {
        case .device:
            return Color.Theme.Accent.green
        case .multi:
            return Color.Theme.Accent.green
        case .phrase:
            return Color.Theme.Accent.green
        }
    }
}

// MARK: - BackupListView.BackupFinishItem

extension BackupListView {
    struct BackupFinishItem: View {
        var item: KeyDeviceModel
        var index: Int
        var onDelete: (MultiBackupType, Int) -> Void

        var body: some View {
            Button {
                Router.route(to: RouteMap.Backup.backupDetail(item))
            } label: {
                HStack(alignment: .top) {
                    Image(iconName())
                        .resizable()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(itemTitle())
                            .font(.inter(size: 16))
                            .foregroundStyle(Color.Theme.Text.black8)
                            .foregroundColor(.black.opacity(0.8))
                        Text(item.device.showApp())
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Theme.Text.black3)
                        Text(item.device.showLocation())
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Theme.Text.black3)
                    }
                    Spacer()
                    HStack {
                        Image("check_fill_1")
                            .frame(width: 16, height: 16)
                    }
                    .frame(width: 16)
                    .frame(minHeight: 0, maxHeight: .infinity)
                }
                .padding(16)
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 96)
                .background(.Theme.Background.grey)
                .cornerRadius(16)
                .onViewSwipe(title: "delete".localized) {
                    onDelete(item.multiBackupType()!, index)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }

        func iconName() -> String {
            if item.backupInfo?.backupType() == .fullWeightSeedPhrase {
                return MultiBackupType.phrase.iconName()
            }
            return item.multiBackupType()?.iconName() ?? ""
        }

        func itemTitle() -> String {
            if item.backupInfo?.backupType() == .fullWeightSeedPhrase {
                return BackupType.fullWeightSeedPhrase.title + " Backup"
            }
            return "\(item.multiBackupType()?.title ?? "") Backup"
        }
    }
}

extension BackupListView {
    func backButtonAction() {
        /** MU: This is a workaround for talking to our view model.  The BackupListView object that backButtonAction
         is called on by the RouteableUIHostingController (its `rootView` property) isn't installed in the view hierarchy when it's called.
         This notification is observed in BackupListViewModel, so that whatever BackupListView is currently in the
         hierarchy will be updated. */
        NotificationCenter.default.post(name: NSNotification.Name(backTappedNotification))
    }

    private func handleBackButtonAction() {
        if viewModel.hasSomeBackup == false {
            showBackWarning = true
        } else {
            Router.pop()
        }
    }
}

private var backTappedNotification: String { "backTappedNotification" }

#Preview {
    BackupListView()
}
