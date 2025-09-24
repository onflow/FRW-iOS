//
//  ProfileManagerExample.swift
//  FRW
//
//  Created by cat on 9/24/25.
//  Usage example for ProfileManager with KeychainAccess
//

import Foundation

// MARK: - ProfileManager Usage Examples

extension ProfileManager {

    // Example 1: Basic profile creation and storage
    func exampleCreateProfile() {
        // Create a new profile
        let profile = ProfileModel(
            userId: "0x123abc",
            publicKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            nickname: "John Doe",
            avatar: "https://example.com/avatar.png",
            wallets: []
        )

        // Save to keychain
        saveProfile(profile)

        log.info("[Example] Profile created and saved for user: \(profile.userId)")
    }

    // Example 2: Load and update existing profile
    func exampleUpdateProfile() {
        let userId = "0x123abc"

        // Load existing profile
        guard let existingProfile = loadProfile(userId: userId) else {
            log.warning("[Example] Profile not found for user: \(userId)")
            return
        }

        // Update profile information
        updateProfile(
            userId: userId,
            nickname: "Updated Name",
            avatar: "https://example.com/new-avatar.png"
        )

        log.info("[Example] Profile updated for user: \(userId)")
    }

    // Example 3: Get all profiles
    func exampleGetAllProfiles() {
        let allProfiles = profiles
        log.info("[Example] Found \(allProfiles.count) profiles:")

        for profile in allProfiles {
            log.info("[Example] - User: \(profile.userId), Nickname: \(profile.nickname ?? "N/A")")
        }
    }

    // Example 4: Check if profile exists
    func exampleCheckProfileExists() {
        let userId = "0x123abc"

        if hasProfile(userId: userId) {
            log.info("[Example] Profile exists for user: \(userId)")
        } else {
            log.info("[Example] No profile found for user: \(userId)")
        }
    }

    // Example 5: Migration scenario
    func exampleMigrationScenario() {
        log.info("[Example] Valid user IDs from key validation:")
        for userId in validUserIds {
            if hasProfile(userId: userId) {
                log.info("[Example] - \(userId): Profile exists")
            } else {
                log.info("[Example] - \(userId): Creating new profile")
                // Extract public key for the user
                let publicKey = extractPublicKey(for: userId) ?? ""
                let profile = ProfileModel(userId: userId, publicKey: publicKey)
                saveProfile(profile)
            }
        }
    }

    // Example 6: Error handling
    func exampleErrorHandling() {
        do {
            let profiles = try keychainService.getAllProfiles()
            log.info("[Example] Successfully loaded \(profiles.count) profiles")
        } catch let error as ProfileError {
            switch error {
            case .profileNotFound(let userId):
                log.error("[Example] Profile not found: \(userId)")
            case .keychainError(let status):
                log.error("[Example] Keychain error: \(status)")
            case .invalidData:
                log.error("[Example] Invalid profile data")
            default:
                log.error("[Example] Unknown profile error: \(error)")
            }
        } catch {
            log.error("[Example] Unexpected error: \(error)")
        }
    }

    // Example 7: Profile statistics
    func exampleProfileStatistics() {
        let profileCount = getProfileCount()
        log.info("[Example] Profile Statistics:")
        log.info("[Example] - Total profiles: \(profileCount)")
        log.info("[Example] - Valid user IDs: \(validUserIds.count)")

        // Check profile coverage
        let profileCoverage = Double(profileCount) / Double(validUserIds.count) * 100
        log.info("[Example] - Profile coverage: \(String(format: "%.1f", profileCoverage))%")
    }

    // Example 8: Cleanup operations
    func exampleCleanupOperations() {
        log.info("[Example] Performing cleanup operations...")

        // Clear all profiles (use with caution)
        clearAllProfiles()

        log.info("[Example] All profiles cleared")
        log.info("[Example] Profile count after cleanup: \(getProfileCount())")
    }
}

// MARK: - Usage in ViewControllers or SwiftUI Views

/*
// Example usage in a view controller:

class ProfileViewController: UIViewController {
    private let profileManager = ProfileManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load existing profiles
        loadUserProfiles()

        // Listen to profile changes
        profileManager.$profiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
                self?.updateUI(with: profiles)
            }
            .store(in: &cancellables)
    }

    private func loadUserProfiles() {
        // Profiles are automatically loaded in ProfileManager init()
        print("Loaded \(profileManager.getProfileCount()) profiles")
    }

    private func createNewProfile() {
        let profile = ProfileModel(
            userId: "user123",
            publicKey: "0xabcdef1234567890...", // In real usage, extract from key validation
            nickname: "New User",
            avatar: nil
        )
        profileManager.saveProfile(profile)
    }

    private func updateUI(with profiles: [ProfileModel]) {
        // Update your UI with the profiles
        // For example, reload table view or update collection view
    }
}

// Example usage in SwiftUI:

struct ProfileListView: View {
    @StateObject private var profileManager = ProfileManager()

    var body: some View {
        NavigationView {
            List(profileManager.profiles, id: \.userId) { profile in
                ProfileRowView(profile: profile)
            }
            .navigationTitle("Profiles (\(profileManager.getProfileCount()))")
            .onAppear {
                // Profiles are automatically loaded
            }
        }
    }
}

struct ProfileRowView: View {
    let profile: ProfileModel

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: profile.avatar ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(Color.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(profile.nickname ?? "Unknown")
                    .font(.headline)
                Text(profile.userId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(profile.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
*/