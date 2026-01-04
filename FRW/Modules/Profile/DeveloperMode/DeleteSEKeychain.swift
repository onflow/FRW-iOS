//
//  DeleteSEKeychain.swift
//  FRW
//
//  Created by cat on 10/9/25.
//

import SwiftUI
import FlowWalletKit
import KeychainAccess

struct DeleteSEKeychain: RouteableView {
  // MARK: Internal

  var title: String = "Delete SE"

  let isShow: Bool = true

  var body: some View {
    VStack {
      if isShow {
        content
      } else {
        Text("hahaha")
      }
    }
    .padding(18)
    .applyRouteable(self)
  }

  var content: some View {
    ScrollView {
      VStack(spacing: 10) {
        // Delete ALL Keychain data (recommended)
        Button {
          deleteAllAppKeychain()
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("🗑️ Delete ALL Keychain Data")
                .fontWeight(.semibold)
              Text("Removes all app-related Keychain entries")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
          }
          .padding(16)
          .background(Color.red.opacity(0.1))
        }

        // Individual delete options
        Button {
          deleteAllSEKeychain()
        } label: {
          HStack {
            Text("Delete All SecureEnclaveKey")
            Spacer()
          }
          .padding(16)
          .background(Color.Theme.Background.fill1)
        }

        Button {
          deleteAllSPKeychain()
        } label: {
          HStack {
            Text("Delete All Seed Phrase Keys")
            Spacer()
          }
          .padding(16)
          .background(Color.Theme.Background.fill1)
        }

        Button {
          deleteAllPrivateKeychain()
        } label: {
          HStack {
            Text("Delete All Private Keys")
            Spacer()
          }
          .padding(16)
          .background(Color.Theme.Background.fill1)
        }
      }
      .cornerRadius(16)
    }
    .font(.inter())
    .foregroundStyle(Color.Theme.Text.black8)
    .background(
      Color.LL.Neutrals.background.ignoresSafeArea()
    )
  }

  // MARK: Private

  private func deleteAllSEKeychain() {
    let keychain = SecureEnclaveKey.KeychainStorage
    do {
      try keychain.removeAll()
      HUD.success(title: "done")
    } catch {
      HUD.error(title: "Failed", message: error.localizedDescription)
    }
  }

  private func deleteAllSPKeychain() {
    let keychain = SeedPhraseKey.seedPhraseStorage
    do {
      try keychain.removeAll()

      // Also remove backup storage
      let backupKeychain = SeedPhraseKey.seedPhraseBackupStorage
      try backupKeychain.removeAll()

      HUD.success(title: "done")
    } catch {
      HUD.error(title: "Failed", message: error.localizedDescription)
    }
  }

  private func deleteAllPrivateKeychain() {
    let keychain = PrivateKey.PKStorage
    do {
      try keychain.removeAll()
      HUD.success(title: "done")
    } catch {
      HUD.error(title: "Failed", message: error.localizedDescription)
    }
  }

  // Delete all app-related Keychain data
  private func deleteAllAppKeychain() {
    var errors: [String] = []
    let bundleId = Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet"

    // List of all Keychain services used by the app
    let services = [
      // FlowWalletKit storage
      bundleId + ".SE",
      bundleId + ".SP",
      bundleId + ".SP.backup",
      bundleId + ".PK",

      // Legacy services
      "io.outblock.lilico.securekey",
      "com.flowfoundation.wallet.securekey",

      // App-specific services
      bundleId + ".local",
      bundleId + ".uuid",
      bundleId + ".backup.phrase",
      bundleId,
      "com.flowfoundation.frw.profiles"
    ]

    do {
      for service in services {
        let keychain = Keychain(service: service)
        do {
          try keychain.removeAll()
        } catch {
          errors.append("\(service): \(error.localizedDescription)")
        }
      }

      if errors.isEmpty {
        HUD.success(title: "All Keychain Data Deleted")
      } else {
        let errorMessage = errors.joined(separator: "\n")
        HUD.error(title: "Partial Success", message: "Some services failed:\n\(errorMessage)")
      }
    }
  }
}

#Preview {
  DeleteSEKeychain()
}
