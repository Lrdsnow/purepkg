//
//  JBDetection.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import UIKit

enum jbType {
    case rootful
    case rootless
    case roothide
    case macos
    case tvOS_rootful
    case jailed
    case unknown
}

struct DeviceInfo {
    var major: Int = 0
    var sub: Int = 0
    var minor: Int = 0
    var beta: Bool = false
    var build_number: String = "0"
    var modelIdentifier: String = "Unknown Device"
}

func osString() -> String {
    #if targetEnvironment(macCatalyst)
    return "macOS"
    #elseif os(tvOS)
    return "tvOS"
    #else
    return "iOS"
    #endif
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
                                modelIdentifier: UIDevice.current.modelName)
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
                                modelIdentifier: "\(UIDevice.current.modelName) (\(modelIdentifier))")
    }
#endif
    return deviceInfo
}

public class Jailbreak {
    static func roothide_jbroot() -> URL? {
        let fileManager = FileManager.default
        let symlink = URL.documents.appendingPathComponent("roothide_jbroot")
        let symlinkURL = try? fileManager.destinationOfSymbolicLink(atPath: symlink.path)
        if fileManager.fileExists(atPath: symlinkURL ?? "") {
            return URL(fileURLWithPath: symlinkURL!)
        } else {
            try? fileManager.removeItem(at: symlink)
            let directoryPath = "/private/var/containers/Bundle/Application/"
            let directoryURL = URL(fileURLWithPath: directoryPath)
            
            do {
                let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                log(contents)
                for url in contents {
                    NSLog("\(url)")
                    if url.lastPathComponent.hasPrefix(".jbroot-") && url.hasDirectoryPath {
                        try? fileManager.createSymbolicLink(at: symlink, withDestinationURL: url)
                        return url
                    }
                }
            } catch {}
        }
        
        return nil
    }
    
    static func arch(_ appData: AppData? = nil) -> String {
        var jbarch = ""
        if let appData = appData {
            if appData.jbdata.jbarch != "" {
                return appData.jbdata.jbarch
            }
        }
        let jbtype = self.type(appData)
        if jbtype == .macos {
            jbarch = "darwin-amd64"
        } else if jbtype == .tvOS_rootful {
            jbarch = "appletvos-arm64"
        } else if jbtype == .rootful {
            jbarch = "iphoneos-arm"
        } else if jbtype == .rootless {
            jbarch = "iphoneos-arm64"
        } else if jbtype == .roothide {
            jbarch = "iphoneos-arm64e"
        } else {
            jbarch = ""
        }
        if let appData = appData {
            appData.jbdata.jbarch = jbarch
        }
        return jbarch
    }
    
    static func type(_ appData: AppData? = nil) -> (jbType) {
        #if targetEnvironment(simulator)
        return .tvOS_rootful
        #else
        var jbtype: jbType = .unknown
        if let appData = appData {
            if appData.jbdata.jbtype != .unknown {
                return appData.jbdata.jbtype
            }
        }
        let filemgr = FileManager.default
        if filemgr.fileExists(atPath: "/opt/procursus") {
            jbtype = .macos
        } else if filemgr.fileExists(atPath: "/private/etc/apt") {
            if #available(tvOS 9.0, *) {
                jbtype = .tvOS_rootful
            } else {
                jbtype = .rootful
            }
        } else if filemgr.fileExists(atPath: "/var/jb/etc/apt") {
            jbtype = .rootless
        } else if self.roothide_jbroot() != nil {
            jbtype = .roothide
        } else {
            jbtype = .jailed
        }
        if let appData = appData {
            appData.jbdata.jbtype = jbtype
        }
        return jbtype
        #endif
    }
    
    static func path(_ appData: AppData? = nil) -> String {
        #if targetEnvironment(simulator)
        var jbroot = "/var/jb"
        #else
        var jbroot = ""
        if let appData = appData {
            if appData.jbdata.jbroot != "" {
                return appData.jbdata.jbroot
            }
        }
        let jbtype = self.type(appData)
        if jbtype == .macos {
            jbroot = "/opt/procursus"
        } else if jbtype == .rootful || jbtype == .tvOS_rootful {
            jbroot = ""
        } else if jbtype == .rootless {
            jbroot = "/var/jb"
        } else if jbtype == .roothide {
            jbroot = self.roothide_jbroot()?.path ?? URL.documents.path
        } else {
            jbroot = URL.documents.path
        }
        if let appData = appData {
            appData.jbdata.jbroot = jbroot
        }
        #endif
        return jbroot
    }
    
    static func jailbreak() -> String? {
        let jburls: [(String, URL)] = [
            // iOS 15+ (semi-)Jailbreaks only
            ("Serotonin", URL(fileURLWithPath: "/var/mobile/Serotonin.jp2")),
            ("Palera1n (Nightly)", URL(fileURLWithPath: "/cores/binpack/.installed_overlay")),
            ("Palera1n", URL(fileURLWithPath: "/cores/jbloader")),
            ("Palera1n (Legacy)", URL(fileURLWithPath: "/jbin/post.sh")),
            ("Xina15", URL(fileURLWithPath: "/var/jb/.installed_xina15")),
            ("Xina15 (Legacy)", URL(fileURLWithPath: "/var/Liy/.procursus_strapped")),
            ("Fugu15 Max", URL(fileURLWithPath: "/var/jb/.installed_fugu15max")),
            ("NekoJB", URL(fileURLWithPath: "/var/jb/.installed_nekojb")),
            ("PureVirus", URL(fileURLWithPath: "/var/jb/.installed_purevirus")),
            ("Dopamine", URL(fileURLWithPath: "/var/jb/.installed_dopamine")),
            ("Fugu15 Rootful", URL(fileURLWithPath: "/.Fugu15")),
            ("Cherimoya", URL(fileURLWithPath: "/var/jb/.installed_cherimoya"))
        ]
        for (name, url) in jburls {
            log("\(url.path)")
            if FileManager.default.fileExists(atPath: url.path) {
                log("jb: \(name)")
                return name
            } else {
                log("does not exist")
            }
        }
        return nil
    }
    
    static func tweakArchSupported(_ pkgarch: String, _ appData: AppData? = nil) -> Bool {
        /* ill uncomment this when i actually add conversion lol
        let jbtype = self.type()
        if jbtype == .rootful {
            if pkgarch == "iphoneos-arm" {
                return true
            } else {
                return false
            }
        } else if jbtype == .rootless {
            if pkgarch == "iphoneos-arm" || pkgarch == "iphoneos-arm64" {
                return true
            } else {
                return false
            }
        } else if jbtype == .roothide {
            if pkgarch == "iphoneos-arm" || pkgarch == "iphoneos-arm64" || pkgarch == "iphoneos-arm64e" {
                return true
            } else {
                return false
            }
        }
         */
        return self.arch(appData) == pkgarch
    }
}
