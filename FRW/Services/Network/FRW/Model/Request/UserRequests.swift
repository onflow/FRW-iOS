//
//  UserRequests.swift
//  Flow Wallet
//
//  Created by Selina on 9/6/2022.
//

import Foundation
import MapKit

// MARK: - RegisterRequest

struct RegisterRequest: Codable {
    let username: String?
    let accountKey: AccountKey
    let deviceInfo: DeviceInfoRequest
}

// MARK: - AccountKey

struct AccountKey: Codable {
    let hashAlgo: Int
    let publicKey: String
    let signAlgo: Int
    var weight: Int = 1000
}

// MARK: - LoginRequest

struct LoginRequest: Codable {
//    let publicKey: String
    let signature: String
    let accountKey: AccountKey
    let deviceInfo: DeviceInfoRequest
    var address: String? = nil
}

// MARK: - RestoreImportRequest

struct RestoreImportRequest: Codable {
    let username: String?
    let accountKey: AccountKey
    let deviceInfo: DeviceInfoRequest
    let address: String
}

// MARK: - DeviceInfoRequest

struct DeviceInfoRequest: Codable {
    let deviceId: String
    let ip: String?
    let name: String?
    let type: String?
    let userAgent: String?

    let continent: String?
    let continentCode: String?
    let country: String?
    let countryCode: String?
    let regionName: String?
    let city: String?
    let district: String?
    let zip: String?
    let lat: Double?
    let lon: Double?
    let timezone: String?
    let currency: String?
    let isp: String?
    let org: String?
}

extension DeviceInfoRequest {
    func showApp() -> String {
        userAgent ?? ""
    }

    func showIP() -> String {
        ip ?? ""
    }

    func showLocation() -> String {
        var res = ""
        if city != nil {
            res += city!
        }
        if country != nil {
            res += ",\(country!)"
        }
        return res
    }

    func coordinate() -> CLLocationCoordinate2D {
        guard let latitude = lat, let longitude = lon else {
            return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - NetworkRequest

struct NetworkRequest: Codable {
    let accountKey: AccountKey
    let network: String
}

// MARK: - create address request
struct CreateAddress: Codable {
    let hashAlgorithm: Int
    let publicKey: String
    let signatureAlgorithm: Int
    let weight: Int
}
