//
//  Package.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

struct Package: Encodable, Decodable {
    var id: String = "uwu.lrdsnow.unknown" // Package
    var name: String = "Unknown Tweak" // Name
    var author: String = "Unknown Author" // Maintainer/Author
    var arch: String = "" // Architecture
    var installed_size: Int = 0
    var path: String = "" // Filename
    var desc: String = "Unknown Desc" // Description
    var section: String = "Tweaks" // Section
    var version: String = "" // Version
    var versions: [String] = [] // Versions
    var installedVersion: String = "" // for Updates
    var depends: [DepPackage] = [] // Depends
    var depiction: URL? = nil
    var icon: URL? = nil
    var debPath: String? = nil
    var repo: Repo = Repo()
}

struct verReq: Encodable, Decodable {
    var req: Bool = false
    var version: String = ""
    var minVer: Bool = false // if it should compare the ver as min ver or max ver
}

struct DepPackage: Encodable, Decodable {
    var id: String = "uwu.lrdsnow.unknown"
    var reqVer: verReq = verReq()
}
