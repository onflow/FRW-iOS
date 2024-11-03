//
//  EventTrack.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation
import Mixpanel

class EventTrack {
    
    static func start(token: String) {
        Mixpanel.initialize(token: token)
        Mixpanel.mainInstance().registerSuperProperties(common())
#if DEBUG
        Mixpanel.mainInstance().loggingEnabled = true
#endif
    }
    
    /// super properties
    private static func common() -> [String: String] {
        var param: [String: String] = [:]
        
        let scriptVersion = CadenceManager.shared.version
        param["cadence_script_version"] = scriptVersion
        
        return param
    }
    //MARK: - Action
    
    /// call when switch user
    static func switchUser() {
        guard let uid = UserManager.shared.activatedUID else {
            // reset ?
            return
        }
        Mixpanel.mainInstance().identify(distinctId: uid)
    }
    
    static func updateNetwork() {
        // flow_network
    }
    
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
