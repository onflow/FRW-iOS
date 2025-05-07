//
//  ChildAccountDetailView.swift
//  Flow Wallet
//
//  Created by Selina on 21/6/2023.
//

import Combine
import Kingfisher
import SwiftUI
import SwiftUIX
import UIKit

// MARK: - ChildAccountDetailViewModel

@MainActor
class ChildAccountDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(childAccount: ChildAccount) {
        self.childAccount = childAccount
        fetchCollections()
    }

    // MARK: Internal

    @Published
    var childAccount: ChildAccount
    @Published
    var isPresent: Bool = false
    @Published
    var accessibleItems: [ChildAccountAccessible] = []

    @Published
    var isLoading: Bool = true

    @Published
    var showEmptyCollection: Bool = true

    var accessibleEmptyTitle: String {
        let title = "None Accessible "
        if tabIndex == 0 {
            return title + "collections".localized
        }
        return title + "coins_cap".localized
    }

    func copyAction() {
        UIPasteboard.general.string = childAccount.addr
        HUD.success(title: "copied".localized)
    }

    func unlinkConfirmAction() {
        if !checkChildAcountExist() {
            Router.pop()
            return
        }

        if checkUnlinkingTransactionIsProcessing() {
            return
        }

        if isPresent {
            isPresent = false
        }

        isPresent = true
    }

    func switchTab(index: Int) {
        tabIndex = index
        if index == 0 {
            if var list = collections {
                if !showEmptyCollection {
                    list = list.filter { !$0.isEmpty }
                }
                accessibleItems = list
            } else {
                fetchCollections()
            }
        } else if index == 1 {
            if let list = coins {
                accessibleItems = list
            } else {
                fetchCoins()
            }
        }
    }

    func doUnlinkAction() {
        if isUnlinking {
            return
        }

        isUnlinking = true

        Task {
            do {
                let txId = try await FlowNetwork.unlinkChildAccount(childAccount.addr ?? "")
                let data = try JSONEncoder().encode(self.childAccount)
                let holder = TransactionManager.TransactionHolder(
                    id: txId,
                    type: .unlinkAccount,
                    data: data
                )

                TransactionManager.shared.newTransaction(holder: holder)
                self.isUnlinking = false
                self.isPresent = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Router.pop()
                }
            } catch {
                log.error("unlink failed", context: error)
                DispatchQueue.main.async {
                    self.isUnlinking = false
                    self.isPresent = false
                }

                HUD.error(title: "request_failed".localized)
            }
        }
    }

    @objc
    func editChildAccountAction() {
        Router.route(to: RouteMap.Profile.editChildAccount(childAccount))
    }

    func switchEmptyCollection() {
        showEmptyCollection.toggle()
        switchTab(index: tabIndex)
    }

    // MARK: Private

    private var isUnlinking: Bool = false

    private var tabIndex: Int = 0
    private var collections: [ChildAccountAccessible]?
    private var coins: [ChildAccountAccessible]?

    private func checkChildAcountExist() -> Bool {
        ChildAccountManager.shared.childAccounts.contains(where: { $0.addr == childAccount.addr })
    }

    private func checkUnlinkingTransactionIsProcessing() -> Bool {
        for holder in TransactionManager.shared.holders {
            if holder.type == .unlinkAccount, holder.internalStatus == .pending,
               let holderModel = try? JSONDecoder().decode(ChildAccount.self, from: holder.data),
               holderModel.addr == self.childAccount.addr
            {
                return true
            }
        }

        return false
    }

    private func fetchCollections() {
        accessibleItems = [FlowModel.NFTCollection].mock(1)
        isLoading = true

        Task {
            guard let parent = WalletManager.shared.getPrimaryWalletAddress(),
                  let child = self.childAccount.addr
            else {
                await MainActor.run {
                    self.collections = []
                    self.accessibleItems = []
                }
                return
            }

            do {
                let result = try await FlowNetwork.fetchAccessibleCollection(
                    parent: parent,
                    child: child
                )
                let response: [NFTCollection] = try await Network
                    .request(FRWAPI.NFT.userCollection(
                        child,
                        .cadence
                    ))
                let collectionList = response

                let resultList: [NFTCollection] = result.compactMap { item in
                    if let contractName = item.split(separator: ".")[safe: 2] {
                        if let model = NFTCatalogCache.cache.find(by: String(contractName)) {
                            return NFTCollection(collection: model.collection, count: 0)
                        }
                    }
                    return nil
                }

                let tmpList = resultList.map { model in
                    var model = model
                    let collectionItem = collectionList.first(where: { item in
                        item.maskContractName == model.maskContractName && item.maskAddress == model
                            .maskAddress
                    })
                    if let item = collectionItem {
                        model.ids = item.ids
                        model.count = item.ids?.count ?? 0
                    }
                    return model
                }
                let res = tmpList.sorted { $0.count > $1.count }

                self.collections = res
                self.accessibleItems = self.collections ?? []
                self.isLoading = false
            } catch {
                log.error("\(error)")
                print("Error")
            }
        }
    }

    private func fetchCoins() {
        accessibleItems = [FlowModel.TokenInfo].mock(1)
        isLoading = true

        Task {
            guard let parent = WalletManager.shared.getPrimaryWalletAddress(),
                  let child = childAccount.addr
            else {
                self.coins = []
                self.accessibleItems = []
                return
            }

            let result = try await FlowNetwork.fetchAccessibleFT(parent: parent, child: child)
            self.coins = result
            self.accessibleItems = result
            self.isLoading = false
        }
    }
}

// MARK: - ChildAccountDetailView

struct ChildAccountDetailView: RouteableView {
    // MARK: Lifecycle

    init(vm: ChildAccountDetailViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    @StateObject
    var vm: ChildAccountDetailViewModel

    var title: String {
        "linked_account".localized
    }

    var body: some View {
        VStack(spacing: 20) {
            contentView
            unlinkBtn
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .halfSheet(
            showSheet: $vm.isPresent,
            autoResizing: true,
            backgroundColor: Color.LL.Neutrals.background
        ) {
            UnlinkConfirmView()
                .environmentObject(vm)
        }
    }

    var unlinkBtn: some View {
        Button {
            vm.unlinkConfirmAction()
        } label: {
            Text("unlink_account".localized)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.LL.Warning.warning2)
                .cornerRadius(16)
                .foregroundColor(Color.white)
                .font(.inter(size: 16, weight: .semibold))
        }
    }

    var contentView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                KFImage.url(URL(string: vm.childAccount.icon))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(50)
                    .padding(.vertical, 20)

                Text(vm.childAccount.aName)
                    .foregroundColor(Color.LL.Neutrals.text)
                    .font(.inter(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                addressContentView
                    .padding(.bottom, bottomPadding)

                descContentView
                    .padding(.bottom, bottomPadding)
                accessibleView
                    .padding(.bottom, bottomPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    var addressContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("address".localized)
                .foregroundColor(Color.LL.Neutrals.text4)
                .font(.inter(size: 16, weight: .semibold))

            HStack {
                Text(vm.childAccount.addr ?? "")
                    .foregroundColor(Color.LL.Neutrals.text)
                    .font(.inter(size: 16, weight: .medium))

                Spacer()

                Button {
                    vm.copyAction()
                } label: {
                    Image("icon-copy")
                        .frame(width: 56, height: 48)
                        .contentShape(Rectangle())
                }
            }
            .frame(height: 48)
            .padding(.leading, 15)
            .background(Color.LL.Neutrals.neutrals6)
            .cornerRadius(16)
        }
    }

    var descContentView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("description".localized)
                .foregroundColor(Color.LL.Neutrals.text4)
                .font(.inter(size: 16, weight: .semibold))

            Text(vm.childAccount.description ?? "")
                .foregroundColor(Color.LL.Neutrals.text2)
                .font(.inter(size: 14, weight: .medium))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var accessibleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("accessible_cap".localized)
                    .foregroundColor(Color.LL.Neutrals.text4)
                    .font(.inter(size: 16, weight: .semibold))

                Spacer()

                HStack(spacing: 6) {
                    Spacer()
//                    Image(vm.showEmptyCollection ? "icon-empty-mark" : "icon-right-mark")
//                        .resizable()
//                        .frame(width: 11, height: 11)
                    Text("view_empty".localized)
                        .font(.inter(size: 14, weight: .w600))
                        .foregroundStyle(
                            Color.LL.Neutrals.text4
                        )
                    Toggle(isOn: $vm.showEmptyCollection) {}
                        .tint(.LL.Primary.salmonPrimary)
                        .onChange(of: vm.showEmptyCollection) { _ in
                            vm.switchEmptyCollection()
                        }
                        .labelsHidden()
                        .contentShape(Rectangle())
                    Spacer()
                        .frame(width: 2)
                }
            }
            .padding(.bottom, 8)

            LLSegmenControl(titles: ["collections".localized, "coins_cap".localized]) { idx in
                vm.switchTab(index: idx)
            }
            if vm.accessibleItems.isEmpty, !vm.isLoading {
                emptyAccessibleView
            }
            ForEach(vm.accessibleItems.indices, id: \.self) { idx in
                AccessibleItemView(item: vm.accessibleItems[idx]) { item in
                    if let collectionInfo = item as? NFTCollection, let addr = vm.childAccount.addr,
                       let pathId = collectionInfo.collection.path?.storagePathId(),
                       !collectionInfo.isEmpty
                    {
                        Router.route(to: RouteMap.NFT.collectionDetail(
                            addr,
                            pathId,
                            vm.childAccount
                        ))
                    }
                }
            }
            .mockPlaceholder(vm.isLoading)
        }
    }

    var emptyAccessibleView: some View {
        HStack {
            Text(vm.accessibleEmptyTitle)
                .font(Font.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.LL.Neutrals.text4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .padding(.horizontal, 18)
        .background(.LL.Neutrals.neutrals6)
        .cornerRadius(16, style: .continuous)
    }

    func configNavigationItem(_ navigationItem: UINavigationItem) {
        let editButton = UIBarButtonItem(
            image: UIImage(named: "icon-edit-child-account"),
            style: .plain,
            target: vm,
            action: #selector(ChildAccountDetailViewModel.editChildAccountAction)
        )
        editButton.tintColor = UIColor(named: "button.color")
        navigationItem.rightBarButtonItem = editButton
    }

    // MARK: Private

    private var bottomPadding: CGFloat {
        24
    }
}

extension ChildAccountDetailView {
    struct Indicator: View {
        var styleColor: Color {
            Color(hex: "#CCCCCC")
        }

        var barColors: [Color] {
            [.clear, styleColor]
        }

        var body: some View {
            HStack(spacing: 0) {
                dotView
                lineView(start: .leading, end: .trailing)
                shortLine
                    .padding(.horizontal, 4)

                Image("unlink-indicator")
                    .renderingMode(.template)
                    .foregroundColor(styleColor)

                shortLine
                    .padding(.horizontal, 4)
                lineView(start: .trailing, end: .leading)
                dotView
            }
            .frame(width: 114, height: 8)
        }

        var shortLine: some View {
            Rectangle()
                .frame(width: 4, height: 2)
                .foregroundColor(styleColor)
        }

        var dotView: some View {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(styleColor)
        }

        func lineView(start: UnitPoint, end: UnitPoint) -> some View {
            LinearGradient(colors: barColors, startPoint: start, endPoint: end)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
        }
    }

    struct ChildAccountTargetView: View {
        @State
        var iconURL: String
        @State
        var name: String
        @State
        var address: String

        var body: some View {
            VStack(spacing: 8) {
                KFImage.url(URL(string: iconURL))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)

                Text(name)
                    .font(.inter(size: 10, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .lineLimit(1)

                Text(address)
                    .font(.inter(size: 10, weight: .medium))
                    .foregroundColor(.LL.Neutrals.note)
                    .lineLimit(1)
            }
            .frame(width: 120)
        }
    }

    struct UnlinkConfirmView: View {
        // MARK: Internal

        var body: some View {
            VStack {
                SheetHeaderView(title: "unlink_confirmation".localized)

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        fromToView
                        ChildAccountDetailView.Indicator()
                            .padding(.bottom, 38)
                    }
                    .background(Color.LL.background)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), x: 0, y: 4, blur: 16)
                    .padding(.horizontal, 18)

                    descView
                        .padding(.top, -20)
                        .padding(.horizontal, 28)
                        .zIndex(-1)

                    Spacer()

                    confirmButton
                        .padding(.bottom, 10)
                        .padding(.horizontal, 28)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }

        var fromToView: some View {
            HStack {
                ChildAccountTargetView(
                    iconURL: vm.childAccount.icon,
                    name: vm.childAccount.aName,
                    address: vm.childAccount.addr ?? ""
                )

                Spacer()

                ChildAccountTargetView(
                    iconURL: UserManager.shared.userInfo?.avatar.convertedAvatarString() ?? "",
                    name: UserManager.shared.userInfo?.meowDomain ?? "",
                    address: WalletManager.shared.getPrimaryWalletAddress() ?? "0x"
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
        }

        var descView: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("unlink_account".localized.uppercased())
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text4)

                Text("unlink_account_desc_x".localized(vm.childAccount.aName))
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 44)
            .padding(.bottom, 34)
            .background(Color.LL.Neutrals.neutrals6)
            .cornerRadius(16)
        }

        var confirmButton: some View {
            WalletSendButtonView(
                allowEnable: .constant(true),
                buttonText: "hold_to_unlink".localized
            ) {
                vm.doUnlinkAction()
            }
        }

        // MARK: Private

        @EnvironmentObject
        private var vm: ChildAccountDetailViewModel
    }
}

extension ChildAccountManager {}

// MARK: - ChildAccountDetailView.AccessibleItemView

private extension ChildAccountDetailView {
    struct AccessibleItemView: View {
        var item: ChildAccountAccessible
        var onClick: ((_ item: ChildAccountAccessible) -> Void)?

        var body: some View {
            HStack(spacing: 16) {
                KFImage.url(URL(string: item.img))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .cornerRadius(12, style: .continuous)

                Text(item.title)
                    .foregroundColor(Color.LL.Neutrals.text)
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(2)

                Spacer()

                Text(item.subtitle)
                    .foregroundColor(Color.LL.Neutrals.text3)
                    .font(.inter(size: 12))
                Image("icon-black-right-arrow")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Neutrals.text2)
                    .visibility(item.isShowNext ? .visible : .gone)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .padding(.horizontal, 16)
            .background(Color.LL.background)
            .cornerRadius(16, style: .circular)
            .onTapGesture {
                if let onClick = onClick {
                    onClick(item)
                }
            }
        }
    }
}

// MARK: - ChildAccountAccessible

protocol ChildAccountAccessible {
    var img: String { get }
    var title: String { get }
    var subtitle: String { get }
    var isShowNext: Bool { get }
    var id: String { get }
    var count: Int { get }
}

extension ChildAccountAccessible {
    var count: Int {
        0
    }

    var isEmpty: Bool { count == 0 }
}

// MARK: - NFTCollection + ChildAccountAccessible

extension NFTCollection: ChildAccountAccessible {
    var img: String {
        collection.logoURL.absoluteString
    }

    var title: String {
        collection.name ?? ""
    }

    var subtitle: String {
        guard let count = ids?.count else {
            return ""
        }
        return "\(count) Collectible"
    }

    var isShowNext: Bool {
        (ids?.count ?? 0) > 0
    }

    var id: String {
        collection.id
    }
}

// MARK: - FlowModel.NFTCollection + ChildAccountAccessible

extension FlowModel.NFTCollection: ChildAccountAccessible {
    var img: String {
        display?.squareImage ?? AppPlaceholder.image
    }

    var title: String {
        if let name = display?.name {
            return name
        }
        if let name2 = id.split(separator: ".")[safe: 2] {
            return String(name2)
        }

        return "Unrecognised Collection"
    }

    var subtitle: String {
        "\(idList.count) Collectible"
    }

    var isShowNext: Bool {
        !idList.isEmpty
    }

    var fromPath: String {
        guard let path = path else { return "" }
        return String(path.split(separator: "/").last ?? "")
    }

    var count: Int {
        idList.count
    }

    func toCollectionModel() -> CollectionItem {
        let item = CollectionItem()
        item.name = title
        item.count = idList.count
        item.collection = NFTCollectionInfo(
            id: id,
            name: title,
            contractName: title,
            address: "",
            logo: img,
            banner: "",
            officialWebsite: "",
            description: "",
            path: ContractPath(
                storagePath: "",
                publicPath: "",
                privatePath: nil,
                publicCollectionName: "",
                publicType: "",
                privateType: ""
            ),
            evmAddress: nil,
            flowIdentifier: nil
        )
        item.isEnd = true
        return item
    }
}

// MARK: - FlowModel.TokenInfo + ChildAccountAccessible

extension FlowModel.TokenInfo: ChildAccountAccessible {
    var img: String {
        if let model = theToken {
            let url = model.iconURL.absoluteString
            return url
        }
        return AppPlaceholder.image
    }

    var title: String {
        guard let model = theToken else {
            let title = id.split(separator: ".")[safe: 2] ?? "Unrecognised Coin"
            return String(title)
        }

        if !model.name.isEmpty {
            return model.name
        }
        return model.contractName
    }

    var subtitle: String {
        if let model = theToken {
            let sub = model.symbol?.uppercased() ?? "?"
            return "\(balance) \(sub)"
        }
        return "\(balance) ?"
    }

    var isShowNext: Bool {
        false
    }

    private var theToken: TokenModel? {
        let contractName = id.split(separator: ".")[safe: 2] ?? "empty"
        let address = id.split(separator: ".")[safe: 1] ?? "empty_error"
        return WalletManager.shared.activatedCoins.filter { $0.contractName == contractName && ($0.getAddress() ?? "") == address }.first
    }
}
