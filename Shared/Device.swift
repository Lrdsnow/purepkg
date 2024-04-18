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

struct DeviceInfo {
    var major: Int = 0
    var minor: Int = 0
    var patch: Int = 0
    var build_number: String = "0"
    var modelIdentifier: String = "Unknown Device"
}

func osString() -> String {
    #if os(macOS)
    return "macOS"
    #elseif os(tvOS)
    return "tvOS"
    #else
    return "iOS"
    #endif
}


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

func getDeviceInfo() -> DeviceInfo {
    var deviceInfo = DeviceInfo()
#if os(watchOS) || os(macOS)
    let systemVersion = ProcessInfo().operatingSystemVersion
    deviceInfo = DeviceInfo(major: systemVersion.majorVersion,
                            minor: systemVersion.minorVersion,
                            patch: systemVersion.patchVersion,
                            build_number: ProcessInfo.processInfo.operatingSystemVersionString,
                            modelIdentifier: getModelName())
#elseif targetEnvironment(simulator)
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let minor = versionComponents[1]
        let patch = versionComponents.count >= 3 ? versionComponents[2] : 0
        deviceInfo = DeviceInfo(major: major,
                                minor: minor,
                                patch: patch,
                                build_number: "0",
                                modelIdentifier: UIDevice.current.modelName)
    }
#else
    let systemVersion = UIDevice.current.systemVersion
    let versionComponents = systemVersion.split(separator: ".").compactMap { Int($0) }
    if versionComponents.count >= 2 {
        let major = versionComponents[0]
        let minor = versionComponents[1]
        let patch = versionComponents.count >= 3 ? versionComponents[2] : 0
        
        // get model
        let systemAttributes = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")
        let build_number = systemAttributes?["ProductBuildVersion"] as? String ?? "0"
        //
        
        deviceInfo = DeviceInfo(major: major,
                                minor: minor,
                                patch: patch,
                                build_number: build_number,
                                modelIdentifier: UIDevice.current.modelName)
    }
#endif
    return deviceInfo
}
