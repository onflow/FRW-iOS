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
    associatedtype KeyType

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

    /// Computed property to access the crypto key (for protocol extension use)
    private var key: KeyType? {
        get { cryptoKey }
        set { cryptoKey = newValue }
    }

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
    
    guard let address = try? wallet?.ethAddress(),
          let publicKey = try? wallet?.ethPublicKey().hexValue else {
      //TODO:
      return
    }
    
    let flowKey = Flow.AccountKey(
      publicKey: Flow.PublicKey(hex: publicKey),
      signAlgo: .ECDSA_SECP256k1,
      hashAlgo: .SHA2_256,
      weight: 1000
    )
    Task {
      
      await AlertCenter.shared.presentAccountNotFound(onCreate: {
        self.createUserName{ [weak self] name in
          Task {
            HUD.loading()
            try await self?.performLogin(
              address: address,
              userName: name,
              flowKey: flowKey,
              isImport: true
            )
            HUD.dismissLoading()
            Router.popToRoot()
          }
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

//    /// Wrapper to call UserManager.shared.importLogin
//    /// Subclasses must implement this to handle their specific KeyType
//    /// - Parameters:
//    ///   - address: Flow account address
//    ///   - userName: Username for new account
//    ///   - flowKey: Flow account key
//    ///   - isImport: Whether this is a new import
//    func performLogin(
//        address: String,
//        userName: String,
//        flowKey: Flow.AccountKey,
//        isImport: Bool
//    ) async throws {
//      
//    }
}
