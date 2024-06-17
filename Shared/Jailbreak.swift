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
    case visionOS_rootless
    case roothide
    case macos
    case tvOS_rootful
    case watchOS_rootful
    case jailed
    case unknown
}

enum TweakCompatibility {
    case supported
    case conversionReq
    case unsupported
}

public class Jailbreak {
    var roothide_jbroot: URL? {
        get {
            #if os(iOS)
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
            #endif
            
            return nil
        }
    }
    
    var arch: String {
        get {
            return "iphoneos-arm64"
#if os(macOS)
            return "darwin-\(getMacOSArchitecture() ?? "unknown")"
#elseif os(tvOS)
            return "appletvos-arm64"
#elseif os(watchOS)
            return "watchos-arm"
#elseif os(visionOS)
            return "xros-arm64"
#else
            let jbtype = self.type
            if jbtype == .rootful {
                return "iphoneos-arm"
            } else if jbtype == .roothide {
                return "iphoneos-arm64e"
            } else {
                return "iphoneos-arm64"
            }
#endif
        }
    }
    
    var pretty_type: String {
        get {
            let type = self.type
            return (type == .rootful || type == .tvOS_rootful || type == .watchOS_rootful) ? "Rootful" : (type == .rootless || type == .visionOS_rootless) ? "Rootless" : type == .roothide ? "Roothide" : "Jailed"
        }
    }
    
    var type: jbType {
        get {
            let filemgr = FileManager.default
#if targetEnvironment(simulator)
            return .rootless
#else
            if filemgr.fileExists(atPath: "/opt/procursus") {
                return .macos
            } else if filemgr.fileExists(atPath: "/private/etc/apt") {
#if os(tvOS)
                return .tvOS_rootful
#elseif os(watchOS)
                return .watchOS_rootful
#else
                return .rootful
#endif
            } else if filemgr.fileExists(atPath: "/var/jb/etc/apt") {
#if os(visionOS)
                return .visionOS_rootless
#else
                return .rootless
#endif
            } else if self.roothide_jbroot != nil {
                return .roothide
            } else {
                return .jailed
            }
#endif
        }
    }
    
    var path: String {
        get {
#if targetEnvironment(simulator)
            return "/var/jb"
#else
            let jbtype = self.type
            if jbtype == .macos {
                return "/opt/procursus"
            } else if jbtype == .rootful || jbtype == .tvOS_rootful || jbtype == .watchOS_rootful {
                return ""
            } else if jbtype == .rootless {
                return "/var/jb"
            } else if jbtype == .roothide {
                return self.roothide_jbroot?.path ?? URL.documents.path
            } else {
                return URL.documents.path
            }
#endif
        }
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
        #elseif os(iOS)
        let jbtype = Jailbreak().type
        if jbtype == .jailed {
            if self.arch == "iphoneos-arm64" {
                return .supported
            } else {
                return .unsupported
            }
        } else if jbtype == .rootful {
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
        #else
        return (self.arch == Jailbreak().arch) ? .supported : .unsupported
        #endif
    }
}
