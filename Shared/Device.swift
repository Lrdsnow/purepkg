//
//  Device.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/14/24.
//

import Foundation
#if !os(macOS)
import UIKit
#endif

#if !os(watchOS) && !os(macOS)
public extension UIDevice {
    var modelName: String {
        #if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Unknown"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
        return identifier
    }
}
#endif

#if os(watchOS) || os(macOS)
func getModelName() -> String {
    #if targetEnvironment(simulator)
    return ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
    #else
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
    #endif
}
#endif

#if os(macOS)
func getMacOSArchitecture() -> String? {
    let process = Process()
    process.launchPath = "/usr/bin/uname"
    process.arguments = ["-m"]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    
    if let rawArch = output?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        if rawArch.contains("x86") {
            return "amd64"
        } else if rawArch.contains("arm") || rawArch.contains("aarch") {
            return "arm64"
        }
    }
    return nil
}
#endif

class Device {
    var build_number: String {
        get {
#if targetEnvironment(simulator)
            return ""
#elseif os(watchOS) || os(macOS)
            return ProcessInfo.processInfo.operatingSystemVersionString
#else
            let systemAttributes = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
            return systemAttributes?["ProductBuildVersion"] as? String ?? "0"
#endif
        }
    }
    
    var pretty_version: String {
        get {
            let version = self.version
            return "\(version.0).\(version.1)\(version.2 == 0 ? "" : ".\(version.2)")"
        }
    }
    
    var version: (Int, Int, Int) {
        get {
#if os(watchOS) || os(macOS)
            let systemVersion = ProcessInfo().operatingSystemVersion
            return (systemVersion.majorVersion, systemVersion.minorVersion, systemVersion.patchVersion)
#else
            let systemVersion = UIDevice.current.systemVersion
            let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
            if versionComponents.count >= 2 {
                let major = versionComponents[0]
                let minor = versionComponents[1]
                let patch = versionComponents.count >= 3 ? versionComponents[2] : 0
                return (major, minor, patch)
            } else {
                return (99,99,99)
            }
#endif
        }
    }
    
    var modelIdentifier: String {
        get {
#if os(watchOS) || os(macOS)
            return getModelName()
#else
            return UIDevice.current.modelName
#endif
        }
    }
    
    var uniqueIdentifier: String {
        get {
#if (os(iOS) || os(tvOS)) && !targetEnvironment(simulator)
            if UserDefaults.standard.bool(forKey: "usePaymentAPI") {
                let gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY)
                typealias MGCopyAnswerFunc = @convention(c) (CFString) -> CFString
                let MGCopyAnswer = unsafeBitCast(dlsym(gestalt, "MGCopyAnswer"), to: MGCopyAnswerFunc.self)
                return MGCopyAnswer("UniqueDeviceID" as CFString) as String
            } else {
                return ""
            }
#else
            return ""
#endif
        }
    }
    
    var osString: String {
        get {
#if os(macOS)
            return "macOS"
#elseif os(tvOS)
            return "tvOS"
#elseif os(watchOS)
            return "watchOS"
#elseif os(visionOS)
            return "visionOS"
#else
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPadOS"
            } else {
                return "iOS"
            }
#endif
        }
    }
}
