//
//  AppData.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

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


//#if TARGET_IOS_MAJOR_13
//class AppData: ObservableObject {
//    @Published var repoSources: [RepoSource] = []
//    @Published var repos: [Repo] = []
//    @Published var pkgs: [Package] = []
//    @Published var installed_pkgs: [Package] = []
//    @Published var jbdata: JBData = JBData()
//    @Published var deviceInfo: DeviceInfo = DeviceInfo()
//    @Published var queued: PKGQueue = PKGQueue()
//
//    static let shared = AppData()
//}
//#else
class AppData {
    var repoSources: [RepoSource] = []
    var repos: [Repo] = []
    var pkgs: [Package] = []
    var installed_pkgs: [Package] = []
    var jbdata: JBData = JBData()
    var deviceInfo: DeviceInfo = DeviceInfo()
    var queued: PKGQueue = PKGQueue()
}
//#endif
