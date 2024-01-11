//
//  AppData.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

struct JBData {
    var jbtype: jbtype = .jailed
    var jbroot: String = ""
}

class AppData: ObservableObject {
    @Published var repo_urls: [URL?] = [URL(string: "https://apt.procurs.us/dists/iphoneos-arm64-rootless/1800/main/binary-iphoneos-arm64"), URL(string:"https://havoc.app"), URL(string:"https://repo.chariz.com"), URL(string: "https://dekotas.org/")]
    @Published var repos: [Repo] = []
    @Published var pkgs: [Package] = []
    @Published var jbdata: JBData = JBData()
    @Published var deviceInfo: DeviceInfo = DeviceInfo()
    
    static let shared = AppData()
}
