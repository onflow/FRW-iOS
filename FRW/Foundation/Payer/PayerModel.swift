//
//  PayerModel.swift
//  FRW
//
//  Created by lmcmz on 8/10/2025.
//

import Flow
import Foundation

// MARK: - Unified Context/Overrides/Decision

enum FlowTxPhase {
  case request
  case response
  case error
}

struct FlowTxOverrides {
  let payer: Flow.Address?
  let signers: [FlowSigner]?
  let authorizers: [Flow.Address]?

  init(payer: Flow.Address? = nil,
       signers: [FlowSigner]? = nil,
       authorizers: [Flow.Address]? = nil) {
    self.payer = payer
    self.signers = signers
    self.authorizers = authorizers
  }
}

enum FlowTxDecision {
  case retry(FlowTxOverrides)
  case noRetry
}

struct FlowTxContext {
  let phase: FlowTxPhase
  let funcName: String

  // identities
  let from: Flow.Address
  let proposer: Flow.Address?

  // execution
  let cadenceHash: String?
  let txId: Flow.ID?

  // participants
  let payer: Flow.Address?
  let authorizers: [Flow.Address]?

  // defaults for request phase
  let defaultSigners: [FlowSigner]?
  let defaultPayer: Flow.Address?
}
