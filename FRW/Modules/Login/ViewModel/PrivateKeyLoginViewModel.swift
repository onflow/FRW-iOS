//
//  PrivateKeyLoginViewModel.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import CryptoKit
import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - PrivateKeyLoginViewModel

final class PrivateKeyLoginViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var key: String = ""
    @Published
    var wantedAddress: String = ""
    @Published
    var buttonState: VPrimaryButtonState = .disabled

    var userName: String = ""

    var wallet: FlowWalletKit.Wallet? = nil

  @Published
  var showPDFPicker = false

  @Published
  var isPDFProcessing = false

  @Published
  var showPDFParseError = false

  /// Flow Wallet extension Chrome Web Store URL
  static let flowWalletExtensionURL = "https://chromewebstore.google.com/detail/flow-wallet/hpclkefagolihohboafpheddmmgdffjm?hl=en"

    @MainActor
    func update(key _: String) {
        update()
    }

    @MainActor
    func update(address _: String) {
        update()
    }

    func onSumbit() {
        UIApplication.shared.endEditing()
        HUD.loading()
        Task {
            do {
                let chainId = currentNetwork
                guard let data = Data(hexString: key.stripHexPrefix()) else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                privateKey = try PrivateKey.restore(
                    secret: data,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )
                guard let privateKey = privateKey else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }
                wallet = FlowWalletKit.Wallet(type: .key(privateKey))

                try await fetchAllAddresses()
                HUD.dismissLoading()
                if wantedAddress.isEmpty {
                  guard let account = wallet?.flowAccounts?[currentNetwork]?.first else {
                    return
                  }
                  selectedAccount(by: account)
                } else {
                    guard let keys = wallet?.flowAccounts?[currentNetwork] else {
                        return
                    }
                    guard let account = keys.filter({ $0.address.hex == wantedAddress }).first
                    else {
                        HUD.error(title: "not_find_address".localized)
                        return
                    }
                    selectedAccount(by: account)
                }
            } catch {
                HUD.dismissLoading()
            }
        }
    }

    func fetchAllAddresses() async throws {
        do {
            _ = try await wallet?.fetchAllNetworkAccounts()
        } catch {
            log.error("\(error.localizedDescription)")
        }
    }

    func selectedAccount(by account: Flow.Account) {
        self.account = account
        checkPublicKey()
    }

    func createUserName(callback: @escaping (String) -> Void) {
        let viewModel = ImportUserNameViewModel { name in
            if !name.isEmpty {
                callback(name)
            }
        }
        Router.route(to: RouteMap.RestoreLogin.importUserName(viewModel))
    }

    func checkPublicKey() {
        let keys = account?.keys
            .filter {
                $0.publicKey.description == p256PublicKey || $0.publicKey
                    .description == secp256PublicKey
            }
        guard let selectedKey = keys?.first,
              let address = account?.address.hex, let privateKey = privateKey
        else {
            log.error("[Import] keys of account not match the public:\(String(describing: p256PublicKey)) or \(String(describing: secp256PublicKey)) ")
            return
        }
        guard selectedKey.weight >= 1000 else {
            HUD.error(title: "account_key_weight_less".localized)
            return
        }
        guard !selectedKey.revoked else {
            HUD.error(title: "account_key_done_revoked_tips".localized)
            return
        }
        Task {
            HUD.loading()
            do {
                let publicKey = selectedKey.publicKey.description
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.checkimport(publicKey))
                if response.httpCode == 409 {
                    try await UserManager.shared.importLogin(
                        by: address,
                        userName: "",
                        flowKey: selectedKey,
                        privateKey: privateKey
                    )
                    HUD.dismissLoading()
                } else if response.httpCode == 200 {
                    HUD.dismissLoading()
                    createUserName { _ in
                        Task {
                          do {
                            HUD.loading()
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: self.userName,
                                flowKey: selectedKey,
                                privateKey: privateKey,
                                isImport: true
                            )
                            HUD.dismissLoading()
                            Router.popToRoot()
                          } catch {
                            log.error("[Import] check public key own error:\(error)")
                            HUD.dismissLoading()
                            if let moyError = error.moyaCode() {
                              HUD.error(title: "error:\(moyError)")
                            }
                          }
                        }
                    }
                } else {
                  HUD.dismissLoading()
                }

            } catch {
                if let code = error.moyaCode() {
                    if code == 409 {
                        do {
                            HUD.loading()
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: "",
                                flowKey: selectedKey,
                                privateKey: privateKey
                            )
                            HUD.dismissLoading()
                            Router.popToRoot()
                        } catch {
                            log.error("[Import] login 409 :\(error)")
                        }
                    }
                }
                log.error("[Import] check public key own error:\(error)")
                HUD.dismissLoading()
            }
        }
    }

    // MARK: Private

    private var privateKey: FlowWalletKit.PrivateKey?
    private var account: Flow.Account? = nil

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = (key.isEmpty) ? .disabled : .enabled
    }

}

extension PrivateKeyLoginViewModel {
    private var p256PublicKey: String? {
        privateKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue.dropPrefix("04")
    }

    private var secp256PublicKey: String? {
        privateKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue.dropPrefix("04")
    }
}

// MARK: - Import PDF
extension PrivateKeyLoginViewModel {

    /// Present PDF picker to select and extract JSON
    func pickPDF() {
        showPDFPicker = true
    }

    /// Document picker for selecting PDF files
    var documentPicker: DocumentPicker {
        DocumentPicker.pdf(
            allowsMultipleSelection: false,
            onPick: { [weak self] results in
                self?.showPDFPicker = false
                guard let first = results.first else { return }
                self?.processPDFFile(url: first.url)
            },
            onCancel: { [weak self] in
                self?.showPDFPicker = false
            }
        )
    }

  
    /// Process selected PDF file: extract text and parse JSON
    private func processPDFFile(url: URL) {
        if PDFParser.shared.isPasswordProtected(at: url) {
            promptForPDFPassword(url: url)
        } else {
            performPDFExtraction(url: url, password: nil)
        }
    }

    private func promptForPDFPassword(url: URL, isRetry: Bool = false) {
        let message = isRetry ? "The password provided is incorrect." : nil
        PDFPasswordAlertView.show(message: message) { [weak self] password in
            guard let password = password else {
                // User cancelled
                return
            }
            self?.performPDFExtraction(url: url, password: password)
        }
    }

    private func performPDFExtraction(url: URL, password: String?) {
        isPDFProcessing = true
        showPDFParseError = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Step 1: Extract text from PDF
                let pdfText = try PDFParser.shared.extractText(from: url, password: password)
                let trimmedText = pdfText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedText.isEmpty else {
                    DispatchQueue.main.async {
                        self.isPDFProcessing = false
                        self.showPDFParseError = true
                    }
                    return
                }

                // Step 2: Extract JSON string from text using BloctoPDFExtractor
                let jsonString = BloctoPDFExtractor.extractJSON(from: trimmedText)

                // Step 3: Validate and parse JSON using native JSONSerialization
                guard let jsonValue = BloctoPDFExtractor.parseJSON(jsonString) else {
                    DispatchQueue.main.async {
                        self.isPDFProcessing = false
                        self.showPDFParseError = true
                    }
                    return
                }

                // Step 4: Get minified JSON for PrivateKey field
                let minifiedJSON = BloctoPDFExtractor.minifyJSON(jsonString) ?? jsonString

                // Step 5: Extract address if available
                var privateKey: String?
                if let dict = jsonValue as? [String: Any] {
                    privateKey = dict["private_key"] as? String
                }

                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    self.showPDFParseError = false
                    self.key = privateKey ?? ""

                    self.update()
                    log.info("[PrivateKey] PDF JSON extracted successfully, length: \(minifiedJSON.count)")
                }

            } catch let error as PDFParserError {
                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    
                    if error == .incorrectPassword || error == .passwordRequired {
                        self.promptForPDFPassword(url: url, isRetry: true)
                    } else {
                        self.showPDFParseError = true
                        log.error("[PrivateKey] PDF extraction failed: \(error.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    self.showPDFParseError = true
                    log.error("[PrivateKey] PDF extraction failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Open Flow Wallet extension in Safari
    func openFlowWalletExtension() {
        guard let url = URL(string: Self.flowWalletExtensionURL) else { return }
        UIApplication.shared.open(url)
    }
}
