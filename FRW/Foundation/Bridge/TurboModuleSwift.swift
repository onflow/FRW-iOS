import Foundation
import Factory

@objc(TurboModuleSwift)
class TurboModuleSwift: NSObject {

    @objc
    static func getJWT() async throws -> String {
        return try await Network.fetchIDToken()
    }

    @objc
    static func getCurrentAddress() -> String? {
        return WalletManager.shared.selectedAccountAddress
    }

    @objc
    static func getNetwork() -> String? {
        return WalletManager.shared.currentNetwork.name
    }

    @objc
    static func sign(hexData: String) async throws -> String {
        return try await WalletManager.shared.sign(signableData: Data(hexData.hexValue)).hexString
    }
}
