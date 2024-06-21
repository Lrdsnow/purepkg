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
        spawnRootHelper(args: ["removeAllRepoFiles"])
        for repoSource in repoSources {
            let url = repoSource.url
            log("getting repo: \(url.absoluteString)")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let releaseURL = url.appendingPathComponent("Release")
            Networking.get_dict_compressed(releaseURL) { (result, error) in
                var repo = Repo()
                repo.url = url
                
                if let result = result {
                    log("got repo! \(releaseURL.absoluteString)")
                    repo.name = result["Origin"] ?? "Unknown Repo"
                    repo.label = result["Label"] ?? ""
                    repo.description = result["Description"] ?? "Description"
                    repo.archs = (result["Architectures"] ?? "").split(separator: " ").map { String($0) }
                    repo.version = Double(result["Version"] ?? "0.0") ?? 0.0
                    repo.component = repoSource.components
                    
                    let currentArch = Jailbreak().arch
                    if !repo.archs.contains(currentArch) {
                        repo.error = "Unsupported architecture '\(currentArch)'"
                        spawnRootHelper(args: ["clearRepoFiles", url.absoluteString])
                        completion(repo)
                    }
                    
#if !os(watchOS) && !targetEnvironment(simulator)
                    if UserDefaults.standard.bool(forKey: "checkSignature") {
                        log("getting repo signature: \(url.appendingPathComponent("Release.gpg"))")
                        Networking.get(url.appendingPathComponent("Release.gpg")) { (result, error) in
                            if error != nil {
                                switch Jailbreak().type {
                                case .macos:
                                    log("Error: No signature found for \(url.absoluteString)")
                                    repo.error = "Error: No signature found for \(url.absoluteString)"
                                case .tvOS_rootful, .rootful, .rootless, .roothide:
                                    log("Warning: No signature found for \(url.absoluteString)")
                                    repo.error = "Warning: No signature found for \(url.absoluteString)"
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
                    if let repoComponents = repoSource.suites {
                        pkgsURL = url.appendingPathComponent(repoComponents).appendingPathComponent("binary-\(Jailbreak().arch)")
                    }
                    let packagesURL = pkgsURL.appendingPathComponent("Packages")

                    log("getting repo tweaks from: \(packagesURL.absoluteString)")
                    
                    Networking.get_compressed(packagesURL) { (result, error, actualURL) in
                        if let result = result {
                            log("got repo tweaks! \(actualURL!.absoluteString)")
                            repo.tweaks = result.map { tweakDict -> Package in
                                let lowercasedTweak = tweakDict.reduce(into: [String: String]()) { result, element in
                                    let (key, value) = element
                                    result[key.lowercased()] = value
                                }
                                return createPackageStruct(lowercasedTweak, repo)
                            }
                            let endTime = CFAbsoluteTimeGetCurrent()
                            let elapsedTime = endTime - startTime
                            log("Time taken to process/get repo \(url.absoluteString): \(elapsedTime) seconds")
                            completion(repo)
                        } else if let error = error {
                            log("Error getting repo tweaks: \(error.localizedDescription)")
                            repo.error = "Error getting repo tweaks: \(error.localizedDescription)"
                        }
                    }
                } else if let error = error {
                    log("Error getting repo: \(error.localizedDescription)")
                    repo.error = "Error getting repo: \(error.localizedDescription)"
                }
            }
        }
    }

    static func createPackageStruct(_ tweakDict: [String: String], _ repo: Repo? = nil) -> Package {
        var tweak = Package()
        tweak.arch = tweakDict["architecture"] ?? ""
        tweak.id = tweakDict["package"] ?? "uwu.lrdsnow.unknown"
        tweak.desc = tweakDict["description"] ?? "Description"
        tweak.author = tweakDict["author"] ?? tweakDict["maintainer"] ?? "Unknown Author"
        tweak.name = tweakDict["name"] ?? tweakDict["package"] ?? "Unknown Tweak"
        tweak.section = tweakDict["section"] ?? "Tweaks"
        tweak.path = tweakDict["filename"] ?? ""
        tweak.version = tweakDict["version"] ?? "0.0"
        tweak.versions.append(tweakDict["version"] ?? "0.0")
        tweak.installed_size = Int(tweakDict["installed-size"] ?? "0") ?? 0
        tweak.paid = (tweakDict["tag"] ?? "").contains("::commercial")
        
        let dependencies = (tweakDict["Depends"] ?? "").components(separatedBy: ", ").map { String($0) }
        tweak.depends = dependencies.compactMap { depString -> DepPackage? in
            let components = depString.components(separatedBy: " ")
            guard components.count >= 1 else { return nil }
            var dep = DepPackage()
            dep.id = components[0]
            if components.count >= 2 {
                let compare = components[0]
                let version = components[1...].joined(separator: " ").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                dep.reqVer.req = true
                dep.reqVer.version = version
                dep.reqVer.minVer = (compare == ">=")
            }
            return dep
        }
        
        if let depiction = tweakDict["depiction"] {
            tweak.depiction = URL(string: depiction)
        }
        if let icon = tweakDict["icon"] {
            tweak.icon = URL(string: icon)
        }
        if let repo = repo {
            tweak.repo = repo
        }
        tweak.author = tweak.author.removingBetweenAngleBrackets()
        
        return tweak
    }
    
    static func getAptSources(_ aptSourcesDirPath: String) -> [RepoSource] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: aptSourcesDirPath), includingPropertiesForKeys: nil)
            var repos: [RepoSource] = []
            
            for fileURL in fileURLs {
                if let fileContents = try? String(contentsOf: fileURL, encoding: .utf8) {
                    for dict in genArrayOfDicts(fileContents) as? [[String:String]] ?? [] {
                        var repo = RepoSource()
                        let suites = (dict["Suites"] ?? "./").trimmingCharacters(in: .whitespacesAndNewlines)
                        if let urlString = dict["URIs"], let url = URL(string: urlString) {
                            repo.url = (suites != "./" ? url.appendingPathComponent("dists") : url).appendingPathComponent(suites)
                            if let signedBy = dict["Signed-by"] { repo.signedby = URL(fileURLWithPath: signedBy) }
                            if suites != "./" {
                                repo.suites = suites
                                if let components = dict["Components"] {
                                    let componentsArray = components.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").map { String($0) }
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
            }
            
            return repos
        } catch {
            log("Error reading directory \(aptSourcesDirPath): \(error.localizedDescription)")
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
    
    static func manageRepo(_ repositoryURL: URL, operation: String) {
        let (status, out, error) = spawnRootHelper(args: [operation, repositoryURL.absoluteString])
        if status != 0 {
            if status == -1 {
                showPopup("Failed", "\(out) \(error)")
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status))
                let desc = String(cString: desc_cstring)
                free(desc_cstring)
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
}

func fixDuplicateRepos(_ repos: [Repo]) -> [Repo] {
    var seenRepos = Set<String>()
    var tempRepos: [Repo] = []
    
    for repo in repos {
        let key = "\(repo.url.absoluteString)-\(repo.component)"
        if !seenRepos.contains(key) {
            seenRepos.insert(key)
            tempRepos.append(repo)
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
                        Task {
                            if repo.payment_endpoint != nil {
                                PaymentAPI.getUserInfo(repo) { userInfo in
                                    if let userInfo = userInfo {
                                        DispatchQueue.main.async {
                                            appData.userInfo[repo.name] = userInfo
                                        }
                                    }
                                }
                            }
                        }
                        let jsonEncoder = JSONEncoder()
                        let endTime = CFAbsoluteTimeGetCurrent()
                        let elapsedTime = endTime - startTime
                        log("Got \(appData.repos.filter { $0.error != "Refreshing..." }.count) repos in \(elapsedTime) seconds")
                        appData.available_updates = checkForUpdates(installed: appData.installed_pkgs, all: appData.pkgs)
                        if appData.repos.filter { $0.error != "Refreshing..." }.count >= appData.repos.count {
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
