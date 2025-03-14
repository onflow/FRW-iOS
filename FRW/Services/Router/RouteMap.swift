//
//  RouteMap.swift
//  Flow Wallet
//
//  Created by Selina on 25/7/2022.
//

import Flow
import SafariServices
import SwiftUI

import UIKit

// MARK: - RouteMap

enum RouteMap {}

typealias EmptyClosure = () -> Void
typealias SwitchNetworkClosure = (FlowNetworkType) -> Void
typealias BoolClosure = (Bool) -> Void

// MARK: - RouteMap.RestoreLogin

extension RouteMap {
    enum RestoreLogin {
        case root
        case restoreManual
        case chooseAccount([BackupManager.DriveItem], BackupManager.BackupType)
        case enterRestorePwd(BackupManager.DriveItem, BackupManager.BackupType)
        case syncQC
        case syncAccount(SyncInfo.User)
        case syncDevice(SyncAddDeviceViewModel)

        case restoreList
        case restoreMulti
        case multiConnect([MultiBackupType])
        case multiAccount([[MultiBackupManager.StoreItem]])
        case inputMnemonic((String) -> Void)

        case createProfile(CreateProfileWaitingViewModel)
        case createProfileSuccess(CreateProfileWaitingViewModel)
        case restoreErrorView(RestoreErrorView.RestoreError)

        case keystore
        case importAddress(ImportAccountsViewModel)
        case importUserName(ImportUserNameViewModel)
        case privateKey
        case seedPhrase
    }
}

// MARK: - RouteMap.RestoreLogin + RouterTarget

extension RouteMap.RestoreLogin: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .root:
            navi.push(content: RestoreWalletView())
        case .restoreManual:
            navi.push(content: InputMnemonicView())
        case let .chooseAccount(items, backupType):
            navi.push(content: ChooseAccountView(driveItems: items, backupType: backupType))
        case let .enterRestorePwd(item, backupType):
            navi.push(content: EnterRestorePasswordView(driveItem: item, backupType: backupType))
        case .syncQC:
            navi.push(content: SyncAccountView())
        case let .syncAccount(info):
            navi.push(content: SyncConfirmView(user: info))
        case let .syncDevice(vm):
            let vc = CustomHostingController(rootView: SyncAddDeviceView(viewModel: vm))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .restoreList:
            navi.push(content: RestoreListView())
        case .restoreMulti:
            navi.push(content: RestoreMultiBackupOptionView())
        case let .multiConnect(item):
            navi.push(content: RestoreMultiConnectView(items: item))
        case let .multiAccount(list):
            navi.push(content: RestoreMultiAccountView(list))
        case let .inputMnemonic(callback):
            navi.push(content: RestoreMultiInputMnemonicView(callback: callback))
        case let .createProfile(vm):
            navi.push(content: CreateProfileWaitingView(vm))
        case let .createProfileSuccess(vm):
            navi.push(content: AccountCreatedView(vm))
        case let .restoreErrorView(error):
            navi.push(content: RestoreErrorView(error: error))
        case .keystore:
            navi.push(content: KeyStoreLoginView())
        case let .importAddress(viewModel):
            let vc = PresentHostingController(rootView: ImportAccountsView(viewModel: viewModel))
            navi.present(vc, animated: true, completion: nil)
        case let .importUserName(viewModel):
            navi.push(content: ImportUserNameView(viewModel: viewModel))
        case .privateKey:
            navi.push(content: PrivateKeyLoginView())
        case .seedPhrase:
            navi.push(content: SeedPhraseLoginView())
        }
    }
}

// MARK: - RouteMap.Register

extension RouteMap {
    enum Register {
        case root(String?)
    }
}

// MARK: - RouteMap.Register + RouterTarget

extension RouteMap.Register: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case let .root(mnemonic):
            navi.push(content: UsernameView(mnemonic: mnemonic))
        }
    }
}

// MARK: - RouteMap.Backup

extension RouteMap {
    enum Backup {
        case backupRoot
        case chooseBackupMethod
        case backupToCloud(BackupManager.BackupType)
        case backupManual

        case backupList
        case rootToBackupList
        case multiBackup([MultiBackupType])
        case uploadMulti([MultiBackupType])
        case showPhrase(String)
        case backupDetail(KeyDeviceModel)

        case createPin
        case confirmPin(String)
        case verityPin(
            MultiBackupVerifyPinViewModel.From,
            MultiBackupVerifyPinViewModel.VerifyCallback
        )

        case introduction(IntroductionView.Topic, EmptyClosure, Bool)
        case thingsNeedKnowOnBackup
        case showRecoveryPhraseBackup(String)
        case backupCompleted(String)
    }
}

// MARK: - RouteMap.Backup + RouterTarget

extension RouteMap.Backup: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .backupRoot:
            navi.push(content: TYNKView())
        case .chooseBackupMethod:
            guard let rootVC = navi.viewControllers.first else {
                return
            }

            var newVCList = [rootVC]
            let vc = RouteableUIHostingController(rootView: RecoveryPhraseView(backupMode: false))
            newVCList.append(vc)
            navi.setViewControllers(newVCList, animated: true)
        case let .backupToCloud(type):
            navi.push(content: BackupPasswordView(backupType: type))
        case .backupManual:
            navi.push(content: ManualBackupView())
        case .backupList:
            navi.push(content: BackupListView())
        case .rootToBackupList:
            guard let rootController = navi.viewControllers.first else { return }
            let backupController = RouteableUIHostingController(rootView: BackupListView())
            let viewControllers = [rootController, backupController]
            navi.setViewControllers(viewControllers, animated: false)
        case let .multiBackup(items):
            navi.push(content: BackupMultiView(items: items))
        case let .uploadMulti(items):
            navi.push(content: BackupUploadView(items: items))
        case let .showPhrase(mnemonic):
            navi.push(content: MultiBackupPhraseView(mnemonic: mnemonic))
        case let .backupDetail(item):
            navi.push(content: MultiBackupDetailView(item: item))
        case .createPin:
            navi.push(content: MultiBackupCreatePinView())
        case let .confirmPin(pin):
            navi.push(content: MultiBackupConfirmPinView(lastPin: pin))
        case let .verityPin(from, callback):
            navi.push(content: MultiBackupVerifyPinView(from: from, callback: callback))
        case let .introduction(topic, closure, isPush):
            if isPush {
                navi.push(content: IntroductionView(topic: topic, confirmClosure: closure))
            } else {
                navi.present(content: IntroductionView(topic: topic, confirmClosure: closure))
            }
        case .thingsNeedKnowOnBackup:
            navi.push(content: ThingsNeedKnowView())
        case let .showRecoveryPhraseBackup(mnemonic):
            navi.push(content: ShowRecoveryPhraseBackup(mnemonic: mnemonic))
        case let .backupCompleted(mnemonic):
            navi.push(content: RecoveryPhraseBackupResultView(mnemonic: mnemonic))
        }
    }
}

// MARK: - RouteMap.Wallet

extension RouteMap {
    enum Wallet {
        case addToken
        case tokenDetail(TokenModel, Bool)
        case receive
        case send(_ address: String = "")
        case sendAmount(Contact, TokenModel, isPush: Bool = true)
        case scan(SPQRCodeCallback, click: SPQRCodeCallback? = nil)
        case buyCrypto
        case transactionList(String?)
        case swapEvmToken(TokenModel)
        case swapCadenceToken(TokenModel)
        case selectToken(TokenModel?, [TokenModel], (TokenModel) -> Void)
        case stakingList
        case stakingSelectProvider
        case stakeGuide
        case stakeAmount(StakingProvider, isUnstake: Bool = false)
        case stakeDetail(StakingProvider, StakingNode)
        case stakeSetupConfirm(StakeAmountViewModel)
        case backToTokenDetail
        case jailbreakAlert
        case pushAlert
        case receiveQR
        case enableEVM
        case moveNFTs
        case moveAssets
        case moveToken(TokenModel)
        case selectMoveToken(FWAddress, (TokenModel) -> Void)
        case chooseChild(MoveAccountsViewModel)
        case addCustomToken
        case showCustomToken(CustomToken)
        case addTokenSheet(CustomToken, BoolClosure)
        case swapProvider(TokenModel?)
    }
}

// MARK: - RouteMap.Wallet + RouterTarget

extension RouteMap.Wallet: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .addToken:
            navi.push(content: AddTokenView(vm: AddTokenViewModel()))
        case let .tokenDetail(token, isAccessible):
            navi.push(content: TokenDetailView(token: token, accessible: isAccessible))
        case .receive:
            let vc = UIHostingController(rootView: WalletReceiveView())
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .coverVertical
            vc.view.backgroundColor = .clear
            navi.present(vc, animated: false)
        case let .send(address):
            navi.present(content: WalletSendView(address: address))
        case let .sendAmount(contact, token, isPush):
            if isPush {
                navi.push(content: WalletSendAmountView(target: contact, token: token))
            } else {
                navi.present(content: WalletSendAmountView(target: contact, token: token))
            }
        case let .scan(handler, click):
//            let rootVC = Router.topPresentedController()
            SPQRCode.scanning(handled: handler, click: click, on: navi)
        case .buyCrypto:
            let vc = CustomHostingController(rootView: BuyProvderView())
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case let .transactionList(contractId):
            let vc = TransactionListViewController(contractId: contractId)
            navi.pushViewController(vc, animated: true)
        case let .swapEvmToken(token):
            guard let url = URL(string: "https://swap.kittypunch.xyz/#/swap") else { return }
            Router.route(to: RouteMap.Explore.browser(url))
        case let .swapCadenceToken(token):
            guard let url =
                URL(
                    string: "https://app.increment.fi/swap?in=A.1654653399040a61.FlowToken&out=\(token.contractId)"
                )
            else { return }
            Router.route(to: RouteMap.Explore.browser(url))
        case let .selectToken(selectedToken, disableTokens, callback):
            let vm = AddTokenViewModel(
                selectedToken: selectedToken,
                disableTokens: disableTokens,
                selectCallback: callback
            )
            navi.present(content: AddTokenView(vm: vm))
        case .stakingList:

            let stakingList = RouteableUIHostingController(rootView: StakingListView())
            var dest: [UIViewController] = [stakingList]
            if StakingManager.shared.isStaked == false {
                let stakingProvider = RouteableUIHostingController(rootView: SelectProviderView())
                dest.append(stakingProvider)
            }
            navi.setViewControllers(navi.viewControllers + dest, animated: true)
        case .stakingSelectProvider:
            navi.push(content: SelectProviderView())
        case .stakeGuide:
            navi.push(content: StakeGuideView())
        case let .stakeAmount(provider, isUnstake):
            navi.push(content: StakeAmountView(provider: provider, isUnstake: isUnstake))
        case let .stakeDetail(provider, node):
            navi.push(content: StakingDetailView(provider: provider, node: node))
        case let .stakeSetupConfirm(vm):
            let vc = CustomHostingController(rootView: StakeAmountView.StakeSetupView(vm: vm))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .backToTokenDetail:
            if let existVC = navi.viewControllers
                .first(where: { $0 as? RouteableUIHostingController<TokenDetailView> != nil })
            {
                navi.popToViewController(existVC, animated: true)
                return
            }

            navi.popToRootViewController(animated: true)
        case .jailbreakAlert:
            let vc = CustomHostingController(rootView: JailbreakAlertView())
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .pushAlert:
            let vc = RouteableUIHostingController(rootView: PushAlertView())
            vc.modalPresentationStyle = .fullScreen
            let contentNavi = RouterNavigationController(rootViewController: vc)
            contentNavi.modalPresentationCapturesStatusBarAppearance = true
            contentNavi.modalPresentationStyle = .fullScreen
            Router.topPresentedController().present(contentNavi, animated: true)
        case .receiveQR:
            navi.present(content: ReceiveQRView())
        case .enableEVM:
            navi.push(content: EVMEnableView())
        case .moveNFTs:
            let vc = PresentHostingController(rootView: MoveNFTsView())
            navi.present(vc, animated: true, completion: nil)
        case .moveAssets:
            let vc = PresentHostingController(rootView: MoveAssetsView())
            navi.present(vc, animated: true, completion: nil)
        case let .moveToken(tokenModel):
            let vc = PresentHostingController(rootView: MoveTokenView(
                tokenModel: tokenModel,
                isPresent: .constant(true)
            ))
            navi.present(vc, animated: true, completion: nil)
        case let .selectMoveToken(address, callback):
            let vm = TokenBalanceListViewModel(address: address, selectCallback: callback)
            Router.topPresentedController().present(content: TokenBalanceListView(vm: vm))
        case let .chooseChild(model):
            let vc = PresentHostingController(rootView: MoveAccountsView(viewModel: model))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .addCustomToken:
            navi.push(content: AddCustomTokenView())
        case let .showCustomToken(token):
            navi.push(content: CustomTokenDetailView(token: token))
        case let .addTokenSheet(token, callback):
            let vc = PresentHostingController(
                rootView: AddTokenSheetView(
                    customToken: token,
                    callback: callback
                )
            )
            navi.present(vc, completion: nil)
        case let .swapProvider(token):
            let vc = PresentHostingController(rootView: SwapProviderView(token: token))
            navi.present(vc, completion: nil)
        }
    }
}

// MARK: - RouteMap.Profile

extension RouteMap {
    enum Profile {
        case themeChange
        case developer
        case about
        case addressBook
        case edit
        case editName
        case editAvatar
        case backupChange
        case walletSetting(Bool, String)
        case privateKey(Bool)
        case walletConnect
        case manualBackup(Bool)
        case security(Bool)
        case inbox
        case resetWalletConfirm
        case currency
        case accountSetting
        case accountDetail(ChildAccount)
        case switchProfile
        case editChildAccount(ChildAccount)
        case backToAccountSetting

        case linkedAccount
        case accountKeys
        case devices
        case deviceInfo(DeviceInfoModel)

        case keychain
        case walletList

        case wallpaper
        case secureEnclavePrivateKey
    }
}

// MARK: - RouteMap.Profile + RouterTarget

extension RouteMap.Profile: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .themeChange:
            navi.push(content: ThemeChangeView())
        case .developer:
            navi.push(content: DeveloperModeView())
        case .about:
            navi.push(content: AboutView())
        case .addressBook:
            navi.push(content: AddressBookView())
        case .edit:
            navi.push(content: ProfileEditView())
        case .editName:
            navi.push(content: ProfileEditNameView())
        case .editAvatar:
            navi.push(content: EditAvatarView())
        case .backupChange:
            #if DEBUG
//            navi.push(content: BackupPatternView())
//            return
            #endif
            if let existVC = navi.viewControllers
                .first(where: { $0.navigationItem.title == "backup".localized })
            {
                navi.popToViewController(existVC, animated: true)
                return
            }

            navi.push(content: ProfileBackupView())
        case let .walletSetting(animated, address):
            Router.coordinator.rootNavi?.push(
                content: WalletSettingView(address: address),
                animated: animated
            )
        case .walletConnect:
            navi.push(content: WalletConnectView())
        case let .privateKey(animated):
            Router.coordinator.rootNavi?.push(content: PrivateKeyView(), animated: animated)
        case let .manualBackup(animated):
            Router.coordinator.rootNavi?.push(
                content: RecoveryPhraseView(backupMode: true),
                animated: animated
            )
        case let .security(animated):
            if let existVC = Router.coordinator.rootNavi?.viewControllers
                .first(where: { $0.navigationItem.title == "security".localized })
            {
                navi.popToViewController(existVC, animated: animated)
                return
            }

            Router.coordinator.rootNavi?.push(content: ProfileSecureView(), animated: animated)
        case .inbox:
            navi.push(content: InboxView())
        case .resetWalletConfirm:
            navi.push(content: WalletResetConfirmView())
        case .currency:
            navi.push(content: CurrencyListView())
        case .accountSetting:
            navi.push(content: AccountSettingView())
        case let .accountDetail(childAccount):
            let vm = ChildAccountDetailViewModel(childAccount: childAccount)
            navi.push(content: ChildAccountDetailView(vm: vm))
        case .switchProfile:
            let vc = PresentHostingController(rootView: AccountSwitchView())
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case let .editChildAccount(childAccount):
            let vm = ChildAccountDetailEditViewModel(childAccount: childAccount)
            navi.push(content: ChildAccountDetailEditView(vm: vm))
        case .backToAccountSetting:
            if let existVC = navi.viewControllers
                .first(where: { $0 as? RouteableUIHostingController<AccountSettingView> != nil })
            {
                navi.popToViewController(existVC, animated: true)
                return
            }
            navi.popToRootViewController(animated: true)
        case .linkedAccount:
            navi.push(content: LinkedAccountView())
        case .accountKeys:
            navi.push(content: AccountKeysView())
        case .devices:
            navi.push(content: DevicesView())
        case let .deviceInfo(model):
            navi.push(content: DevicesInfoView(info: model))
        case .keychain:
            navi.push(content: KeychainListView())
        case .walletList:
            navi.push(content: WalletListView())
        case .wallpaper:
            navi.push(content: WallpaperView())
        case .secureEnclavePrivateKey:
            navi.push(content: SecureEnclavePrivateKeyView())
        }
    }
}

// MARK: - RouteMap.AddressBook

extension RouteMap {
    enum AddressBook {
        case root
        case add(AddressBookView.AddressBookViewModel)
        case edit(Contact, AddressBookView.AddressBookViewModel)
        case pick(WalletSendView.WalletSendViewSelectTargetCallback)
    }
}

// MARK: - RouteMap.AddressBook + RouterTarget

extension RouteMap.AddressBook: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .root:
            navi.push(content: AddressBookView())
        case let .add(vm):
            navi.push(content: AddAddressView(addressBookVM: vm))
        case let .edit(contact, vm):
            navi.push(content: AddAddressView(editingContact: contact, addressBookVM: vm))
        case let .pick(callback):
            navi.present(content: WalletSendView(callback: callback))
        }
    }
}

// MARK: - RouteMap.PinCode

extension RouteMap {
    enum PinCode {
        case root
        case pinCode
        case confirmPinCode(String)
        case verify(Bool, Bool, VerifyPinViewModel.VerifyCallback)
    }
}

// MARK: - RouteMap.PinCode + RouterTarget

extension RouteMap.PinCode: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .root:
            navi.push(content: RequestSecureView())
        case .pinCode:
            navi.push(content: CreatePinCodeView())
        case let .confirmPinCode(lastPin):
            navi.push(content: ConfirmPinCodeView(lastPin: lastPin))
        case let .verify(animated, needNavi, callback):
            let vc = RouteableUIHostingController(rootView: VerifyPinView(callback: callback))
            vc.modalPresentationStyle = .fullScreen
            if needNavi {
                let contentNavi = RouterNavigationController(rootViewController: vc)
                contentNavi.modalPresentationCapturesStatusBarAppearance = true
                contentNavi.modalPresentationStyle = .fullScreen
                Router.topPresentedController().present(contentNavi, animated: animated)
            } else {
                Router.topPresentedController().present(vc, animated: animated)
            }
        }
    }
}

// MARK: - RouteMap.NFT

extension RouteMap {
    enum NFT {
        case detail(NFTTabViewModel, NFTModel, ChildAccount?)
        case collection(NFTTabViewModel, CollectionItem)
        case collectionDetail(String, String, ChildAccount)
        case addCollection
        case send(NFTModel, Contact, ChildAccount?)
        case AR(UIImage)
        case selectCollection(SelectCollectionViewModel)
        case searchNFT(NFTCollectionInfo)
    }
}

// MARK: - RouteMap.NFT + RouterTarget

extension RouteMap.NFT: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case let .detail(vm, nft, childAccount):
            navi.push(content: NFTDetailPage(viewModel: vm, nft: nft, from: childAccount))
        case let .collection(vm, collection):
            navi.push(content: NFTCollectionListView(viewModel: vm, collection: collection))
        case let .collectionDetail(addr, path, childAccount):
            navi.push(content: NFTCollectionListView(address: addr, path: path, from: childAccount))
        case .addCollection:
            navi.push(content: NFTAddCollectionView())
        case let .send(nft, contact, childAccount):
            let vc = CustomHostingController(rootView: NFTTransferView(
                nft: nft,
                target: contact,
                fromChildAccount: childAccount
            ))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .AR:
            print("")
        case let .selectCollection(vm):
            Router.topPresentedController().present(content: SelectCollectionView(viewModel: vm))
        case let .searchNFT(info):
            navi.push(content: NFTSearchView(collection: info))
        }
    }
}

// MARK: - RouteMap.Transaction

extension RouteMap {
    enum Transaction {
        case detail(Flow.ID)
    }
}

// MARK: - RouteMap.Transaction + RouterTarget

extension RouteMap.Transaction: RouterTarget {
    func onPresent(navi _: UINavigationController) {
        switch self {
        case let .detail(transactionId):
            let network = LocalUserDefaults.shared.flowNetwork
            let accountType = AccountType.current
            let url = network.getTransactionHistoryUrl(
                accountType: .flow,
                transactionId: transactionId.hex
            )

//            UIApplication.shared.open(url)
            TransactionUIHandler.shared.dismissListView()
            url.map { Router.route(to: RouteMap.Explore.browser($0)) }
        }
    }
}

// MARK: - RouteMap.Explore

extension RouteMap {
    enum Explore {
        case browser(URL)
        case safariBrowser(URL)
        case authn(BrowserAuthnViewModel)
        case authz(BrowserAuthzViewModel)
        case signMessage(BrowserSignMessageViewModel)
        case searchExplore
        case claimDomain
        case bookmark
        case linkChildAccount(ChildAccountLinkViewModel)
        case dapps
        case switchNetwork(
            FlowNetworkType,
            FlowNetworkType,
            SwitchNetworkClosure?
        )
        case signTypedMessage(BrowserSignTypedMessageViewModel)
    }
}

// MARK: - RouteMap.Explore + RouterTarget

extension RouteMap.Explore: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case let .browser(url):

            // For some dapp like Disney and NBA Topshot
            // We should navigate user to App Store to download
            let externalHost = ["apps.apple.com"]
            if let host = url.host, externalHost.contains(host) {
                UIApplication.shared.open(url)
                return
            }

            if let isIn = RemoteConfigManager.shared.config?.features.browser, isIn {
                let vc = BrowserViewController()
                vc.loadURL(url)
                navi.pushViewController(vc, animated: true)
            } else {
                UIApplication.shared.open(url)
            }
        case let .safariBrowser(url):
            let vc = SFSafariViewController(url: url)
            navi.present(vc, animated: true)
        case let .authn(vm):
            let vc = CustomHostingController(rootView: BrowserAuthnView(vm: vm))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case let .authz(vm):
            let vc = CustomHostingController(rootView: BrowserAuthzView(vm: vm), showLarge: true)
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case let .signMessage(vm):
            let vc = CustomHostingController(
                rootView: BrowserSignMessageView(vm: vm),
                showLarge: true
            )
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .searchExplore:
            let inputVC = BrowserSearchInputViewController()
            inputVC.setSearchText(text: "")
            inputVC.selectTextCallback = { text in
                UISelectionFeedbackGenerator().selectionChanged()
                let urlString = BrowserSearchInputViewController.makeUrlIfNeeded(urlString: text)
                if let url = URL(string: urlString) {
                    navi.popViewController(animated: false) {
                        Router.route(to: RouteMap.Explore.browser(url))
                    }
                }
            }
            navi.pushViewController(inputVC, animated: false)
        case .claimDomain:
            navi.push(content: ClaimDomainView())
        case .bookmark:
            navi.present(content: BrowserBookmarkView())
        case let .linkChildAccount(vm):
            let vc = CustomHostingController(rootView: ChildAccountLinkView(vm: vm))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case .dapps:
            navi.present(content: DAppsListView())
        case let .switchNetwork(from, to, callback):
            let vc = CustomHostingController(rootView: NetworkSwitchPopView(from: from, to: to))
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        case let .signTypedMessage(viewModel):
            let vc = CustomHostingController(
                rootView: BrowserSignTypedMessageView(viewModel: viewModel),
                showLarge: true
            )
            Router.topPresentedController().present(vc, animated: true, completion: nil)
        }
    }
}
