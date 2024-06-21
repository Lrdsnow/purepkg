//
//  Package.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import UniformTypeIdentifiers

struct Package: Encodable, Decodable {
    var id: String = "uwu.lrdsnow.unknown" // Package
    var name: String = "Unknown Tweak" // Name
    var author: String = "Unknown Author" // Maintainer/Author
    var arch: String = "" // Architecture
    var installed_size: Int = 0
    var path: String = "" // Filename
    var desc: String = "Unknown Desc" // Description
    var section: String = "Tweaks" // Section
    var version: String = "" // Version
    var versions: [String] = [] // Versions
    var installedVersion: String = "" // for Updates
    var depends: [DepPackage] = [] // Depends
    var paid: Bool = false // Paid (::commercial)
    var installDate: Date? = nil
    var depiction: URL? = nil
    var icon: URL? = nil
    var debPath: String? = nil
    var repo: Repo = Repo()
    
    func supportedVers(_ inputString: String? = nil) -> String? {
        func versionString(_ version: (Int, Int, Int)) -> String {
            if version.2 == 0 && version.1 == 0 {
                return "\(Device().osString) \(version.0)"
            } else if version.2 == 0 {
                return "\(Device().osString) \(version.0).\(version.1)"
            } else {
                return "\(Device().osString) \(version.0).\(version.1).\(version.2)"
            }
        }
        
        if let inputString = inputString {
            let components = inputString.components(separatedBy: " - ")
            let firstComponent = components[0].components(separatedBy: ".")
            let secondComponent = components[1].components(separatedBy: ".")
            let min = (
                firstComponent.count > 0 ? Int(firstComponent[0]) ?? 0 : 0,
                firstComponent.count > 1 ? Int(firstComponent[1]) ?? 0 : 0,
                firstComponent.count > 2 ? Int(firstComponent[2]) ?? 0 : 0
            )
            let max = (
                secondComponent.count > 0 ? Int(secondComponent[0]) ?? 0 : 0,
                secondComponent.count > 1 ? Int(secondComponent[1]) ?? 0 : 0,
                secondComponent.count > 2 ? Int(secondComponent[2]) ?? 0 : 0
            )
            
            return "\(versionString(min)) - \(versionString(max))"
            
        } else {
            let firmReqs = self.depends.filter { $0.id == "firmware" }
            guard !firmReqs.isEmpty else {
                return nil
            }
            
            var minVersion: (Int, Int, Int)?
            var maxVersion: (Int, Int, Int)?
            
            for firmReq in firmReqs {
                let splitVer = firmReq.reqVer.version.split(separator: ".")
                let version = (
                    splitVer.count > 0 ? Int(splitVer[0]) ?? 0 : 0,
                    splitVer.count > 1 ? Int(splitVer[1]) ?? 0 : 0,
                    splitVer.count > 2 ? Int(splitVer[2]) ?? 0 : 0
                )
                
                if firmReq.reqVer.minVer {
                    if minVersion == nil || version > minVersion! {
                        minVersion = version
                    }
                } else {
                    if maxVersion == nil || version < maxVersion! {
                        maxVersion = version
                    }
                }
            }
            
            if let minVersion = minVersion, let maxVersion = maxVersion, minVersion.0 != 0, maxVersion.0 != 0 {
                return "\(versionString(minVersion)) - \(versionString(maxVersion))"
            } else if let minVersion = minVersion, minVersion.0 != 0 {
                return "\(versionString(minVersion))+"
            } else if let maxVersion = maxVersion, maxVersion.0 != 0 {
                return "\(versionString(maxVersion)) and below"
            } else {
                return nil
            }
        }
    }

    func supportedByDevice(_ inputString: String? = nil) -> Bool? {
        let ver = Device().version
        if let inputString = inputString {
            let components = inputString.components(separatedBy: " - ")
            let firstComponent = components[0].components(separatedBy: ".")
            let secondComponent = components[1].components(separatedBy: ".")
            let min = (
                firstComponent.count > 0 ? Int(firstComponent[0]) ?? 0 : 0,
                firstComponent.count > 1 ? Int(firstComponent[1]) ?? 0 : 0,
                firstComponent.count > 2 ? Int(firstComponent[2]) ?? 0 : 0
            )
            let max = (
                secondComponent.count > 0 ? Int(secondComponent[0]) ?? 0 : 0,
                secondComponent.count > 1 ? Int(secondComponent[1]) ?? 0 : 0,
                secondComponent.count > 2 ? Int(secondComponent[2]) ?? 0 : 0
            )
            if ver >= min && ver <= max {
                return true
            } else {
                return false
            }
        } else {
            let firmReqs = self.depends.filter({ $0.id == "firmware" })
            for firmReq in firmReqs {
                let splitVer = firmReq.reqVer.version.split(separator: ".")
                let reqVer = (
                    splitVer.count > 0 ? Int(splitVer[0]) ?? 0 : 0,
                    splitVer.count > 1 ? Int(splitVer[1]) ?? 0 : 0,
                    splitVer.count > 2 ? Int(splitVer[2]) ?? 0 : 0
                )
                if reqVer.0 != 0 {
                    if firmReq.reqVer.minVer && ver < reqVer {
                        return false
                    } else if !firmReq.reqVer.minVer && ver > reqVer {
                        return false
                    }
                }
            }
            return true
        }
    }
}

struct verReq: Encodable, Decodable, Equatable {
    var req: Bool = false
    var version: String = ""
    var minVer: Bool = false // if it should compare the ver as min ver or max ver
}

struct DepPackage: Encodable, Decodable {
    var id: String = "uwu.lrdsnow.unknown"
    var reqVer: verReq = verReq()
}

@available(iOS 14.0, tvOS 14.0, *)
extension UTType {
    static var deb: UTType {
        UTType(exportedAs: "org.debian.deb-archive")
    }
}
