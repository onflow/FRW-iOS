//
//  FCLScripts.swift
//  Flow Wallet
//
//  Created by Selina on 5/9/2022.
//

import Flow
import Foundation

// MARK: - FCLScripts

class FCLScripts {
    private static let PreAuthzReplacement = "$PRE_AUTHZ_REPLACEMENT"
    private static let AddressReplacement = "$ADDRESS_REPLACEMENT"
    private static let KeyIDReplacement = "$KEY_ID_REPLACEMENT"
    private static let PayerAddressReplacement = "$PAYER_ADDRESS_REPLACEMENT"
    private static let SignatureReplacement = "$SIGNATURE_REPLACEMENT"
    private static let UserSignatureReplacement = "$USER_SIGNATURE_REPLACEMENT"
    private static let AccountProofReplacement = "$ACCOUNT_PROOF_REPLACEMENT"
    private static let NonceReplacement = "$NONCE_REPLACEMENT"
    private static let NetworkReplacement = "$NETWORK"
    private static let ReasonReplacement = "$REASON"

    private static let preAuthzResponse = """
        {
            "status": "APPROVED",
            "data": {
                "f_type": "PreAuthzResponse",
                "f_vsn": "1.0.0",
                "proposer": {
                    "f_type": "Service",
                    "f_vsn": "1.0.0",
                    "type": "authz",
                    "uid": "frw#authz",
                    "endpoint": "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
                    "method": "EXT/RPC",
                    "identity": {
                        "address": "$ADDRESS_REPLACEMENT",
                        "keyId": $KEY_ID_REPLACEMENT
                    }
                },
                "payer": [
                    {
                        "f_type": "Service",
                        "f_vsn": "1.0.0",
                        "type": "authz",
                        "uid": "frw#authz",
                        "endpoint": "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
                        "method": "EXT/RPC",
                        "identity": {
                            "address": "$PAYER_ADDRESS_REPLACEMENT",
                            "keyId": 0
                        }
                    }
                ],
                "authorization": [
                    {
                        "f_type": "Service",
                        "f_vsn": "1.0.0",
                        "type": "authz",
                        "uid": "frw#authz",
                        "endpoint": "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
                        "method": "EXT/RPC",
                        "identity": {
                            "address": "$ADDRESS_REPLACEMENT",
                            "keyId": $KEY_ID_REPLACEMENT
                        }
                    }
                ]
            },
            "type": "FCL:VIEW:RESPONSE"
        }
    """

    private static let authnResponse = """
        {
          "f_type": "PollingResponse",
          "f_vsn": "1.0.0",
          "status": "APPROVED",
          "reason": null,
          "data": {
            "f_type": "AuthnResponse",
            "f_vsn": "1.0.0",
            "addr": "$ADDRESS_REPLACEMENT",
            "services": [
              {
                "f_type": "Service",
                "f_vsn": "1.0.0",
                "type": "authn",
                "uid": "frw#authn",
                "endpoint": "ext:0x000",
                "id": "$ADDRESS_REPLACEMENT",
                "identity": {
                  "address": "$ADDRESS_REPLACEMENT"
                },
                "provider": {
                  "f_type": "ServiceProvider",
                  "f_vsn": "1.0.0",
                  "address": "$ADDRESS_REPLACEMENT",
                  "name": "Flow Wallet",
                  "description": "Flow Wallet is built from the ground up for Flow Blockchain!",
                  "color": "#41CC5D",
                  "supportEmail": "wallet@flow.com",
                  "website": "https://frw-link.lilico.app/wc",
                  "icon": "https://lilico.app/logo_mobile.png"
                }
              },
              $PRE_AUTHZ_REPLACEMENT
              $USER_SIGNATURE_REPLACEMENT
              $ACCOUNT_PROOF_REPLACEMENT
              {
                "f_type": "Service",
                "f_vsn": "1.0.0",
                "type": "authz",
                "uid": "frw#authz",
                "endpoint": "ext:0x000",
                "method": "EXT/RPC",
                "identity": {
                  "address": "$ADDRESS_REPLACEMENT",
                  "keyId": $KEY_ID_REPLACEMENT
                }
              }
            ],
            "paddr": null
          },
          "type": "FCL:VIEW:RESPONSE"
        }
    """

    private static let signMessageResponse = """
        {
          "f_type": "PollingResponse",
          "f_vsn": "1.0.0",
          "status": "APPROVED",
          "reason": null,
          "data": {
            "f_type": "CompositeSignature",
            "f_vsn": "1.0.0",
            "addr": "$ADDRESS_REPLACEMENT",
            "keyId": $KEY_ID_REPLACEMENT,
            "signature": "$SIGNATURE_REPLACEMENT"
          },
          "type": "FCL:VIEW:RESPONSE"
        }
    """

    private static let authnResponseUserSignature = """
        {
            "f_type": "Service",
            "f_vsn": "1.0.0",
            "type": "user-signature",
            "uid": "frw#user-signature",
            "endpoint": "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
            "method": "EXT/RPC"
        },
    """

    private static let authnResponseAccountProof = """
        {
            "f_type": "Service",
            "f_vsn": "1.0.0",
            "type": "account-proof",
            "uid": "frw#account-proof",
            "endpoint": "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
            "method": "EXT/RPC",
            "network": "$NETWORK",
            "data": {
              "f_type": "account-proof",
              "f_vsn": "2.0.0",
              "address": "$ADDRESS_REPLACEMENT",
              "nonce": "$NONCE_REPLACEMENT",
              "signatures": [
                {
                  "f_type": "CompositeSignature",
                  "f_vsn": "1.0.0",
                  "addr": "$ADDRESS_REPLACEMENT",
                  "keyId": $KEY_ID_REPLACEMENT,
                  "signature": "$SIGNATURE_REPLACEMENT"
                }
              ]
            }
        },
    """

    private static let authzResponse = """
        {
          "f_type": "PollingResponse",
          "f_vsn": "1.0.0",
          "status": "APPROVED",
          "reason": null,
          "data": {
            "f_type": "CompositeSignature",
            "f_vsn": "1.0.0",
            "addr": "$ADDRESS_REPLACEMENT",
            "keyId": $KEY_ID_REPLACEMENT,
            "signature": "$SIGNATURE_REPLACEMENT"
          },
          "type": "FCL:VIEW:RESPONSE"
        }
    """
    
    private static let rejectResponse = """
        {
          "f_type": "PollingResponse",
          "f_vsn": "1.0.0",
          "status": "DECLINED",
          "reason": "$REASON",
          "type": "FCL:VIEW:RESPONSE"
        }
        """
}

extension FCLScripts {
    private static func generateAuthnPreAuthz() async throws -> String {
        let payer = RemoteConfigManager.shared.payer

        if RemoteConfigManager.shared.freeGasEnabled {
            let keyId = try await FlowNetwork.getLastBlockAccountKeyId(address: payer)

            let str = """
                {
                    "f_type": "Service",
                    "f_vsn": "1.0.0",
                    "type": "pre-authz",
                    "uid": "frw#pre-authz",
                    "endpoint": "ios://pre-authz.lilico.app",
                    "method": "EXT/RPC",
                    "data": {
                        "address": "\(payer)",
                        "keyId": \(keyId)
                    }
                },
            """

            return str
        } else {
            return ""
        }
    }

    private static func generateAuthnAccountProof(
        accountProofSign: String,
        address: String,
        nonce: String,
        keyId: Int = 0
    ) -> String {
        let dict = [
            AddressReplacement: address,
            SignatureReplacement: accountProofSign,
            NonceReplacement: nonce,
            KeyIDReplacement: "\(keyId)",
            NetworkReplacement: LocalUserDefaults.shared.flowNetwork.rawValue,
        ]
        return FCLScripts.authnResponseAccountProof.replace(from: dict)
    }
}

extension FCLScripts {
    static func generatePreAuthzResponse(address: String, keyIndex: Int = 0) -> String {
        let dict = [
            AddressReplacement: address,
            PayerAddressReplacement: RemoteConfigManager.shared.payer,
            KeyIDReplacement: String(keyIndex),
        ]
        return FCLScripts.preAuthzResponse.replace(from: dict)
    }

    static func generateSignMessageResponse(
        message: String,
        address: String,
        keyId: Int = 0
    ) async -> String? {
        let data = Flow.DomainTag.user.normalize + Data(hex: message)
        guard let signedData = try? await WalletManager.shared.sign(signableData: data) else {
            return nil
        }
        
        let hex = signedData.hexString
        let dict = [
            AddressReplacement: address,
            SignatureReplacement: hex,
            KeyIDReplacement: "\(keyId)",
        ]
        return FCLScripts.signMessageResponse.replace(by: dict)
    }

    static func generateAuthnResponse(
        accountProofSign: String = "",
        nonce: String = "",
        address: String,
        keyId: Int = 0
    ) async throws -> String {
        let authz = try await generateAuthnPreAuthz()

        var confirmedAccountProofSign = accountProofSign
        if !accountProofSign.isEmpty {
            confirmedAccountProofSign = generateAuthnAccountProof(
                accountProofSign: accountProofSign,
                address: address,
                nonce: nonce,
                keyId: keyId
            )
        }

        let dict = [
            AddressReplacement: address,
            PreAuthzReplacement: authz,
            UserSignatureReplacement: authnResponseUserSignature,
            AccountProofReplacement: confirmedAccountProofSign,
            KeyIDReplacement: "\(keyId)",
        ]
        return FCLScripts.authnResponse.replace(from: dict)
    }

    static func generateAuthzResponse(
        address: String,
        signature: String,
        keyId: Int = 0
    ) -> String {
        let dict = [
            AddressReplacement: address,
            SignatureReplacement: signature,
            KeyIDReplacement: "\(keyId)",
        ]
        return FCLScripts.authzResponse.replace(from: dict)
    }
    
    static func genertateRejectResponse(reason: String) -> String {
        return FCLScripts.rejectResponse.replace(from: [ReasonReplacement: reason])
    }
}
