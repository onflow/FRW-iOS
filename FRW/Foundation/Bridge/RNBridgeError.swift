//
//  RNBridgeError.swift
//  FRW
//
//  Created by cat on 7/31/25.
//

import Foundation

enum RNBridgeError: Error {
  case scanInvalidProvider
  case invalidParameters
  case sendToFlowConfigurationError
  case mnemonicGenerationFailed
  case mnemonicSaveFailed
  case keyGenerationFailed
  case invalidMnemonic
  case accountCreationFailed
  case walletInitializationFailed
  case signFailed
}
