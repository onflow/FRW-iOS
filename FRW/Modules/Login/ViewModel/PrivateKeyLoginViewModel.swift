//
//  PrivateKeyLoginViewModel.swift
//  FRW
//
//  Refactored version using LoginViewModelProtocol
//  Created by cat on 2024/12/28.
//

import CryptoKit
import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - PrivateKeyLoginViewModel

final class PrivateKeyLoginViewModel: ObservableObject, LoginViewModelProtocol {
    // MARK: - LoginViewModelProtocol Required Properties

    typealias KeyType = FlowWalletKit.PrivateKey

    @Published var wantedAddress: String = ""
    @Published var buttonState: VPrimaryButtonState = .disabled
    var wallet: FlowWalletKit.Wallet? = nil
    var cryptoKey: FlowWalletKit.PrivateKey?
    var account: Flow.Account? = nil

    // MARK: - Specific Properties

    @Published var key: String = ""
    var userName: String = ""

    // MARK: - Initialization

    init() {
        // Setup any initial state
    }

    // MARK: - UI Update Methods

  @Published
  var showPDFPicker = false

  @Published
  var isPDFProcessing = false

  @Published
  var showPDFParseError = false

  /// Flow Wallet extension Chrome Web Store URL
  static let flowWalletExtensionURL = "https://chromewebstore.google.com/detail/flow-wallet/hpclkefagolihohboafpheddmmgdffjm?hl=en"

    init(key: String?) {
      self.key = key ?? ""
      buttonState = (self.key.isEmpty) ? .disabled : .enabled
    }

    @MainActor
    func update(key _: String) {
        update()
    }

    @MainActor
    func update(address _: String) {
        update()
    }

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = key.isEmpty ? .disabled : .enabled
    }

    // MARK: - LoginViewModelProtocol Required Methods

    func onSubmit() {
        UIApplication.shared.endEditing()
        HUD.loading()

        Task {
            do {
                // Restore private key from hex string
                guard let data = Data(hexString: key.stripHexPrefix()) else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                cryptoKey = try PrivateKey.restore(
                    secret: data,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )

                guard cryptoKey != nil else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                // Create wallet with restored key
                wallet = FlowWalletKit.Wallet(type: .key(cryptoKey!))

                // Fetch all addresses (common logic from protocol)
                try await fetchAllAddresses()

                HUD.dismissLoading()

                // Select account (common logic from protocol)
                selectAccountFromWallet()

            } catch {
                HUD.dismissLoading()
                HUD.error(title: "invalid_data".localized)
            }
        }
    }

    func getP256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue.format()
    }

    func getSecp256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue.format()
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
        if let dict = jsonValue as? [String: Any], let crypto = dict["crypto"] {
          Router.route(to: RouteMap.RestoreLogin.keystore(minifiedJSON))
          return
        }
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
// MARK: - LoginError

enum LoginError: Error {
    case missingKey
    case invalidData
}
