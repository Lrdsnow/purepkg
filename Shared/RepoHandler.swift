//
//  RepoHandler.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public class RepoHandler {
    static func getSavedRepoFileName(_ url: URL) -> String {
        let absoluteString = url.absoluteString.hasSuffix(".gpg") ? url.absoluteString : url.deletingPathExtension().absoluteString;
        return absoluteString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_");    }
    
    static func getSavedRepoFilePath(_ url: URL) -> String {
        return "\(Jailbreak().path)/var/lib/apt/purepkglists/\(getSavedRepoFileName(url))";
    }
    
    static func getRepos(_ repoSources: [RepoSource], completion: @escaping (Repo) -> Void) {
        spawnRootHelper(args: [ "removeAllRepoFiles" ])
        for repoSource in repoSources {
            let url = repoSource.url
            log("getting repo: \(url.absoluteString)")
            let startTime = CFAbsoluteTimeGetCurrent()
            Networking.get_dict_compressed(url.appendingPathComponent("Release")) { (result, error) in
                if let result = result {
                    log("got repo! \(url.appendingPathComponent("Release").absoluteString)")
                    var Repo = Repo()
                    Repo.url = url
                    Repo.name = result["Origin"] ?? "Unknown Repo"
                    Repo.label = result["Label"] ?? ""
                    Repo.description = result["Description"] ?? "Description"
                    Repo.archs = (result["Architectures"] ?? "").split(separator: " ").map { String($0) }
                    Repo.version = Double(result["Version"] ?? "0.0") ?? 0.0
                    Repo.component = repoSource.components
                    do { Repo.payment_endpoint = URL(string: try String(contentsOf: url.appendingPathComponent("payment_endpoint"))) } catch {}
                    
                    let currentArch = Jailbreak().arch
                    if !Repo.archs.contains(currentArch) {
                        Repo.error = "Unsupported architecture '\(currentArch)'"
                        spawnRootHelper(args: ["clearRepoFiles", url.absoluteString])
                        completion(Repo)
                        return
                    }
                    
#if !os(watchOS) && !targetEnvironment(simulator)
                    if UserDefaults.standard.bool(forKey: "checkSignature") {
                        log("getting repo signature: \(url.appendingPathComponent("Release.gpg"))")
                        var signature_ok: Bool = false;
                        Networking.get(url.appendingPathComponent("Release.gpg")) { (result, error) in
                            if error != nil {
                                switch Jailbreak().type {
                                case .macos:
                                    log("Error: No signature found for \(url.absoluteString)")
                                    Repo.error = "Error: No signature found for \(url.absoluteString)"
                                    completion(Repo);
                                    return
                                case .tvOS_rootful, .rootful, .rootless, .roothide:
                                    log("Warning: No signature found for \(url.absoluteString)")
                                    Repo.error = "Warning: No signature found for \(url.absoluteString)"
                                default:
                                    log("Warning: No signature found for \(url.absoluteString)")
                                }
                            }
                            
                            if let result = result {
                                let savedReleasePath = self.getSavedRepoFilePath(url.appendingPathComponent("Release"));
                                var savedReleaseGPGPath = self.getSavedRepoFilePath(url.appendingPathComponent("Release.gpg"));
                                if let signedBy = repoSource.signedby {
                                    savedReleaseGPGPath = signedBy.path
                                }
                                log("verify \(savedReleasePath) with \(savedReleaseGPGPath)")
                                
                                var validAndTrusted = false;
                                var errorStr: String = "";
                                if (error == nil) {
                                    var counter = 0;
                                    while (!FileManager.default.fileExists(atPath: savedReleaseGPGPath)) {
                                        usleep(50000);
                                        counter += 1;
                                        if (counter > 50) { // 5 seconds
                                            NSLog("\(savedReleaseGPGPath) wait timeout");
                                            break;
                                        }
                                    }
                                    
                                    counter = 0;
                                    while (!FileManager.default.fileExists(atPath: savedReleasePath)) {
                                        usleep(50000);
                                        counter += 1;
                                        if (counter > 50) { // 5 seconds
                                            NSLog("\(savedReleasePath) wait timeout");
                                            break;
                                        }
                                    }
                                    
                                }
                                
                                validAndTrusted = APTWrapper.verifySignature(key: savedReleaseGPGPath, data: savedReleasePath, error: &errorStr);
                                
                                if (!validAndTrusted || !errorStr.isEmpty) {
                                    log("Error: Invalid signature at \(url.appendingPathComponent("Release.gpg"))");
                                    signature_ok = false;
                                    if Jailbreak().type == .tvOS_rootful || Jailbreak().type == .visionOS_rootless {
                                        if errorStr != "" {
                                            Repo.error = errorStr
                                        } else {
                                            Repo.error = "Warning: Invalid signature at \(url.appendingPathComponent("Release.gpg"))"
                                        }
                                    } else {
                                        if errorStr != "" {
                                            Repo.error = errorStr
                                        } else {
                                            Repo.error = "Error: Invalid signature at \(url.appendingPathComponent("Release.gpg"))"
                                        }
                                        let endTime = CFAbsoluteTimeGetCurrent()
                                        let elapsedTime = endTime - startTime
                                        log("Time taken to process/get repo \(url.absoluteString): \(elapsedTime) seconds")
                                        completion(Repo);
                                        return
                                    }
                                } else {
                                    signature_ok = true;
                                    log("Good signature at \(url.appendingPathComponent("Release.gpg"))");
                                    
                                    Networking.get(url.appendingPathComponent("InRelease")) { (result, error) in
                                        if let error = error {
                                            log("Error getting InRelease: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                    }
#endif
                    var pkgsURL = url
                    if repoSource.suites != nil {
                        let repoComponents = repoSource.components
                        pkgsURL = url.appendingPathComponent(repoComponents).appendingPathComponent("binary-\(Jailbreak().arch)")
                    }
                    log("gettings repo tweaks from: \(pkgsURL.appendingPathComponent("Packages").absoluteString)")
                    Networking.get_compressed(pkgsURL.appendingPathComponent("Packages")) { (result, error, actualURL) in
                        if let result = result {
                            log("got repo tweaks! \(actualURL!.absoluteString)")
                            var tweaks: [Package] = []
                            for tweak in result {
                                let lowercasedTweak = tweak.reduce(into: [String: String]()) { result, element in
                                    let (key, value) = element
                                    result[key.lowercased()] = value
                                }
                                var Tweak = Package()
                                Tweak.arch = lowercasedTweak["architecture"] ?? ""
                                if Tweak.tweakCompatibility() == .supported {
                                    Tweak.id = lowercasedTweak["package"] ?? "uwu.lrdsnow.unknown"
                                    Tweak.desc = lowercasedTweak["description"] ?? "Description"
                                    Tweak.author = lowercasedTweak["author"] ?? lowercasedTweak["maintainer"] ?? "Unknown Author"
                                    Tweak.name = lowercasedTweak["name"] ?? lowercasedTweak["package"] ?? "Unknown Tweak"
                                    Tweak.section = lowercasedTweak["section"] ?? "Tweaks"
                                    Tweak.path = lowercasedTweak["filename"] ?? ""
                                    Tweak.version = lowercasedTweak["version"] ?? "0.0"
                                    Tweak.versions.append(lowercasedTweak["version"] ?? "0.0")
                                    Tweak.installed_size = Int(lowercasedTweak["installed-size"] ?? "0") ?? 0
                                    Tweak.paid = (lowercasedTweak["tag"] ?? "").contains("::commercial")
                                    for dep in (tweak["Depends"] ?? "").components(separatedBy: ", ").map({ String($0) }) {
                                        var tweakDep = DepPackage()
                                        let components = dep.components(separatedBy: " ")
                                        if components.count >= 1 {
                                            tweakDep.id = components[0]
                                        }
                                        if components.count >= 2 {
                                            var ver = components[1...].joined(separator: " ")
                                            ver = ver.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                                            let verComponents = ver.components(separatedBy: " ")
                                            if verComponents.count >= 2 {
                                                tweakDep.reqVer.req = true
                                                let compare = verComponents[0]
                                                let truVer = verComponents[1]
                                                tweakDep.reqVer.version = truVer
                                                if compare == ">=" {
                                                    tweakDep.reqVer.minVer = true
                                                }
                                            }
                                        }
                                        if tweakDep.id != "" {
                                            Tweak.depends.append(tweakDep)
                                        }
                                    }
                                    if let depiction = lowercasedTweak["depiction"] {
                                        Tweak.depiction = URL(string: depiction)
                                    }
                                    if let depiction = lowercasedTweak["sileodepiction"] {
                                        Tweak.depiction = URL(string: depiction)
                                    }
                                    if let icon = lowercasedTweak["icon"] {
                                        Tweak.icon = URL(string: icon)
                                    }
                                    Tweak.repo = Repo
                                    Tweak.author = Tweak.author.removingBetweenAngleBrackets()
                                    if let index = tweaks.firstIndex(where: { $0.id == Tweak.id }) {
                                        var existingTweak = tweaks[index]
                                        existingTweak.versions += [Tweak.version]
                                        tweaks[index] = existingTweak
                                        if Tweak.version.compare(existingTweak.version, options: .numeric) == .orderedDescending {
                                            Tweak.versions = existingTweak.versions
                                            tweaks[index] = Tweak
                                        }
                                    } else {
                                        tweaks.append(Tweak)
                                    }
                                }
                            }
                            Repo.tweaks = tweaks
                            let endTime = CFAbsoluteTimeGetCurrent()
                            let elapsedTime = endTime - startTime
                            log("Time taken to process/get repo \(url.absoluteString): \(elapsedTime) seconds")
                            completion(Repo)
                        } else if let error = error {
                            log("Error getting repo tweaks: \(error.localizedDescription)")
                            Repo.error = "Error getting repo tweaks: \(error.localizedDescription)"
                            let endTime = CFAbsoluteTimeGetCurrent()
                            let elapsedTime = endTime - startTime
                            log("Time taken to process/get repo \(url.absoluteString): \(elapsedTime) seconds")
                            completion(Repo)
                        }
                    }
                } else if let error = error {
                    log("Error getting repo: \(error.localizedDescription)")
                    var repo = Repo()
                    repo.url = url
                    repo.error = "Error getting repo: \(error.localizedDescription)"
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let elapsedTime = endTime - startTime
                    log("Time taken to process/get repo \(url.absoluteString): \(elapsedTime) seconds")
                    completion(repo)
                }
            }
        }
    }
    
    static func getAptSources(_ directoryPath: String) -> [RepoSource] {
        do {
            log("Repo Sources Directory: \(directoryPath)")
            let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            
            let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
            
            log("source Files: \(sourceFiles)")
            
            var repos: [RepoSource] = []
            
            for sourceFile in sourceFiles {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(sourceFile)
                
                let arrayOfDictionaries = Networking.get_local(fileURL.path)
                
                for sourceDict in arrayOfDictionaries {
                    var repo = RepoSource()
                    var suites = "./"
                    if let dict_suites = sourceDict["Suites"] {
                        suites = dict_suites.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let urlString = sourceDict["URIs"], let url = URL(string: urlString) {
                        var finalURL = url
                        if suites != "./" {
                            finalURL = url.appendingPathComponent("dists")
                        }
                        finalURL = finalURL.appendingPathComponent(suites)
                        repo.url = finalURL
                        if let signedBy = sourceDict["Signed-by"] {
                            repo.signedby = URL(fileURLWithPath: signedBy)
                        }
                        if suites != "./" {
                            repo.suites = suites
                            if let components = sourceDict["Components"] {
                                print(components)
                                let componentsArray = components.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map { String($0) }
                                print(componentsArray)
                                if componentsArray.count >= 2 {
                                    for component in componentsArray {
                                        repo.components = component
                                        repos.append(repo)
                                    }
                                } else {
                                    repo.components = components
                                    repos.append(repo)
                                }
                            }
                        } else {
                            repos.append(repo)
                        }
                    }
                }
            }
            
            var tempParsedSources: [RepoSource] = []
            var distSources: [RepoSource] = []

            for source in repos {
                if source.url.absoluteString.contains("/dists/") {
                    distSources.append(source)
                } else {
                    tempParsedSources.append(source)
                }
            }

            repos = tempParsedSources + distSources
            print(distSources)
            return repos
        } catch {
            log("Error reading directory: \(error.localizedDescription)")
            return []
        }
    }
    
    static func getInstalledTweaks(_ dpkgPath: String) -> [Package] {
        let arrayofdicts = Networking.get_local(dpkgPath+"/status")
        var tweaks: [Package] = []
        for tweak in arrayofdicts {
            if (tweak["Status"] ?? "").contains("installed") && !(tweak["Status"] ?? "").contains("not-installed") {
                var Tweak = createPackageStruct(tweak)
                let packageInstallPath = URL(string: dpkgPath)!.appendingPathComponent("info/\(Tweak.id).list")
                let attr = try? FileManager.default.attributesOfItem(atPath: packageInstallPath.path)
                Tweak.installDate = attr?[FileAttributeKey.modificationDate] as? Date
                if !tweaks.contains(where: { $0.id == Tweak.id }) {
                    tweaks.append(Tweak)
                }
            }
        }
        return tweaks
    }
    
    static func getCachedRepos() -> [Repo] {
        let fileManager = FileManager.default
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/var/mobile/.purepkg")
        let repoCacheDirectory = documentDirectory.appendingPathComponent("repoCache")
        
        if fileManager.fileExists(atPath: repoCacheDirectory.path) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: repoCacheDirectory, includingPropertiesForKeys: nil)
                
                var repos: [Repo] = []
                
                for fileURL in fileURLs {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let repo = try JSONDecoder().decode(Repo.self, from: data)
                        repos.append(repo)
                    } catch {
                        log("Error decoding JSON from \(fileURL.path): \(error.localizedDescription)")
                    }
                }
                
                return repos
            } catch {
                log("Error reading directory \(repoCacheDirectory.path): \(error.localizedDescription)")
                return []
            }
        } else {
            return []
        }
    }
    
    static func removeRepo(_ repositoryURL: URL) {
        let (status, out, error) = spawnRootHelper(args: [ "removeRepo", repositoryURL.absoluteString ])
        if (status != 0) {
            if (status == -1) {
                showPopup("Failed", "\(out) \(error)")
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                showPopup("Failed", "RootHelper \(desc)")
            }
        }
    }
    
    static func addRepo(_ repositoryURL: String) {
        let (status, out, error) = spawnRootHelper(args: [ "addRepo", repositoryURL ])
        if (status != 0) {
            if (status == -1) {
                showPopup("Failed", "\(out) \(error)")
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                showPopup("Failed", "RootHelper \(desc)")
            }
        }
    }
    
    static func getDeps(_ pkgs: [Package], _ appData: AppData) -> [Package] {
        let all_pkgs = appData.pkgs + appData.installed_pkgs
        var uniqueDeps: [String: verReq] = [:]
        
        pkgs.forEach { package in
            package.depends.forEach { dependency in
                let depID = dependency.id
                let existingDep = uniqueDeps[depID]
                if existingDep == nil || dependency.reqVer.version > existingDep!.version {
                    uniqueDeps[depID] = dependency.reqVer
                }
            }
        }
        
        var resultDeps = [Package]()
        resultDeps.reserveCapacity(uniqueDeps.count)
        
        uniqueDeps.forEach { (depID, reqVer) in
            if let matchingPackage = all_pkgs.first(where: { $0.id == depID }) {
                if ((reqVer.version >= matchingPackage.version && reqVer.minVer) || (reqVer.version <= matchingPackage.version && !reqVer.minVer)) && !appData.installed_pkgs.contains(where: { $0.id == depID }) {
                    resultDeps.append(matchingPackage)
                }
            }
        }
        
        return resultDeps
    }
    
    static func createPackageStruct(_ tweak: [String:String]) -> Package {
        var Tweak = Package()
        Tweak.id = tweak["Package"] ?? "uwu.lrdsnow.unknown"
        Tweak.desc = tweak["Description"] ?? "Description"
        Tweak.author = tweak["Author"] ?? tweak["Maintainer"] ?? "Unknown Author"
        Tweak.arch = tweak["Architecture"] ?? ""
        Tweak.name = tweak["Name"] ?? tweak["Package"] ?? "Unknown Tweak"
        Tweak.section = tweak["Section"] ?? "Tweaks"
        Tweak.version = tweak["Version"] ?? "0.0"
        Tweak.installed_size = Int(tweak["Installed-Size"] ?? "0") ?? 0
        if let depiction = tweak["Depiction"] {
            Tweak.depiction = URL(string: depiction)
        }
        if let depiction = tweak["SileoDepiction"] {
            Tweak.depiction = URL(string: depiction)
        }
        if let depiction = tweak["Sileodepiction"] {
            Tweak.depiction = URL(string: depiction)
        }
        if let icon = tweak["Icon"] {
            Tweak.icon = URL(string: icon)
        }
        for dep in (tweak["Depends"] ?? "").components(separatedBy: ", ").map({ String($0) }) {
            var tweakDep = DepPackage()
            let components = dep.components(separatedBy: " ")
            if components.count >= 1 {
                tweakDep.id = components[0]
            }
            if components.count >= 2 {
                var ver = components[1...].joined(separator: " ")
                ver = ver.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                let verComponents = ver.components(separatedBy: " ")
                if verComponents.count >= 2 {
                    tweakDep.reqVer.req = true
                    let compare = verComponents[0]
                    let truVer = verComponents[1]
                    tweakDep.reqVer.version = truVer
                    if compare == ">=" {
                        tweakDep.reqVer.minVer = true
                    }
                }
            }
            if tweakDep.id != "" {
                Tweak.depends.append(tweakDep)
            }
        }
        Tweak.author = Tweak.author.removingBetweenAngleBrackets()
        return Tweak
    }
}

func fixDuplicateRepos(_ repos: [Repo]) -> [Repo] {
    var tempRepos: [Repo] = []
    
    for repo in repos {
        if !tempRepos.map({ $0.url }).contains(repo.url) {
            tempRepos.append(repo)
        } else {
            if !tempRepos.filter({ $0.url == repo.url }).map({ $0.component }).contains(repo.component) {
                tempRepos.append(repo)
            }
        }
    }
    
    return tempRepos
}

public var refreshingRepos = false

func refreshRepos(_ appData: AppData) {
    guard !refreshingRepos else {
        return
    }

    refreshingRepos = true
    
    appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak().path+"/Library/dpkg")
    
    let startTime = CFAbsoluteTimeGetCurrent()
    #if os(macOS)
    Task(priority: .background) {
        APTWrapper.spawn(command: "\(Jailbreak().path)/bin/apt-get", args: ["apt-get", "update"])
    }
    #endif
    let oldRepos = appData.repos
    let repoCacheDir = URL.documents.appendingPathComponent("repoCache")
    appData.repos = []
    if FileManager.default.fileExists(atPath: repoCacheDir.path) {
        try? FileManager.default.removeItem(at: repoCacheDir)
    }
    try? FileManager.default.createDirectory(at: repoCacheDir, withIntermediateDirectories: true, attributes: nil)
    DispatchQueue.main.async {
        if Jailbreak().type != .jailed {
            appData.repoSources = RepoHandler.getAptSources(Jailbreak().path+"/etc/apt/sources.list.d")
        } else {
            appData.repoSources = [
                RepoSource(url: URL(string: "https://lrdsnow.github.io/purepkg/./")!)
            ]
            #if os(iOS)
            appData.repoSources.append(contentsOf: [
                RepoSource(url: URL(string: "https://repo.chariz.com/./")!),
                RepoSource(url: URL(string: "https://luki120.github.io/./")!),
                RepoSource(url: URL(string: "https://sparkdev.me/./")!),
                RepoSource(url: URL(string: "https://havoc.app/./")!),
                RepoSource(url: URL(string: "https://apt.procurs.us/dists/iphoneos-arm64-rootless/1800")!, suites: "iphoneos-arm64-rootless/1800", components: "main")
            ])
            #elseif os(tvOS)
            appData.repoSources.append(contentsOf: [
                RepoSource(url: URL(string: "https://strap.palera.in/dists/appletvos-arm64/1800")!, suites: "appletvos-arm64/1800", components: "main")
            ])
            #endif
        }
        let repoSources = appData.repoSources
        for repo in repoSources {
            var tempRepo = Repo()
            tempRepo.url = repo.url.appendingPathComponent("refreshing/")
            tempRepo.component = repo.components
            tempRepo.error = "Refreshing..."
            if let oldRepo = oldRepos.first(where: { $0.url == repo.url }) {
                tempRepo.name = oldRepo.name
            }
            appData.repos.append(tempRepo)
        }
        DispatchQueue.global(qos: .background).async {
            RepoHandler.getRepos(repoSources) { repo in
                DispatchQueue.main.async {
                    appData.repos = fixDuplicateRepos(appData.repos)
                    if let AppDataRepoIndex = appData.repos.firstIndex(where: { $0.url == repo.url.appendingPathComponent("refreshing/") && $0.component == repo.component }) {
                        var tempRepo = repo
//                        if repo.tweaks.isEmpty {
//                            spawnRootHelper(args: ["clearRepoFiles", repo.url.absoluteString])
//                            if repo.error == nil || repo.error == "" {
//                                tempRepo.error = "An unknown error occured getting repo packages"
//                            }
//                        }
                        appData.repos[AppDataRepoIndex] = tempRepo
                        appData.repos = fixDuplicateRepos(appData.repos)
                        appData.pkgs  = appData.repos.flatMap { $0.tweaks }
                        let jsonEncoder = JSONEncoder()
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let elapsedTime = endTime - startTime
                        log("Got \(appData.repos.filter { $0.error != "Refreshing..." }.count) repos in \(elapsedTime) seconds")
                        appData.available_updates = checkForUpdates(installed: appData.installed_pkgs, all: appData.pkgs)
                        if (appData.repos.filter { $0.error != "Refreshing..." }.count + 2) >= appData.repos.count {
                            refreshingRepos = false
                        }
                        do {
                            let jsonData = try jsonEncoder.encode(repo)
                            do {
                                var cleanname = repo.name.filter { $0.isLetter || $0.isNumber }.trimmingCharacters(in: .whitespacesAndNewlines)
                                if cleanname == "" {
                                    cleanname = "\(UUID())"
                                }
                                try jsonData.write(to: repoCacheDir.appendingPathComponent("\(cleanname).json"))
                            } catch {
                                log("Error saving repo data: \(error)")
                            }
                        } catch {
                            log("Error encoding repo: \(error)")
                        }
                    }
                }
            }
        }
    }
}

func checkForUpdates(installed: [Package], all: [Package]) -> [Package] {
    var updates: [Package] = []
    for pkg in installed {
        let repo_pkg = all.first { $0.id == pkg.id }
        if let repo_pkg = repo_pkg {
            if pkg.name == "PurePKG" {
                print(pkg.version)
                print(repo_pkg.version)
            }
            if pkg.version.compareVersion(repo_pkg.version) == .orderedAscending {
                var update_pkg = repo_pkg
                update_pkg.installedVersion = pkg.version
                updates.append(update_pkg)
            }
        }
    }
    return updates
}

extension Package {
    func getDeps(_ appData: AppData) -> [Package] {
        let all_pkgs = appData.pkgs + appData.installed_pkgs
        var uniqueDeps: [String: verReq] = [:]
        
        self.depends.forEach { dependency in
            let depID = dependency.id
            let existingDep = uniqueDeps[depID]
            if existingDep == nil || dependency.reqVer.version > existingDep!.version {
                uniqueDeps[depID] = dependency.reqVer
            }
        }
        
        var resultDeps = [Package]()
        resultDeps.reserveCapacity(uniqueDeps.count)
        
        uniqueDeps.forEach { (depID, reqVer) in
            if let matchingPackage = all_pkgs.first(where: { $0.id == depID }) {
                if ((reqVer.version >= matchingPackage.version && reqVer.minVer) || (reqVer.version <= matchingPackage.version && !reqVer.minVer)) && !appData.installed_pkgs.contains(where: { $0.id == depID }) {
                    resultDeps.append(matchingPackage)
                }
            }
        }
        
        return resultDeps
    }
}
