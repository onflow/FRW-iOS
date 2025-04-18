//
//  EventTrack.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Combine
import Foundation
import Mixpanel

// MARK: - EventTrack

class EventTrack {
    // MARK: Internal

    static let shared = EventTrack()

    static func start(token: String) {
        Mixpanel.initialize(token: token)
        EventTrack.shared.registerAllSuper()
        EventTrack.shared.monitor()
        #if DEBUG
//        Mixpanel.mainInstance().loggingEnabled = true
        #endif
    }

    // MARK: Private

    private var cancellableSet = Set<AnyCancellable>()

    private func monitor() {
        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] _ in
                self?.switchUser()
            }.store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: .networkChange)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.registerNetwork()
            }.store(in: &cancellableSet)
    }
}

extension EventTrack {
    // MARK: - Action

    static func send(event: EventTrackNameProtocol, properties: [String: MixpanelType]? = nil) {
        Mixpanel
            .mainInstance()
            .track(event: event.name, properties: properties)
    }

    static func timeBegin(event: EventTrackNameProtocol) {
        Mixpanel.mainInstance().time(event: event.name)
    }

    static func timeEnd(event: EventTrackNameProtocol, properties: [String: MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event.name, properties: properties)
    }
}

// MARK: - update Super

extension EventTrack {
    private func registerAllSuper() {
        Mixpanel
            .mainInstance()
            .registerSuperProperties([Superkey.deviceId: UUIDManager.appUUID()])
        let env: String
        if RemoteConfigManager.shared.isStaging {
            env = "staging"
        } else if isDevModel {
            env = "development"
        } else {
            env = "production"
        }

        Mixpanel.mainInstance().registerSuperProperties([Superkey.env: env])
        registerNetwork()
        registerCadence(scriptVersion: "", cadenceVersion: "")
        switchUser()
    }

    /// call when switch user
    private func switchUser() {
        guard let uid = UserManager.shared.activatedUID else {
            // reset ?
            return
        }
        Mixpanel.mainInstance().identify(distinctId: uid)
    }

    private func registerNetwork() {
        let network = currentNetwork.rawValue
        Mixpanel.mainInstance().registerSuperProperties([Superkey.network: network])
    }

    func registerCadence(scriptVersion: String, cadenceVersion: String) {
        Mixpanel.mainInstance().registerSuperProperties([Superkey.scriptVersion: scriptVersion])
        Mixpanel
            .mainInstance()
            .registerSuperProperties([Superkey.cadenceVersion: cadenceVersion])
    }
}

// MARK: EventTrack.Superkey

extension EventTrack {
    enum Superkey {
        static let network = "flow_network"
        static let scriptVersion = "cadence_script_version"
        static let cadenceVersion = "cadence_version"
        static let deviceId = "fw_device_id"
        static let env = "app_env"
    }
}
