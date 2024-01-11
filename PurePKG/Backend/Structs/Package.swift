//
//  Package.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

struct Package {
    var id: String = "uwu.lrdsnow.unknown" // Package
    var name: String = "Unknown Tweak" // Name
    var author: String = "Unknown Author" // Maintainer/Author
    var arch: String = "" // Architecture
    var path: String = "" // Filename
    var desc: String = "Unknown Desc" // Description
    var section: String = "Tweaks" // Section
    var version: String = "" // Version
    var depends: [String] = [] // Depends
    var depiction: URL? = nil
    var icon: URL? = nil
    var repo: Repo = Repo()
}
