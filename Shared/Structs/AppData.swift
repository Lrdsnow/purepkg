//
//  AppData.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct JBData {
    var jbtype: jbType = .unknown
    var jbroot: String = ""
    var jbarch: String = ""
}

struct installStatus {
    var message: String = "Queued..."
    var percentage: Double = 0.0
}

struct PKGQueue {
    var install: [Package] = []
    var uninstall: [Package] = []
    var status: [String:installStatus] = [:]
    var all: [String] = [] // just a way to keep track of all the ids
}

class AppData: ObservableObject {
    @Published var repoSources: [RepoSource] = []
    @Published var repos: [Repo] = []
    @Published var pkgs: [Package] = []
    @Published var installed_pkgs: [Package] = []
    @Published var available_updates: [Package] = []
    @Published var jbdata: JBData = JBData()
    @Published var deviceInfo: DeviceInfo = DeviceInfo()
    @Published var queued: PKGQueue = PKGQueue()
    
    @Published var test = false
    
    static let shared = AppData()
}
