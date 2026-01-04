//
//  KeyStoreLoginViewModel.swift
//  FRW
//
//  Refactored version using LoginViewModelProtocol
//  Created by cat on 2024/12/28.
//

import Flow
import FlowWalletKit
import Foundation
import SwiftUI
import WalletCore
import Web3Core

// MARK: - KeyStoreLoginViewModel

final class KeyStoreLoginViewModel: ObservableObject, LoginViewModelProtocol {
    // MARK: - LoginViewModelProtocol Required Properties

    typealias KeyType = FlowWalletKit.PrivateKey

    @Published var wantedAddress: String = ""
    @Published var buttonState: VPrimaryButtonState = .disabled
    @Published var wallet: FlowWalletKit.Wallet? = nil
    var cryptoKey: FlowWalletKit.PrivateKey?
    var account: Flow.Account? = nil

    // MARK: - Specific Properties

    @Published var json: String = ""
    @Published var password: String = ""
    var userName: String = ""

    @Published
    var showPDFPicker = false

    @Published
    var isPDFProcessing = false

    @Published
    var showPDFParseError = false

    /// Flow Wallet extension Chrome Web Store URL
    static let flowWalletExtensionURL = "https://chromewebstore.google.com/detail/flow-wallet/hpclkefagolihohboafpheddmmgdffjm?hl=en"

    init(json: String = "") {
      self.json = json
      updateButtonState()
    }

    @MainActor
    func update(json _: String) {
        if json.isEmpty {
            self.showPDFParseError = false
        }
        update()
    }

    @MainActor
    func update(password _: String) {
        update()
    }

    func update(address _: String) {}

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = (json.isEmpty || password.isEmpty) ? .disabled : .enabled
    }

    // MARK: - LoginViewModelProtocol Required Methods

    func onSubmit() {
        UIApplication.shared.endEditing()
        HUD.loading()

        Task {
            do {
                // Restore private key from keystore JSON
                cryptoKey = try PrivateKey.restore(
                    json: json,
                    password: password,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )

                guard cryptoKey != nil else {
                    HUD.error(title: "invalid_data".localized)
                    HUD.dismissLoading()
                    return
                }

                // Create wallet with restored key
                wallet = FlowWalletKit.Wallet(type: .key(cryptoKey!))

                // Fetch all addresses (common logic from protocol)
                try await fetchAllAddresses()

                HUD.dismissLoading()

                // Select account (common logic from protocol)
                selectAccountFromWallet()

            } catch let error as FlowWalletKit.FWKError {
                handleFWKError(error)
                HUD.dismissLoading()
            } catch {
                HUD.error(title: "invalid_data".localized)
                HUD.dismissLoading()
            }
        }
    }

    func getP256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue
    }

    func getSecp256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue
    }

    func performLogin(
        address: String,
        userName: String,
        flowKey: Flow.AccountKey,
        isImport: Bool
    ) async throws {
        guard let privateKey = cryptoKey else {
            throw LoginError.missingKey
        }

        try await UserManager.shared.importLogin(
            by: address,
            userName: userName,
            flowKey: flowKey,
            privateKey: privateKey,
            isImport: isImport
        )
    }

    // MARK: - Error Handling

    private func handleFWKError(_ error: FlowWalletKit.FWKError) {
        switch error {
        case .invaildKeyStorePassword:
            HUD.error(title: "invalid_password".localized)
        case .invaildKeyStoreJSON:
            DispatchQueue.main.async {
              self.showPDFParseError = true
            }
            HUD.error(title: "invalid_json".localized)
        default:
            HUD.error(title: "invalid_data".localized)
        }
    }
}

// MARK: - Import PDF

extension KeyStoreLoginViewModel {

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

                // Step 4: Get minified JSON for keystore field
                let minifiedJSON = BloctoPDFExtractor.minifyJSON(jsonString) ?? jsonString

                // Step 5: Extract address if available
                if let dict = jsonValue as? [String: Any], let privateKey = dict["private_key"] as? String {
                    DispatchQueue.main.async {
                        self.isPDFProcessing = false
                        self.showPDFParseError = false
                    }
                    log.info("skip to private key")
                    Router.route(to: RouteMap.RestoreLogin.privateKey(privateKey))
                    return
                }

                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    self.showPDFParseError = false
                    self.json = BloctoPDFExtractor.prettyPrintJSON(minifiedJSON) ?? minifiedJSON

                    self.update()
                    log.info("[KeyStore] PDF JSON extracted successfully, length: \(minifiedJSON.count)")
                }

            } catch let error as PDFParserError {
                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    
                    if error == .incorrectPassword || error == .passwordRequired {
                        self.promptForPDFPassword(url: url, isRetry: true)
                    } else {
                        self.showPDFParseError = true
                        log.error("[KeyStore] PDF extraction failed: \(error.localizedDescription)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    self.showPDFParseError = true
                    log.error("[KeyStore] PDF extraction failed: \(error.localizedDescription)")
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
