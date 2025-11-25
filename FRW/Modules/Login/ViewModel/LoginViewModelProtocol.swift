//
//  LoginViewModelProtocol.swift
//  FRW
//
//  Created by cat on 2024/12/28.
//

import Flow
import FlowWalletKit
import Foundation
import UIKit

// MARK: - LoginViewModelProtocol

/// Common protocol for all login view models (Seed Phrase, Private Key, KeyStore)
protocol LoginViewModelProtocol: ObservableObject {
    // MARK: - Associated Types

    /// The type of cryptographic key used for login (e.g., PrivateKey, SeedPhraseKey)
  associatedtype KeyType: FlowWalletKit.KeyProtocol

    // MARK: - Required Properties

    /// Target address to login (optional, will select first account if empty)
    var wantedAddress: String { get set }

    /// Button state for UI
    var buttonState: VPrimaryButtonState { get set }

    /// Wallet instance after key restoration
    var wallet: FlowWalletKit.Wallet? { get set }

    // MARK: - Private/Internal Properties (must be implemented)

    /// The restored cryptographic key
    var cryptoKey: KeyType? { get set }

    /// The selected Flow account
    var account: Flow.Account? { get set }

    // MARK: - Required Methods

    /// Submit handler to restore key and perform login
    func onSubmit()

    /// Get P256 public key from the crypto key
    func getP256PublicKey() -> String?

    /// Get SECP256k1 public key from the crypto key
    func getSecp256PublicKey() -> String?
  
    func performLogin(address: String, userName: String, flowKey: Flow.AccountKey, isImport: Bool) async throws
}

// MARK: - Default Implementations

extension LoginViewModelProtocol {
    // MARK: - Common Properties Access


    // MARK: - Account Fetching

    /// Fetch all addresses associated with the wallet's public key
    func fetchAllAddresses() async throws {
        do {
            _ = try await wallet?.fetchAllNetworkAccounts()
        } catch {
            log.error("\(error.localizedDescription)")
        }
    }

    // MARK: - Account Selection

    /// Handle account selection and proceed to public key verification
    /// - Parameter account: The selected Flow account
    func selectedAccount(by account: Flow.Account) {
        self.account = account
        checkPublicKey()
    }

    /// Select account based on wantedAddress or default to first account
  func selectAccountFromWallet() {
        guard let wallet = wallet else {
            log.error("[Login] Wallet is nil")
            HUD.error(title: "Wallet is nil from the key")
            return
        }

        if wantedAddress.isEmpty {
            // Select first account if no specific address wanted
          if let account = wallet.flowAccounts?[currentNetwork]?.first {
            selectedAccount(by: account)
          } else {
            log.warning("[Login] No accounts found for current network, Prompt the user to create")
            showAccountNotFound()
          }
        } else {
            // Filter accounts by wanted address
            guard let accounts = wallet.flowAccounts?[currentNetwork] else {
                log.error("[Login] wallet don't have flow account")
                HUD.error(title: "not_find_address".localized)
                return
            }
            guard let account = accounts.first(where: { $0.address.hex == wantedAddress }) else {
                log.error("[Login] don't find the account from \(wantedAddress)")
                HUD.error(title: "not_find_address".localized)
                return
            }
            selectedAccount(by: account)
        }
    }

    func showAccountNotFound() {
      HUD.dismissLoading()
      let signAlgo = Flow.SignatureAlgorithm.ECDSA_SECP256k1
      
      guard let address = try? wallet?.ethAddress(),
            let publicKey = cryptoKey?.publicKey(signAlgo: signAlgo)?.hexValue else {
        HUD.error(title: "Invalide Key", message: "Please check the Mnemonic")
        log.error("[import] address\(String(describing: try? wallet?.ethAddress())) or publicKey is nil")
        return
      }
      
      let flowKey = Flow.AccountKey(
        publicKey: Flow.PublicKey(hex: publicKey),
        signAlgo: signAlgo,
        hashAlgo: .SHA2_256,
        weight: 1000
      )
      Task {
        
        await AlertCenter.shared.presentAccountNotFound(onCreate: { [weak self] in
          Task {
            HUD.loading()
            let username = UsernameGenerator.generateRandomUsername()
            try await self?.regist(address: address, userName: username, flowKey: flowKey)
            HUD.dismissLoading()
            Router.popToRoot()
          }
        }, onCancel: {
          
        })
        
      }
    }
  
    // MARK: - Username Creation

    /// Show username creation screen with callback
    /// - Parameter callback: Callback with created username
    func createUserName(callback: @escaping (String) -> Void) {
        let viewModel = ImportUserNameViewModel { name in
            if !name.isEmpty {
                callback(name)
            }
        }
        Router.route(to: RouteMap.RestoreLogin.importUserName(viewModel))
    }

    // MARK: - Public Key Verification

    /// Verify public key matches account keys and perform login
    func checkPublicKey() {
        guard let account = account else {
            log.error("[Login] Account is nil")
            return
        }

        guard let cryptoKey = cryptoKey else {
            log.error("[Login] Crypto key is nil")
            return
        }

        // Get public keys from crypto key
        let p256Key = getP256PublicKey()
        let secp256Key = getSecp256PublicKey()

        // Find matching key in account
        let matchingKeys = account.keys.filter {
            $0.publicKey.description == p256Key || $0.publicKey.description == secp256Key
        }

        guard let selectedKey = matchingKeys.first else {
            log.error("[Login] Keys of account do not match the public key: P256=\(String(describing: p256Key)), SECP256k1=\(String(describing: secp256Key))")
            HUD.error(title: "not_find_address".localized)
            return
        }
        let address = account.address.hex

        // Validate key weight
        guard selectedKey.weight >= 1000 else {
            HUD.error(title: "account_key_weight_less".localized)
            return
        }

        // Validate key is not revoked
        guard !selectedKey.revoked else {
            HUD.error(title: "account_key_done_revoked_tips".localized)
            return
        }

        // Perform import login
        performImportLogin(address: address, flowKey: selectedKey)
    }

    // MARK: - Import Login

    /// Perform import login with backend API check
    /// - Parameters:
    ///   - address: Flow account address
    ///   - flowKey: Flow account key
    private func performImportLogin(address: String, flowKey: Flow.AccountKey) {
        Task {
            HUD.loading()
            do {
                let publicKey = flowKey.publicKey.description
                let response: Network.EmptyResponse = try await Network.requestWithRawModel(
                    FRWAPI.User.checkimport(publicKey)
                )

                if response.httpCode == 409 {
                    // Account already exists, login directly
                    try await performLogin(
                        address: address,
                        userName: "",
                        flowKey: flowKey,
                        isImport: false
                    )
                    HUD.dismissLoading()
                    Router.popToRoot()
                } else if response.httpCode == 200 {
                    // New account, create username first
                    HUD.dismissLoading()
                    createUserName { name in
                        Task {
                            HUD.loading()
                            try await self.performLogin(
                                address: address,
                                userName: name,
                                flowKey: flowKey,
                                isImport: true
                            )
                            HUD.dismissLoading()
                            Router.popToRoot()
                        }
                    }
                }
            } catch {
                // Handle 409 error code from Moya error
                if let code = error.moyaCode(), code == 409 {
                    do {
                        try await performLogin(
                            address: address,
                            userName: "",
                            flowKey: flowKey,
                            isImport: false
                        )
                        HUD.dismissLoading()
                        Router.popToRoot()
                    } catch {
                        log.error("[Login] Login with 409 error: \(error)")
                        HUD.dismissLoading()
                    }
                } else {
                    log.error("[Login] Check public key error: \(error)")
                    HUD.dismissLoading()
                }
            }
        }
    }

    private func regist(address: String, userName: String, flowKey: Flow.AccountKey) async throws {
      guard let keyProtocol = cryptoKey as? (any KeyProtocol) else {
        log.error("[regist] cryptoKey is empty or cannot be cast to KeyProtocol")
        return
      }
      _ = try await UserManager.shared.register(name: userName, key: flowKey, keyProvider: keyProtocol)
    }
}

extension String {
    /// Removes the "04" uncompressed public key prefix if needed
    /// - Returns: Public key string without the uncompressed key indicator (should be 128 hex chars)
    /// - Note: Standard uncompressed ECDSA public key format is "04" + 64 bytes (128 hex chars)
    ///         Preserves original case to ensure compatibility with Flow SDK
    func format() -> String {
        // Case 1: Standard uncompressed key (130 chars with "04" prefix)
        // Remove the "04" prefix to get 128 chars
        if self.count == 130 && self.hasPrefix("04") {
            let result = String(self.dropFirst(2))
            log.debug("[PublicKey] Removed '04' prefix from 130-char key")
            return result
        }
        
        // Case 2: Already formatted key (128 chars, no prefix needed)
        // Should NOT start with "04" - if it does, it's suspicious but keep as-is
        if self.count == 128 {
            if self.hasPrefix("04") {
                log.warning("[PublicKey] 128-char key starts with '04' - unusual but keeping as-is")
            }
            return self
        }
        
        // Case 3: Unexpected format - try to remove "04" if present
        if self.hasPrefix("04") {
            let result = String(self.dropFirst(2))
            log.warning("[PublicKey] Non-standard length (\(self.count) chars), removed '04' prefix -> \(result.count) chars")
            return result
        }
        
        // Case 4: No "04" prefix and non-standard length
        log.warning("[PublicKey] Non-standard public key format: \(self.count) chars, no '04' prefix")
        return self
    }
}
