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
    var paidRepoInfo: PaidRepoInfo? = nil
    var error: String? = nil
    
    var paymentAPI: payment {
        return payment(repo: self)
    }
    
    public struct payment: Encodable, Decodable, Hashable, Equatable {
        let repo: Repo
        
        var authURL: URL? {
            let udid = Device().uniqueIdentifier.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let model = Device().modelIdentifier.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: String(format: "authenticate?udid=%@&model=%@", udid, model), relativeTo: repo.payment_endpoint)
        }
    }
    
    // hashable stuff
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(label)
        hasher.combine(description)
        hasher.combine(version)
        hasher.combine(archs)
        hasher.combine(url)
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
            lhs.error == rhs.error
    }
}

struct RepoSource {
    var url: URL = URL(fileURLWithPath: "/")
    var suites: String? = nil
    var components: String = "main"
    var signedby: URL? = nil
}

struct PaidRepoInfo: Encodable, Decodable, Hashable, Equatable {
    var name: String
    var icon: URL
    var description: String
    var authentication_banner: PaidRepoInfoAuthBanner?
}

struct PaidRepoInfoAuthBanner: Encodable, Decodable, Hashable, Equatable {
    var message: String
    var button: String
}
