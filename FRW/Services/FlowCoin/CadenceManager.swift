//
//  CadenceManager.swift
//  FRW
//
//  Created by cat on 2024/3/2.
//

import SwiftUI

// MARK: - CadenceManager

class CadenceManager {
    
    static let signatureHeader = "x-signature"
    static let signatureVersion = "x-signature-version"
    
    // MARK: Lifecycle

    private init() {
        loadLocalCache()
        fetchScript()
    }

    // MARK: Internal

    static let shared = CadenceManager()

    var version: String = ""
    var scripts: CadenceScript!

    var current: CadenceModel {
        switch currentNetwork {
        case .testnet:
            return scripts.testnet
        case .mainnet:
            return scripts.mainnet
        default:
            return scripts.mainnet
        }
    }

    // MARK: Private

    private let localVersion = "2.13"

    private func loadLocalCache() {
        if let response = loadCache() {
            scripts = response.scripts
            version = response.version ?? localVersion
            log.info("[Cadence] cache version is \(String(describing: response.version))")
            EventTrack.shared
                .registerCadence(
                    scriptVersion: version,
                    cadenceVersion: current.version ?? ""
                )
        } else {
            do {
                guard let filePath = Bundle.main
                    .path(forResource: "scripts", ofType: "json")
                else {
                    log.error("CadenceManager -> loadFromLocalFile error: no local file")
                    return
                }

                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                var providers = try? JSONDecoder().decode(CadenceResponse.self, from: data)
                if (providers == nil) {
                    let model = try? JSONDecoder().decode(Network.Response<CadenceResponse>.self, from: data)
                    providers = model?.data
                }
                
                guard let providers else {
                    log.error(CadenceError.decodeLocalFileFailed)
                    return
                }
                
                scripts = providers.scripts
                version = providers.version ?? localVersion
                EventTrack.shared
                    .registerCadence(
                        scriptVersion: version,
                        cadenceVersion: current.version ?? ""
                    )
                log.info("[Cadence] local version is \(String(describing: providers.version))")
            } catch {
                log.error("CadenceManager -> decode failed", context: error)
            }
        }
    }

    private func fetchScript() {
        Task {
            do {
                let response = try await Network.requestWithRawResponse(FRWAPI.Cadence.list)
                
                guard let signature = response.response?.value(forHTTPHeaderField: CadenceManager.signatureHeader) else {
                    log.error(CadenceError.emptyScriptSignature)
                    return
                }
                
                // If signature is not valid, don't update local script.
                guard let verified = try? verifySignature(signature: signature, data: response.data), verified else {
                    log.error(CadenceError.invaildScriptSignature)
                    return
                }
                
                guard let model = try? FRWAPI.jsonDecoder.decode(Network.Response<CadenceResponse>.self, from: response.data),
                      let data = model.data else {
                    log.error(CadenceError.decodeScriptFailed)
                    return
                }
                                
                await MainActor.run {
                    // first call before
                    self.saveCache(response: data)
                    self.scripts = data.scripts
                    if let version = data.version {
                        self.version = version
                        log.info("[Cadence] remote version is \(String(describing: version))")
                    }
                    EventTrack.shared
                        .registerCadence(
                            scriptVersion: self.version,
                            cadenceVersion: self.current.version ?? ""
                        )
                }
            } catch {
                log.error("CadenceManager -> fetch failed", context: error)
            }
        }
    }

    private func saveCache(response: CadenceResponse) {
        guard response.version != version, let file = filePath() else {
            log.info("[Cadence] same version")
            return
        }
        do {
            let data = try JSONEncoder().encode(response)
            try data.write(to: file)
        } catch {
            log.error("[Cadence] save data failed.\(error)")
        }
    }

    private func loadCache() -> CadenceResponse? {
        guard let file = filePath() else {
            return nil
        }

        if !FileManager.default.fileExists(atPath: file.relativePath) {
            return nil
        }

        do {
            let data = try Data(contentsOf: file)
            let response = try JSONDecoder().decode(CadenceResponse.self, from: data)
            return response
        } catch {
            log.error("[Cadence] load cache \(error)")
            return nil
        }
    }

    private func filePath() -> URL? {
        do {
            let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                .appendingPathComponent("cadence")
            if !FileManager.default.fileExists(atPath: root.relativePath) {
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            }
            let file = root.appendingPathComponent("script")
            return file
        } catch {
            log.warning("[Cadence] create failed. \(error)")
        }
        return nil
    }
}


public extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func toFunc() -> String? {
        guard let decodeStr = fromBase64() else {
            log.error("[Cadence] base decode failed")
            return nil
        }

        let result = decodeStr.replacingOccurrences(of: "<platform_info>", with: platformInfo())
        return result
    }

    private func platformInfo() -> String {
        let version = Bundle.main
            .infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let model = isDevModel ? "(Dev)" : ""
        return "iOS-\(version)-\(buildVersion)\(model)"
    }
}
