//
//  JBDetection.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import UIKit

enum jbtype {
    case rootful
    case rootless
    case roothide
    case jailed
}

struct DeviceInfo {
    var major: Int = 0
    var sub: Int = 0
    var minor: Int = 0
    var beta: Bool = false
    var build_number: String = "0"
    var modelIdentifier: String = "Unknown Device"
}

func getDeviceInfo() -> DeviceInfo {
    var deviceInfo = DeviceInfo()
#if targetEnvironment(simulator)
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let sub = versionComponents[1]
        let minor = versionComponents.count >= 3 ? versionComponents[2] : 0
        deviceInfo = DeviceInfo(major: major,
                                sub: sub,
                                minor: minor,
                                beta: false,
                                build_number: "0",
                                modelIdentifier: "Simulator")
    }
#else
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let sub = versionComponents[1]
        let minor = versionComponents.count >= 3 ? versionComponents[2] : 0
        
        // Check for beta and get model and <A12 check
        let systemAttributes = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
        let build_number = systemAttributes?["ProductBuildVersion"] as? String ?? "0"
        let beta = build_number.count > 6
        let gestAltCache = NSDictionary(contentsOfFile: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")
        let cacheExtras: [String: Any] = gestAltCache?["CacheExtra"] as? [String: Any] ?? [:]
        let modelIdentifier = cacheExtras["0+nc/Udy4WNG8S+Q7a/s1A"] as? String ?? cacheExtras["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String ?? "Unknown Device"
        //
        
        deviceInfo = DeviceInfo(major: major,
                                sub: sub,
                                minor: minor,
                                beta: beta,
                                build_number: build_number,
                                modelIdentifier: modelIdentifier)
    }
#endif
    return deviceInfo
}

public class Jailbreak {
    static func roothide_jbroot() -> URL? {
        let directoryPath = "/private/var/containers/Bundle/Application/"

        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directoryPath)

        do {
            let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            for url in contents {
                NSLog("\(url)")
                if url.lastPathComponent.hasPrefix(".jbroot-") && url.hasDirectoryPath {
                    return url
                }
            }
        } catch {}

        return nil
    }

    
    static func type() -> (jbtype) {
        let filemgr = FileManager.default
        if filemgr.fileExists(atPath: "/etc/apt") {
            return .rootful
        } else if filemgr.fileExists(atPath: "/var/jb/etc/apt") {
            return .rootless
        } else if self.roothide_jbroot() != nil {
            return .roothide
        } else {
            return .jailed
        }
    }
    
    static func path() -> String {
        let jbtype = self.type()
        if jbtype == .rootful {
            return ""
        } else if jbtype == .rootless {
            return "/var/jb"
        } else if jbtype == .roothide {
            return self.roothide_jbroot()!.path
        } else {
            return URL.documents.path
        }
    }
}
