//
//  Repo.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

struct Repo {
    var name: String = "Unknown Repo"
    var label: String = ""
    var description: String = "Description"
    var version: Double = 0.0
    var archs: [String] = []
    var url: URL = URL(fileURLWithPath: "/") // lol
    var tweaks: [Package] = []
}
