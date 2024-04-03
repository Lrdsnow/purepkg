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
    public static func get_dict(_ url: URL, completion: @escaping ([String: String]?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    completion(nil, "Server responded with status code \(statusCode)")
                    return
                }
            }
            
            if let fileContent = String(data: data, encoding: .utf8) {
                if fileContent.isValidRepoFileFormat() {
                    if ((url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release")) {
                        let fileName = "\(url.absoluteString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "/", with: "_"))"
                        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        do {
                            try data.write(to: tempFilePath)
                            spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                        } catch {
                            
                        }
                    }
                    
                    let lines = fileContent.components(separatedBy: .newlines)
                    
                    var dictionary: [String: String] = [:]
                    
                    for line in lines {
                        let components = line.components(separatedBy: ":")
                        if components.count == 2 {
                            let key = components[0].trimmingCharacters(in: .whitespaces)
                            let value = components[1].trimmingCharacters(in: .whitespaces)
                            dictionary[key] = value
                        }
                    }
                    
                    completion(dictionary, nil)
                } else {
                    completion(nil, "Downloaded file was invalid")
                }
            } else {
                completion(nil, "Failed to decode data")
            }
        }
        
        task.resume()
    }
    
    public static func RootHelper_saveRepoFiles(_ url: URL) throws {
        try? FileManager.default.createDirectory(atPath: "\(Jailbreak.path())/var/lib/apt/purepkglists", withIntermediateDirectories: true)
        let data = try Data(contentsOf: url)
        try? FileManager.default.removeItem(at: url)
        try data.write(to: URL(fileURLWithPath: "\(Jailbreak.path())/var/lib/apt/purepkglists/\(url.lastPathComponent)"))
    }
    
    public static func RootHelper_removeAllRepoFiles() throws {
        try? FileManager.default.removeItem(atPath: "\(Jailbreak.path())/var/lib/apt/purepkglists");
    }
    
    public static func get(_ url: URL, completion: @escaping ([[String: String]]?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            if let fileContent = String(data: data, encoding: .utf8) {
                do {
                    if (url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release") {
                        let fileName = "\(url.absoluteString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "/", with: "_"))"
                        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        try data.write(to: tempFilePath)
                        spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                    }
                    
                    let paragraphs = fileContent.components(separatedBy: "\n\n")
                    
                    var arrayOfDictionaries: [[String: String]] = []
                    
                    for paragraph in paragraphs {
                        let lines = paragraph.components(separatedBy: .newlines)
                        
                        var dictionary: [String: String] = [:]
                        
                        for line in lines {
                            let components = line.components(separatedBy: ":")
                            if components.count >= 2 {
                                let key = components[0].trimmingCharacters(in: .whitespaces)
                                var temp_components = components
                                temp_components.removeFirst()
                                let value = temp_components.joined(separator: ":").trimmingCharacters(in: .whitespaces)
                                dictionary[key] = value
                            }
                        }
                        
                        if !dictionary.isEmpty {
                            arrayOfDictionaries.append(dictionary)
                        }
                    }
                    
                    completion(arrayOfDictionaries, nil)
                } catch {
                    completion(nil, "Failed to save/parse data: \(error.localizedDescription)")
                }
            } else {
                completion(nil, "Failed to decode data")
            }
        }
        
        task.resume()
    }
    
    static func getSavedRepoFilePath(_ url: URL) -> String {
        let fileName = "\(url.absoluteString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "/", with: "_"))"
        return "\(Jailbreak.path())/var/lib/apt/purepkglists/\(fileName)";
    }
    
    static func get_local(_ path: String) -> [[String:String]] {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let fileContent = String(data: data, encoding: .utf8) {
            let paragraphs = fileContent.components(separatedBy: "\n\n")
            
            var arrayOfDictionaries: [[String: String]] = []
            
            for paragraph in paragraphs {
                let lines = paragraph.components(separatedBy: .newlines)
                
                var dictionary: [String: String] = [:]
                
                for line in lines {
                    let components = line.components(separatedBy: ":")
                    if components.count >= 2 {
                        let key = components[0].trimmingCharacters(in: .whitespaces)
                        var temp_components = components
                        temp_components.removeFirst()
                        let value = temp_components.joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        dictionary[key] = value
                    }
                }
                
                if !dictionary.isEmpty {
                    arrayOfDictionaries.append(dictionary)
                }
            }
            
            return arrayOfDictionaries
        }
        return []
    }
    
    static func getRepos(_ urls: [URL?], _ distRepoComponents: [URL:String] = [:], completion: @escaping (Repo) -> Void) {
        spawnRootHelper(args: [ "removeAllRepoFiles" ])
        for url in urls {
            if let url = url {
            
                log("getting repo: \(url.absoluteString)")
                self.get_dict(url.appendingPathComponent("Release")) { (result, error) in
                    if let result = result {
                        log("got repo! \(url.appendingPathComponent("Release").absoluteString)")
                        var Repo = Repo()
                        Repo.url = url
                        Repo.name = result["Origin"] ?? "Unknown Repo"
                        Repo.label = result["Label"] ?? ""
                        Repo.description = result["Description"] ?? "Description"
                        Repo.archs = (result["Architectures"] ?? "").split(separator: " ").map { String($0) }
                        Repo.version = Double(result["Version"] ?? "0.0") ?? 0.0
                        
                        #if !os(watchOS)
                        if !UserDefaults.standard.bool(forKey: "ignoreSignature") {
                            log("getting repo signature: \(url.appendingPathComponent("Release.gpg"))")
                            var signature_ok: Bool = false;
                            self.get(url.appendingPathComponent("Release.gpg")) { (result, error) in
                                if error != nil {
                                    switch Jailbreak.type() {
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
                                    let savedReleaseGPGPath = self.getSavedRepoFilePath(url.appendingPathComponent("Release.gpg"));
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
                                        if Jailbreak.type() == .tvOS_rootful || Jailbreak.type() == .visionOS_rootful {
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
                                            completion(Repo);
                                            return
                                        }
                                    } else {
                                        signature_ok = true;
                                        log("Good signature at \(url.appendingPathComponent("Release.gpg"))");
                                        
                                        self.get(url.appendingPathComponent("InRelease")) { (result, error) in
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
                        if let repoComponents = distRepoComponents[url] {
                            pkgsURL = url.appendingPathComponent(repoComponents).appendingPathComponent("binary-\(Jailbreak.arch())")
                        }
                        
                        log("gettings repo tweaks from: \(pkgsURL.appendingPathComponent("Packages").absoluteString)")
                        self.get(pkgsURL.appendingPathComponent("Packages")) { (result, error) in
                            if let result = result {
                                log("got repo tweaks! \(pkgsURL.appendingPathComponent("Packages").absoluteString)")
                                var tweaks: [Package] = []
                                for tweak in result {
                                    let lowercasedTweak = tweak.reduce(into: [String: String]()) { result, element in
                                        let (key, value) = element
                                        result[key.lowercased()] = value
                                    }
                                    var Tweak = Package()
                                    Tweak.arch = lowercasedTweak["architecture"] ?? ""
                                    if Tweak.arch == Jailbreak.arch() {
                                        Tweak.id = lowercasedTweak["package"] ?? "uwu.lrdsnow.unknown"
                                        Tweak.desc = lowercasedTweak["description"] ?? "Description"
                                        Tweak.author = lowercasedTweak["author"] ?? lowercasedTweak["maintainer"] ?? "Unknown Author"
                                        Tweak.name = lowercasedTweak["name"] ?? lowercasedTweak["package"] ?? "Unknown Tweak"
                                        Tweak.section = lowercasedTweak["section"] ?? "Tweaks"
                                        Tweak.version = lowercasedTweak["version"] ?? "0.0"
                                        Tweak.versions.append(lowercasedTweak["version"] ?? "0.0")
                                        Tweak.installed_size = Int(lowercasedTweak["installed-size"] ?? "0") ?? 0
                                        for dep in (tweak["Depends"] ?? "").components(separatedBy: ", ").map { String($0) } {
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
                                completion(Repo)
                            } else if let error = error {
                                log("Error getting repo tweaks: \(error.localizedDescription)")
                                Repo.error = "Error getting repo tweaks: \(error.localizedDescription)"
                                completion(Repo)
                            }
                        }
                    } else if let error = error {
                        log("Error getting repo: \(error.localizedDescription)")
                        var repo = Repo()
                        repo.url = url
                        repo.error = "Error getting repo: \(error.localizedDescription)"
                        completion(repo)
                    }
                }
            }
        }
    }
    
    static func getAptSources(_ directoryPath: String) -> ([URL], [URL:String]) {
        do {
            log("Repo Sources Directory: \(directoryPath)")
            let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            
            let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
            
            log("source Files: \(sourceFiles)")
            
            var parsedURLs: [URL] = []
            var distRepoComponents: [URL:String] = [:]
            
            for sourceFile in sourceFiles {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(sourceFile)
                
                let arrayOfDictionaries = self.get_local(fileURL.path)
                
                for sourceDict in arrayOfDictionaries {
                    var suites = "./"
                    if let dict_suites = sourceDict["Suites"] {
                        suites = dict_suites
                    }
                    if let urlString = sourceDict["URIs"], let url = URL(string: urlString) {
                        var finalURL = url
                        if suites != "./" {
                            finalURL = url.appendingPathComponent("dists")
                        }
                        finalURL = finalURL.appendingPathComponent(suites)
                        parsedURLs.append(finalURL)
                        if suites != "./" {
                            if let components = sourceDict["Components"] {
                                distRepoComponents[finalURL] = components
                            }
                        }
                    }
                }
            }
            
            log("sources: \(parsedURLs)")
            var tempParsedURLs: [URL] = []
            var distURLs: [URL] = []
            for url in parsedURLs {
                if url.absoluteString.contains("/dists/") {
                    distURLs.append(url)
                } else {
                    tempParsedURLs.append(url)
                }
            }
            parsedURLs = tempParsedURLs + distURLs
            
            return (parsedURLs, distRepoComponents)
        } catch {
            log("Error reading directory: \(error.localizedDescription)")
            return ([], [:])
        }
    }
    
    static func getInstalledTweaks(_ statusPath: String) -> [Package] {
        let arrayofdicts = self.get_local(statusPath)
        var tweaks: [Package] = []
        for tweak in arrayofdicts {
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
            for dep in (tweak["Depends"] ?? "").components(separatedBy: ", ").map { String($0) } {
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
            if !tweaks.contains(where: { $0.id == Tweak.id }) {
                tweaks.append(Tweak)
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
                #if !os(watchOS) && !os(macOS)
                UIApplication.shared.alert(title: "Failed", body: "\(out) \(error)", withButton: true)
                #endif
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                #if !os(watchOS) && !os(macOS)
                UIApplication.shared.alert(title: "Failed", body: "RootHelper \(desc)", withButton: true)
                #endif
            }
        }
    }
    
    static func RootHelper_removeRepo(_ repositoryURL: URL, _ appData: AppData? = nil) throws {
        let directoryPath = Jailbreak.path(appData)+"/etc/apt/sources.list.d"
        let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
        
        let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
        
        for sourceFile in sourceFiles {
            let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(sourceFile)
            
            if var fileContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                let paragraphs = fileContent.components(separatedBy: "\n\n")
                
                var modifiedContent = ""
                
                for paragraph in paragraphs {
                    let lines = paragraph.components(separatedBy: .newlines)
                    
                    var shouldRemoveBlock = false
                    
                    for line in lines {
                        let components = line.components(separatedBy: ":")
                        
                        if components.count >= 2 {
                            let key = components[0].trimmingCharacters(in: .whitespaces)
                            var temp_components = components
                            temp_components.removeFirst()
                            let value = temp_components.joined(separator: ":").trimmingCharacters(in: .whitespaces)
                            
                            if URL(string: value) == repositoryURL {
                                shouldRemoveBlock = true
                            }
                        }
                    }
                    
                    if !shouldRemoveBlock {
                        modifiedContent += paragraph + "\n\n"
                    }
                }
                try modifiedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }
    
    static func addRepo(_ repositoryURL: String) {
        let (status, out, error) = spawnRootHelper(args: [ "addRepo", repositoryURL ])
        if (status != 0) {
            if (status == -1) {
                #if !os(watchOS) && !os(macOS)
                UIApplication.shared.alert(title: "Failed", body: "\(out) \(error)", withButton: true)
                #endif
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                #if !os(watchOS) && !os(macOS)
                UIApplication.shared.alert(title: "Failed", body: "RootHelper \(desc)", withButton: true)
                #endif
            }
        }
    }
    
    static func RootHelper_addRepo(_ repositoryURL: String, _ appData: AppData? = nil) throws {
        let fileName = "purepkg.sources"
        let fileURL = URL(fileURLWithPath: Jailbreak.path(appData)+"/etc/apt/sources.list.d").appendingPathComponent(fileName)
        
        var fileContent = ""
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            fileContent = try String(contentsOf: fileURL, encoding: .utf8)
        }
        
        let newRepositoryBlock = """
                Types: deb
                URIs: \(repositoryURL)
                Suites: ./
                Components:
                
                """
        
        fileContent += newRepositoryBlock
        
        try fileContent.write(to: fileURL, atomically: false, encoding: .utf8)
    }
    
    // absolutely terrible way of getting deps that i will rewrite later
    static func getDeps(_ pkgs: [Package], _ appData: AppData) -> [Package] {
        let all_pkgs = appData.pkgs + appData.installed_pkgs
        // gets the deps ofc
        var uniqueDeps: [String: verReq] = [:]
        for package in pkgs {
            for dependency in package.depends {
                let depID = dependency.id
                if let existingDep = uniqueDeps[depID] {
                    if dependency.reqVer.version > existingDep.version {
                        uniqueDeps[depID] = dependency.reqVer
                    }
                } else {
                    uniqueDeps[depID] = dependency.reqVer
                }
            }
        }
        let pkgDeps: [DepPackage] = uniqueDeps.map { (depID, reqVer) in
            return DepPackage(id: depID, reqVer: reqVer)
        }
        //
        var resultDeps: [Package] = []
        for dep in pkgDeps {
            if let matchingPackage = all_pkgs.first(where: { $0.id == dep.id }) {
                if ((dep.reqVer.version >= matchingPackage.version && dep.reqVer.minVer) || (dep.reqVer.version <= matchingPackage.version && !dep.reqVer.minVer)) && !appData.installed_pkgs.contains(where: { $0.id == dep.id }) {
                    resultDeps.append(matchingPackage)
                }
            }
        }
        
        return resultDeps
    }
}

func refreshRepos(_ bg: Bool, _ appData: AppData) {
    let oldRepos = appData.repos
    let repoCacheDir = URL.documents.appendingPathComponent("repoCache")
    appData.repos = []
    if FileManager.default.fileExists(atPath: repoCacheDir.path) {
        try? FileManager.default.removeItem(at: repoCacheDir)
    }
    try? FileManager.default.createDirectory(at: repoCacheDir, withIntermediateDirectories: true, attributes: nil)
    DispatchQueue.main.async {
        if appData.jbdata.jbtype != .jailed {
            let repoData = RepoHandler.getAptSources(Jailbreak.path(appData)+"/etc/apt/sources.list.d")
            appData.repo_urls = repoData.0
            appData.dist_repo_components = repoData.1
        } else {
            appData.repo_urls = [URL(string: "https://repo.chariz.com")!, URL(string: "https://luki120.github.io")!, URL(string: "https://sparkdev.me")!, URL(string: "https://havoc.app")!]
        }
        let repo_urls = appData.repo_urls
        for repourl in repo_urls {
            var tempRepo = Repo()
            tempRepo.url = repourl.appendingPathComponent("refreshing/")
            tempRepo.error = "Refreshing..."
            if let oldRepo = oldRepos.first(where: { $0.url == repourl }) {
                tempRepo.name = oldRepo.name
            }
            appData.repos.append(tempRepo)
        }
        let dist_repo_components = appData.dist_repo_components
        DispatchQueue.global(qos: .background).async {
            RepoHandler.getRepos(repo_urls, dist_repo_components) { repo in
                DispatchQueue.main.async {
                    if let AppDataRepoIndex = appData.repos.firstIndex(where: { $0.url == repo.url.appendingPathComponent("refreshing/") }) {
                        appData.repos[AppDataRepoIndex] = repo
                        appData.pkgs  = appData.repos.flatMap { $0.tweaks }
                        let jsonEncoder = JSONEncoder()
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
