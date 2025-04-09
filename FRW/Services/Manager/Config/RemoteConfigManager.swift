//
//  RemoteConfigManager.swift
//  Flow Wallet
//
//  Created by Selina on 5/9/2022.
//

import CryptoKit
import Flow
import SwiftUI
import UIKit
import WalletCore

// MARK: - RemoteConfigManager

class RemoteConfigManager {
    // MARK: Lifecycle

    init() {
        do {
            try loadLocalConfig()
        } catch {
            log.error("[Firebase] load local file config failed:\(error)")
        }
        updateFromRemote()
    }

    // MARK: Internal

    static let shared = RemoteConfigManager()

    var config: Config?
    var contractAddress: ContractAddress?

    var isFailed: Bool = false
    var isStaging: Bool = false

    var emptyAddress: String {
        switch LocalUserDefaults.shared.flowNetwork.toFlowType() {
        case .mainnet:
            return "0x319e67f2ef9d937f"
        case .testnet:
            return "0xcb1cf3196916f9e2"
        default:
            return "0x319e67f2ef9d937f"
        }
    }

    var freeGasEnabled: Bool {
        if !remoteGreeGas {
            return false
        }
        return localGreeGas
    }

    var remoteGreeGas: Bool {
        if let config = config {
            return config.features.freeGas
        }
        return true
    }

    var payer: String {
        if !freeGasEnabled {
            return WalletManager.shared.getPrimaryWalletAddress() ?? emptyAddress
        }

        switch LocalUserDefaults.shared.flowNetwork.toFlowType() {
        case .mainnet:
            return config?.payer.mainnet.address ?? emptyAddress
        case .testnet:
            return config?.payer.testnet.address ?? emptyAddress
        default:
            return emptyAddress
        }
    }

    var payerKeyId: Int {
        if !freeGasEnabled {
            return 0
        }

        switch LocalUserDefaults.shared.flowNetwork.toFlowType() {
        case .mainnet:
            return config?.payer.mainnet.keyID ?? 0
        case .testnet:
            return config?.payer.testnet.keyID ?? 0
        case .crescendo:
            return config?.payer.crescendo?.keyID ?? 0
        default:
            return 0
        }
    }

    func getContarctAddress(_ network: FlowNetworkType) -> [String: String]? {
        switch network {
        case .mainnet:
            return contractAddress?.mainnet
        case .testnet:
            return contractAddress?.testnet
        }
    }

    func updateFromRemote() {
        fetchNews()
        do {
            let data: String = try FirebaseConfig.ENVConfig.fetch()
            let key = LocalEnvManager.shared.backupAESKey
            if let keyData = key.data(using: .utf8),
               let ivData = key.sha256().prefix(16).data(using: .utf8) {
                let decodeData = AES.decryptCBC(
                    key: keyData,
                    data: Data(hex: data),
                    iv: ivData,
                    mode: .pkcs7
                )!
                let decoder = JSONDecoder()
                let config = try decoder.decode(ENVConfig.self, from: decodeData)
                envConfig = config
                self.config = nil
                isStaging = false
                if let currentVersion = Bundle.main
                    .infoDictionary?["CFBundleShortVersionString"] as? String,
                    let version = envConfig?.version {
                    if version.compareVersion(to: currentVersion) == .orderedDescending {
                        self.config = envConfig?.prod
                    }
                }

                if self.config == nil {
                    self.config = envConfig?.staging
                    isStaging = true
                }
            }
            contractAddress = try FirebaseConfig.contractAddress.fetch(decoder: JSONDecoder())

            NotificationCenter.default.post(name: .remoteConfigDidUpdate, object: nil)
        } catch {
            do {
                log.warning("will load from local")
                try loadLocalConfig()
            } catch {
                isFailed = true
                log.error("load failed")
            }
        }
    }

    func fetchNews() {
        Task {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let list: [RemoteConfigManager.News] = try FirebaseConfig.news
                    .fetch(decoder: decoder)
                DispatchQueue.main.async {
                    WalletNewsHandler.shared.addRemoteNews(list)
                }
            } catch {
                log.error("[Firebase] fetch news failed. \(error)")
            }
        }
    }

    // MARK: Private

    private var envConfig: ENVConfig?
    @AppStorage(LocalUserDefaults.Keys.freeGas.rawValue)
    private var localGreeGas = true

    private func loadLocalConfig() throws {
        do {
            let data: String = try FirebaseConfig.ENVConfig.fetch()
            let key = LocalEnvManager.shared.backupAESKey
            if let keyData = key.data(using: .utf8),
               let ivData = key.sha256().prefix(16).data(using: .utf8) {
                let decodeData = AES.decryptCBC(
                    key: keyData,
                    data: Data(hex: data),
                    iv: ivData,
                    mode: .pkcs7
                )!
                let config = try? JSONDecoder().decode(ENVConfig.self, from: decodeData)
                self.config = config?.staging
            }
        } catch {
            log.warning("[firebase] load local error.\(error)")
        }

        contractAddress = try FirebaseConfig.contractAddress.fetchLocal()
    }
}

// MARK: FlowSigner

extension RemoteConfigManager: FlowSigner {
    var address: Flow.Address {
        .init(hex: payer)
    }

    var hashAlgo: Flow.HashAlgorithm {
        .SHA2_256
    }

    var signatureAlgo: Flow.SignatureAlgorithm {
        .ECDSA_P256
    }

    var keyIndex: Int {
        payerKeyId
    }

    func sign(signableData: Data, transaction: Flow.Transaction?) async throws -> Data {
        guard let transaction else {
            throw WalletError.emptyTransaction
        }
        
        let request = SignPayerRequest(
            transaction: transaction.voucher,
            message: .init(envelopeMessage: signableData.hexValue)
        )
        let signature: SignPayerResponse = try await Network
            .requestWithRawModel(FirebaseAPI.signAsPayer(request))
        return Data(hex: signature.envelopeSigs.sig)
    }

    func sign(voucher: FCLVoucher, signableData: Data) async throws -> Data {
        let request = SignPayerRequest(
            transaction: voucher,
            message: .init(envelopeMessage: signableData.hexValue)
        )
        let signature: SignPayerResponse = try await Network
            .requestWithRawModel(FirebaseAPI.signAsPayer(request))
        return Data(hex: signature.envelopeSigs.sig)
    }
}

extension RemoteConfigManager {
    var remoteVersion: String? {
        envConfig?.versionProd
    }
}
