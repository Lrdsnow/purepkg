//
//  Repo.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

public struct Repo: Encodable, Decodable, Hashable, Equatable {
    let id = UUID()
    var name: String = "Unknown Repo"
    var label: String = ""
    var description: String = "Description"
    var version: Double = 0.0
    var archs: [String] = []
    var url: URL = URL(fileURLWithPath: "/") // lol
    var tweaks: [Package] = []
    var component: String = "main"
    var payment_endpoint: URL? = nil
    var error: String? = nil
    
    // hashable stuff
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(label)
        hasher.combine(description)
        hasher.combine(version)
        hasher.combine(archs)
        hasher.combine(url)
        hasher.combine(payment_endpoint)
        hasher.combine(error)
    }
    
    // equatable stuff
    public static func == (lhs: Repo, rhs: Repo) -> Bool {
        return lhs.name == rhs.name &&
            lhs.label == rhs.label &&
            lhs.description == rhs.description &&
            lhs.version == rhs.version &&
            lhs.archs == rhs.archs &&
            lhs.url == rhs.url &&
            lhs.payment_endpoint == rhs.payment_endpoint &&
            lhs.error == rhs.error
    }
}

struct RepoSource {
    var url: URL = URL(fileURLWithPath: "/")
    var suites: String? = nil
    var components: String = "main"
    var signedby: URL? = nil
}
