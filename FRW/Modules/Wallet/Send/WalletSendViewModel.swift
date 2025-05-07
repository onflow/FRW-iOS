//
//  WalletSendViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 8/7/2022.
//

import Flow
import Foundation
import SwiftUI
import SwiftUIPager
import Web3Core

import Combine

extension WalletSendView {
    enum TabType: Int, CaseIterable {
        case accounts
        case recent
        case addressBook
    }

    enum ViewStatus {
        case normal
        case prepareSearching
        case searching
        case searchResult
        case error
    }

    enum ErrorType {
        case none
        case notFound
        case failed

        // MARK: Internal

        var desc: String {
            switch self {
            case .none:
                return ""
            case .notFound:
                return "no_account_found_msg".localized
            case .failed:
                return "search_failed_msg".localized
            }
        }
    }

    struct SearchSection: VSectionListSectionViewModelable {
        let id: UUID = .init()
        let title: String
        let rows: [Contact]
    }
}

// MARK: - WalletSendViewModel

class WalletSendViewModel: ObservableObject {
    // MARK: Lifecycle

    init(selectCallback: WalletSendView.WalletSendViewSelectTargetCallback? = nil) {
        self.selectCallback = selectCallback

        addressBookVM.injectSelectAction = { [weak self] contact in
            guard let self = self else {
                return
            }

            self.sendToTargetAction(target: contact)
        }

        RecentListCache.cache.$list.sink { list in
            DispatchQueue.main.async {
                self.recentList = list
            }
        }.store(in: &cancelSets)

        var addresList: [String] = []
        if let primaryAddr = WalletManager.shared.getPrimaryWalletAddress() {
            addresList.append(primaryAddr)
        }

        for address in addresList {
            let user = WalletManager.shared.walletAccount.readInfo(at: address)
            let contract = Contact(
                address: address,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: nil,
                user: user
            )
            ownAccountList.append(contract)
        }

        if WalletManager.shared.isSelectedEVMAccount == false,
           let emvAddr = EVMAccountManager.shared.accounts.first?.showAddress {}

        for account in EVMAccountManager.shared.accounts {
            let evmAddr = account.showAddress
            let user = WalletManager.shared.walletAccount.readInfo(at: evmAddr)
            let contract = Contact(
                address: evmAddr,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: nil,
                user: user
            )
            linkedWalletList.append(contract)
        }

        for account in ChildAccountManager.shared.childAccounts {
            let contact = Contact(
                address: account.showAddress,
                avatar: account.showIcon,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.aName
            )
            linkedWalletList.append(contact)
        }
    }

    // MARK: Internal

    @Published
    var status: WalletSendView.ViewStatus = .normal
    @Published
    var errorType: WalletSendView.ErrorType = .none

    @Published
    var tabType: WalletSendView.TabType = .accounts
    @Published
    var searchText: String = ""
    @Published
    var page: Page = .first()

    @Published
    var recentList: [Contact] = []
    @Published
    var linkedWalletList: [Contact] = []
    @Published
    var ownAccountList: [Contact] = []
    let addressBookVM = AddressBookView.AddressBookViewModel()

    @Published
    var localSearchResults: [WalletSendView.SearchSection] = []
    @Published
    var serverSearchList: [Contact]?
    @Published
    var findSearchList: [Contact]?
    @Published
    var flownsSearchList: [Contact]?
    @Published
    var meowSearchList: [Contact]?

    var remoteSearchResults: [WalletSendView.SearchSection] {
        var sections = [WalletSendView.SearchSection]()
        if let serverSearchList = serverSearchList, !serverSearchList.isEmpty {
            sections.append(WalletSendView.SearchSection(
                title: "lilico_user".localized,
                rows: serverSearchList
            ))
        }

        if let findSearchList = findSearchList, !findSearchList.isEmpty {
            sections.append(WalletSendView.SearchSection(
                title: ".find".localized,
                rows: findSearchList
            ))
        }

        if let flownsSearchList = flownsSearchList, !flownsSearchList.isEmpty {
            sections.append(WalletSendView.SearchSection(
                title: ".flowns".localized,
                rows: flownsSearchList
            ))
        }

        if let meowSearchList = meowSearchList, !meowSearchList.isEmpty {
            sections.append(WalletSendView.SearchSection(
                title: ".meow".localized,
                rows: meowSearchList
            ))
        }

        return sections
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()

    private var selectCallback: WalletSendView.WalletSendViewSelectTargetCallback?
}

// MARK: - Search

extension WalletSendViewModel {
    private func searchLocal() {
        let text = searchText.trim()
        localSearchResults = addressBookVM.searchLocal(text: text)
    }

    private func searchRemote(domains: [Contact.DomainType] = Contact.DomainType.allCases) {
        searchFromServer()

        for domain in domains {
            switch domain {
            case .meow:
                searchFromMeow()
            case .flowns:
                searchFromFlowns()
            case .find:
                searchFromFind()
            default:
                break
            }
        }
    }

    private func searchFromServer() {
        let trimedText = searchText.trim()

        Task {
            do {
                let response: UserSearchResponse = try await Network
                    .request(FRWAPI.User.search(trimedText))
                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    var results = [Contact]()
                    let users = response.users ?? []
                    for userInfo in users {
                        results.append(userInfo.toContact())
                    }

                    self.serverSearchList = results
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            } catch {
                debugPrint("WalletSendViewModel -> searchFromServer failed: \(error)")

                if trimedText != self.searchText.trim() {
                    return
                }

                HUD.error(title: "search_failed_msg".localized)

                DispatchQueue.main.async {
                    self.serverSearchList = []
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            }
        }
    }

    private func searchFromFind() {
        let trimedText = searchText.trim()

        Task {
            do {
                let address = try await FlowNetwork
                    .queryAddressByDomainFind(domain: trimedText.lowercased().removeSuffix(".find"))
                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    let contact = Contact(
                        address: address,
                        avatar: nil,
                        contactName: trimedText,
                        contactType: .domain,
                        domain: Contact.Domain(
                            domainType: .find,
                            value: trimedText
                        ),
                        id: UUID().hashValue,
                        username: nil
                    )

                    self.findSearchList = [contact]
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            } catch {
                debugPrint("WalletSendViewModel -> searchFromFind failed: \(error)")

                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    self.findSearchList = []
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            }
        }
    }

    private func searchFromFlowns() {
        let trimedText = searchText.trim()

        Task {
            do {
                let address = try await FlowNetwork
                    .queryAddressByDomainFlowns(domain: trimedText.removeSuffix(".fn"))
                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    let contact = Contact(
                        address: address,
                        avatar: nil,
                        contactName: trimedText,
                        contactType: .domain,
                        domain: Contact.Domain(
                            domainType: .flowns,
                            value: trimedText
                        ),
                        id: UUID().hashValue,
                        username: nil
                    )

                    self.flownsSearchList = [contact]
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            } catch {
                debugPrint("WalletSendViewModel -> searchFlowns failed: \(error)")

                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    self.flownsSearchList = []
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            }
        }
    }

    private func searchFromMeow() {
        let trimedText = searchText.trim()

        Task {
            do {
                let address = try await FlowNetwork.queryAddressByDomainFlowns(
                    domain: trimedText.removeSuffix(".meow"),
                    root: Contact.DomainType.meow.domain
                )
                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    let contact = Contact(
                        address: address,
                        avatar: nil,
                        contactName: trimedText,
                        contactType: .domain,
                        domain: Contact.Domain(
                            domainType: .meow,
                            value: trimedText
                        ),
                        id: UUID().hashValue,
                        username: nil
                    )

                    self.meowSearchList = [contact]
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            } catch {
                debugPrint("WalletSendViewModel -> searchFlowns failed: \(error)")

                if trimedText != self.searchText.trim() {
                    return
                }

                DispatchQueue.main.async {
                    self.meowSearchList = []
                    self.refreshCurrentSearchingStatusAfterPerSearchComplete()
                }
            }
        }
    }

    private func clearRemoteSearch() {
        serverSearchList = nil
        findSearchList = nil
        flownsSearchList = nil
    }

    /// refresh searching status by search result
    private func refreshCurrentSearchingStatusAfterPerSearchComplete() {
        if let serverSearchList = serverSearchList, serverSearchList.isEmpty,
           let findSearchList = findSearchList, findSearchList.isEmpty,
           let flownsSearchList = flownsSearchList, flownsSearchList.isEmpty
        {
            errorType = .notFound
            status = .error
            return
        }

        status = .searchResult
    }
}

// MARK: - Action

extension WalletSendViewModel {
    func sendToTargetAction(target: Contact) {
        if let callback = selectCallback {
            callback(target)
            return
        }
        guard let token = WalletManager.shared.flowToken else {
            return
        }
        // TODO: - FIX ME
//        let vaultIdentifier = LocalUserDefaults.shared.recentToken
//        guard let token = WalletManager.shared.getToken(by: vaultIdentifier) else {
//            return
//        }

        Router.route(to: RouteMap.Wallet.sendAmount(target, token))
    }

    func searchTextDidChangeAction(text: String) {
        let trimedText = text.trim()

        if trimedText.isFlowOrEVMAddress {
            if let callback = selectCallback {
                let target = Contact(
                    address: trimedText,
                    avatar: nil,
                    contactName: trimedText,
                    contactType: .external,
                    domain: nil,
                    id: UUID().hashValue,
                    username: nil
                )
                callback(target)
                return
            }

            sendToAddressAction(trimedText)
            return
        }

        if trimedText.isEmpty {
            status = .normal
            return
        }

        let domains = needAutoSearch(text: trimedText)
        if !domains.isEmpty {
            searchCommitAction(domains: domains)
            return
        }

        status = .prepareSearching
        clearRemoteSearch()
        searchLocal()
    }

    private func sendToAddressAction(_ address: String) {
        let contact = Contact(
            address: address,
            avatar: nil,
            contactName: address,
            contactType: .external,
            domain: nil,
            id: UUID().hashValue,
            username: nil
        )
        let vaultIdentifier = LocalUserDefaults.shared.recentToken
        guard let token = WalletManager.shared.getToken(by: vaultIdentifier) else {
            return
        }
        Router.route(to: RouteMap.Wallet.sendAmount(contact, token))
    }

    func searchCommitAction(domains: [Contact.DomainType] = Contact.DomainType.allCases) {
        let trimedText = searchText.trim()

        if trimedText.isEmpty {
            status = .normal
            return
        }

        status = .searching
        clearRemoteSearch()
        searchRemote(domains: domains)
    }

    func changeTabTypeAction(type: WalletSendView.TabType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            tabType = type
            page.update(.new(index: type.rawValue))
        }
    }

    func scan() {
        Router.route(to: RouteMap.Wallet.scan { data, vc in
            switch data {
            case let .flowWallet(address):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                    self?.searchText = address
                    self?.searchRemote()
                })
            case let .ethWallet(address):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                    self?.searchText = address
                    self?.searchRemote()
                })
            default:
                break
            }
        })
    }

    func addContactAction(contact: Contact) {
        let errorAction = {
            DispatchQueue.main.async {
                HUD.dismissLoading()
                HUD.error(title: "request_failed".localized)
            }
        }

        guard let contactName = contact.contactName?.trim(), !contactName.isEmpty,
              let address = contact.address?.trim(), !address.isEmpty
        else {
            errorAction()
            return
        }

        HUD.loading("saving".localized)

        Task {
            do {
                let request = AddressBookAddRequest(
                    contactName: contactName,
                    address: address,
                    domain: contact.domain?.value ?? "",
                    domainType: contact.domain?
                        .domainType ?? .unknown,
                    username: contact.username ?? ""
                )
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.AddressBook.addExternal(request))

                if response.httpCode != 200 {
                    errorAction()
                    return
                }

                DispatchQueue.main.async {
                    HUD.dismissLoading()
                    self.addressBookVM.appendNewContact(contact: contact)
                    HUD.success(title: "contact_added".localized)
                    self.status = .searchResult
                }
            } catch {
                errorAction()
            }
        }
    }
}

// MARK: - Helper

extension WalletSendViewModel {
    private func needAutoSearch(text: String) -> [Contact.DomainType] {
        let trimedText = text.trim()

        if trimedText.contains(" ") {
            return []
        }

        let allSuffix = Contact.DomainType.allCases
        return allSuffix.filter { trimedText.hasSuffix("." + $0.domain) }
    }
}
