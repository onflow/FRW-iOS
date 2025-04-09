//
//  WalletManager+Signer.swift
//  FRW
//
//  Created by Hao Fu on 9/4/2025.
//

import Foundation
import Flow
import FlowWalletKit

// MARK: FlowSigner

extension WalletManager: FlowSigner {
    
    var defaultSigners: [FlowSigner] {
        if RemoteConfigManager.shared.freeGasEnabled {
            return [WalletManager.shared, RemoteConfigManager.shared]
        }
        return [WalletManager.shared]
    }
    
    var keyIndex: Int {
        currentMainAccount?.keyIndex ?? 0
    }
    
    var address: Flow.Address {
        currentMainAccount?.address ?? .init(hex: "")
    }

    public func sign(signableData: Data, transaction: Flow.Transaction?) async throws -> Data {
        return try await sign(signableData: signableData)
    }

    public func sign(signableData: Data) async throws -> Data {
        guard let account = currentMainAccount else {
            throw WalletError.emptyMainAccount
        }
        
        do {
            return try await account.sign(signableData: signableData)
        } catch FlowWalletKit.WalletError.failedPassSecurityCheck {
            HUD.error(title: "verify_failed".localized)
            throw WalletError.securityVerifyFailed
        } catch {
            throw error
        }
    }

    private func userSecretSign() -> Bool {
        UserManager.shared.userType != .phrase
    }
}

extension WalletManager: SecurityCheckDelegate {
    func verify() async throws -> Bool {
        return await SecurityManager.shared.SecurityVerify()
    }
}
    
