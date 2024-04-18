//
//  JBDetection.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#else
import UIKit
#endif

enum jbType {
    case rootful
    case rootless
    case roothide
    case macos
    case tvOS_rootful
    case watchOS_rootful
    case visionOS_rootful
    case jailed
    case unknown
}

enum TweakCompatibility {
    case supported
    case conversionReq
    case unsupported
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
                for url in contents {
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
#if os(macOS)
        jbarch = "darwin-\(getMacOSArchitecture() ?? "unknown")"
#elseif os(tvOS)
        jbarch = "appletvos-arm64"
#elseif os(watchOS)
        jbarch = "watchos-arm"
#elseif os(visionOS)
        jbarch = "xros-arm64"
#else
        if jbtype == .rootful {
            jbarch = "iphoneos-arm"
        } else if jbtype == .rootless || jbtype == .jailed {
            jbarch = "iphoneos-arm64"
        } else if jbtype == .roothide {
            jbarch = "iphoneos-arm64e"
        }
#endif
        DispatchQueue.main.async {
            if let appData = appData {
                appData.jbdata.jbarch = jbarch
            }
        }
        return jbarch
    }
    
    static func type(_ appData: AppData? = nil) -> (jbType) {
        let filemgr = FileManager.default
        #if targetEnvironment(simulator)
        return .jailed
        #elseif os(tvOS)
        if filemgr.fileExists(atPath: "/private/etc/apt") {
            return .tvOS_rootful
        } else {
            return .jailed
        }
        #elseif os(watchOS)
        if filemgr.fileExists(atPath: "/private/etc/apt") {
            return .watchOS_rootful
        } else {
            return .jailed
        }
        #elseif os(visionOS)
        if filemgr.fileExists(atPath: "/private/etc/apt") {
            return .visionOS_rootful
        } else {
            return .jailed
        }
        #else
        var jbtype: jbType = .unknown
        if let appData = appData {
            if appData.jbdata.jbtype != .unknown {
                return appData.jbdata.jbtype
            }
        }
        if filemgr.fileExists(atPath: "/opt/procursus") {
            jbtype = .macos
        } else if filemgr.fileExists(atPath: "/private/etc/apt") {
            jbtype = .rootful
        } else if filemgr.fileExists(atPath: "/var/jb/etc/apt") {
            jbtype = .rootless
        } else if self.roothide_jbroot() != nil {
            jbtype = .roothide
        } else {
            jbtype = .jailed
        }
        DispatchQueue.main.async {
            if let appData = appData {
                appData.jbdata.jbtype = jbtype
            }
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
        } else if jbtype == .rootful || jbtype == .tvOS_rootful || jbtype == .watchOS_rootful {
            jbroot = ""
        } else if jbtype == .rootless {
            jbroot = "/var/jb"
        } else if jbtype == .roothide {
            jbroot = self.roothide_jbroot()?.path ?? URL.documents.path
        } else {
            jbroot = URL.documents.path
        }
        DispatchQueue.main.async {
            if let appData = appData {
                appData.jbdata.jbroot = jbroot
            }
        }
        #endif
        return jbroot
    }
    
    static func jailbreak() -> String? {
        let jburls: [(String, URL)] = [
            // iOS 15+ (semi-)Jailbreaks only
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
            ("Cherimoya", URL(fileURLWithPath: "/var/jb/.installed_cherimoya")),
            ("Serotonin", URL(fileURLWithPath: "/var/mobile/Serotonin.jp2"))
        ]
        for (name, url) in jburls {
            if FileManager.default.fileExists(atPath: url.path) {
                return name
            } else {}
        }
        return nil
    }
}

extension Package {
    func tweakCompatibility(_ appData: AppData? = nil) -> TweakCompatibility {
        #if targetEnvironment(simulator)
        return .supported
        #else
        let jbtype = Jailbreak.type()
        if jbtype == .rootful {
            if self.arch == "iphoneos-arm" {
                return .supported
            } else {
                return .unsupported
            }
        } else if jbtype == .rootless {
            if self.arch == "iphoneos-arm" {
                return .supported
            } else if self.arch == "iphoneos-arm64" {
                return .conversionReq
            } else {
                return .unsupported
            }
        } else if jbtype == .roothide {
            if self.arch == "iphoneos-arm" {
                return .supported
            } else if self.arch == "iphoneos-arm64" || self.arch == "iphoneos-arm64e" {
                return .conversionReq
            } else {
                return .unsupported
            }
        } else {
            return .unsupported
        }
        #endif
    }
}
