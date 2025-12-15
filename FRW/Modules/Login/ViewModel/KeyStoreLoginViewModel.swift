//
//  KeyStoreLoginViewModel.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import Flow
import FlowWalletKit
import Foundation
import SwiftUI
import WalletCore
import Web3Core

// MARK: - KeyStoreLoginViewModel

final class KeyStoreLoginViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var json: String = ""
    @Published
    var password: String = ""
    @Published
    var wantedAddress: String = ""

    @Published
    var buttonState: VPrimaryButtonState = .disabled

    var userName: String = ""

    @Published
    var wallet: FlowWalletKit.Wallet?

    @Published
    var showPDFPicker = false

    @Published
    var isPDFProcessing = false


    @MainActor
    func update(json _: String) {
        update()
    }

    @MainActor
    func update(password _: String) {
        update()
    }

    func update(address _: String) {}

    func onSumbit() {
        UIApplication.shared.endEditing()
        HUD.loading()
        Task {
            do {
                privateKey = try PrivateKey.restore(
                    json: json,
                    password: password,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )
                guard let privateKey else {
                    HUD.error(title: "invalid_data".localized)
                    return
                }
              await MainActor.run {
                self.wallet = FlowWalletKit.Wallet(type: .key(privateKey))
              }


                try await fetchAllAddresses()
                HUD.dismissLoading()

                if wantedAddress.isEmpty {
                  guard let account = wallet?.flowAccounts?[currentNetwork]?.first else {
                    return
                  }
                  selectedAccount(by: account)
                } else {
                    guard let keys = wallet?.flowAccounts?[currentNetwork] else {
                        HUD.error(title: "not_find_address".localized)
                        return
                    }
                    guard let account = keys.filter({ $0.address.hex == wantedAddress }).first
                    else {
                        HUD.error(title: "not_find_address".localized)
                        return
                    }
                    selectedAccount(by: account)
                }

            } catch let error as FlowWalletKit.FWKError {
                if error == FlowWalletKit.FWKError.invaildKeyStorePassword {
                    HUD.error(title: "invalid_password".localized)
                } else if error == FlowWalletKit.FWKError.invaildKeyStoreJSON {
                    HUD.error(title: "invalid_json".localized)
                } else {
                    HUD.error(title: "invalid_data".localized)
                }
                HUD.dismissLoading()
            } catch {
                HUD.error(title: "invalid_data".localized)
                HUD.dismissLoading()
            }
        }
    }

    // fetch all addresses of Public Key
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
        let keys = account?.keys.filter {
                $0.publicKey.description == p256PublicKey || $0.publicKey
                    .description == secp256PublicKey
            }
        guard let selectedKey = keys?.first,
              let address = account?.address.hex, let privateKey = privateKey
        else {
            HUD.error(title: "not_find_address".localized)
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
                } else if response.httpCode == 200 {
                    createUserName { name in
                        Task {
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: name,
                                flowKey: selectedKey,
                                privateKey: privateKey,
                                isImport: true
                            )
                            Router.popToRoot()
                        }
                    }
                }
                HUD.dismissLoading()
            } catch {
                if let code = error.moyaCode() {
                    if code == 409 {
                        do {
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: "",
                                flowKey: selectedKey,
                                privateKey: privateKey
                            )
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
    private var account: Flow.Account?

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = (json.isEmpty || password.isEmpty) ? .disabled : .enabled
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
        isPDFProcessing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Step 1: Extract text from PDF
                let pdfText = try PDFParser.shared.extractText(from: url)
                let trimmedText = pdfText.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedText.isEmpty else {
                    DispatchQueue.main.async {
                        self.isPDFProcessing = false
                        HUD.error(title: "PDF contains no text")
                    }
                    return
                }

                // Step 2: Extract JSON string from text
                let jsonString = self.extractJSONFromText(trimmedText)

                // Step 3: Validate and parse JSON
                let validationResult = JSONValidator.shared.validate(string: jsonString)

                guard validationResult.isValid, let jsonValue = validationResult.parsedValue else {
                    DispatchQueue.main.async {
                        self.isPDFProcessing = false
                        let errorMsg = validationResult.errors.first?.localizedDescription ?? "invalid_json".localized
                        HUD.error(title: errorMsg)
                    }
                    return
                }

                // Step 4: Get minified JSON for keystore field
                let minifiedJSON = JSONValidator.shared.minify(string: jsonString) ?? jsonString

                // Step 5: Extract address if available
                var extractedAddress: String?
                if let dict = jsonValue as? [String: Any] {
                    extractedAddress = dict["address"] as? String
                }

                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    self.json = minifiedJSON

                    if let address = extractedAddress {
                        self.wantedAddress = address
                    }

                    self.update()
                    log.info("[KeyStore] PDF JSON extracted successfully, length: \(minifiedJSON.count)")
                }

            } catch {
                DispatchQueue.main.async {
                    self.isPDFProcessing = false
                    log.error("[KeyStore] PDF extraction failed: \(error.localizedDescription)")
                    HUD.error(title: error.localizedDescription)
                }
            }
        }
    }

    /// Extract JSON string from raw text
    /// Handles cases where PDF might have multiple JSON blocks or extra text
    private func extractJSONFromText(_ text: String) -> String {
        // Find all potential JSON objects starting with '{'
        let allJSONBlocks = findAllJSONBlocks(in: text)

        // Try each block and return the first valid one
        for block in allJSONBlocks {
            if JSONValidator.shared.isValid(string: block) {
                return block
            }
        }

        // If no valid JSON found, try the whole text
        if text.hasPrefix("{") || text.hasPrefix("[") {
            if let jsonString = findJSONBoundary(in: text, startIndex: text.startIndex) {
                if JSONValidator.shared.isValid(string: jsonString) {
                    return jsonString
                }
            }
        }

        // Return original text as fallback
        return text
    }

    /// Find all potential JSON blocks in text
    /// Returns array of JSON strings found at each '{' position
    private func findAllJSONBlocks(in text: String) -> [String] {
        var blocks: [String] = []
        var searchStart = text.startIndex

        while searchStart < text.endIndex {
            // Find next '{' character
            guard let braceIndex = text[searchStart...].firstIndex(of: "{") else {
                break
            }

            // Try to extract JSON starting from this position
            if let jsonBlock = findJSONBoundary(in: text, startIndex: braceIndex) {
                blocks.append(jsonBlock)
            }

            // Move search position forward
            searchStart = text.index(after: braceIndex)
        }

        return blocks
    }

    /// Find JSON boundary by matching brackets starting from a given index
    private func findJSONBoundary(in text: String, startIndex: String.Index) -> String? {
        guard startIndex < text.endIndex else { return nil }

        let firstChar = text[startIndex]
        guard firstChar == "{" || firstChar == "[" else { return nil }

        let openBracket: Character = firstChar == "{" ? "{" : "["
        let closeBracket: Character = openBracket == "{" ? "}" : "]"

        var depth = 0
        var inString = false
        var escaped = false
        var currentIndex = startIndex

        while currentIndex < text.endIndex {
            let char = text[currentIndex]

            if escaped {
                escaped = false
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\\" && inString {
                escaped = true
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if char == "\"" {
                inString.toggle()
                currentIndex = text.index(after: currentIndex)
                continue
            }

            if !inString {
                if char == openBracket {
                    depth += 1
                } else if char == closeBracket {
                    depth -= 1
                    if depth == 0 {
                        let endIndex = text.index(after: currentIndex)
                        return String(text[startIndex..<endIndex])
                    }
                }
            }

            currentIndex = text.index(after: currentIndex)
        }

        return nil
    }
}

extension KeyStoreLoginViewModel {
    private var p256PublicKey: String? {
        privateKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue
    }

    private var secp256PublicKey: String? {
        privateKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue
    }
}

// MARK: - Keystore

struct Keystore: Codable {
    var address: String?
    var crypto: CryptoParamsV3
    var id: String?
    var version: Int
}

// MARK: - ImportAccountInfo

struct ImportAccountInfo {
    let address: String?
    let weight: Int?
    let keyId: Int?
    let publicKey: String?
    let signAlgo: Flow.SignatureAlgorithm
    let hashAlgo: Flow.HashAlgorithm = .SHA2_256
}
