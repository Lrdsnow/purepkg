//
//  RepoHandler.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import UIKit

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
            
            if let fileContent = String(data: data, encoding: .utf8) {
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
                completion(nil, "Failed to decode data")
            }
        }
        
        task.resume()
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
            } else {
                completion(nil, "Failed to decode data")
            }
        }
        
        task.resume()
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
    
    static func getRepos_limit(_ urls: [URL?], _ appData: AppData? = nil, completion: @escaping (Repo) -> Void) {
        for url in urls {
            if let url = url {
                log("getting repo: \(url.absoluteString)")
                self.get_dict(url.appendingPathComponent("Release")) { (result, error) in
                    if let result = result {
                        log("got repo! \(url.appendingPathComponent("Release").absoluteString)")
                        var Repo = Repo()
                        if url.absoluteString.contains("apt.procurs.us") {
                            Repo.url = URL(string: "https://apt.procurs.us")!
                        } else {
                            Repo.url = url
                        }
                        Repo.name = result["Origin"] ?? "Unknown Repo"
                        Repo.label = result["Label"] ?? ""
                        Repo.description = result["Description"] ?? "Description"
                        Repo.archs = (result["Architectures"] ?? "").split(separator: " ").map { String($0) }
                        Repo.version = Double(result["Version"] ?? "0.0") ?? 0.0
                        var supported = false
                        for arch in Repo.archs {
                            if Jailbreak.tweakArchSupported(arch, appData) {
                                supported = true
                            }
                        }
                        log("gettings repo tweaks from: \(url.appendingPathComponent("Packages").absoluteString)")
                        self.get(url.appendingPathComponent("Packages")) { (result, error) in
                            if let result = result {
                                log("got repo tweaks! \(url.appendingPathComponent("Packages").absoluteString)")
                                var tweaks: [Package] = []
                                for tweak in result {
                                    let lowercasedTweak = tweak.reduce(into: [String: String]()) { result, element in
                                        let (key, value) = element
                                        result[key.lowercased()] = value
                                    }
                                    var Tweak = Package()
                                    Tweak.id = lowercasedTweak["package"] ?? "uwu.lrdsnow.unknown"
                                    Tweak.desc = lowercasedTweak["description"] ?? "Description"
                                    Tweak.author = lowercasedTweak["author"] ?? lowercasedTweak["maintainer"] ?? "Unknown Author"
                                    Tweak.arch = lowercasedTweak["architecture"] ?? ""
                                    Tweak.name = lowercasedTweak["name"] ?? "Unknown Tweak"
                                    Tweak.section = lowercasedTweak["section"] ?? "Tweaks"
                                    Tweak.version = lowercasedTweak["version"] ?? "0.0"
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
                                    if Jailbreak.tweakArchSupported(Tweak.arch, appData) {
                                        if let index = tweaks.firstIndex(where: { $0.id == Tweak.id }) {
                                            let existingTweak = tweaks[index]
                                            if Tweak.version.compare(existingTweak.version, options: .numeric) == .orderedDescending {
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
                                completion(Repo)
                            }
                        }
                    } else if let error = error {
                        log("Error getting repo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    static func getRepos(_ urls: [URL?], completion: @escaping (Repo) -> Void) {
        for url in urls {
            if let url = url {
                log("getting repo: \(url.absoluteString)")
                self.get_dict(url.appendingPathComponent("Release")) { (result, error) in
                    if let result = result {
                        log("got repo! \(url.appendingPathComponent("Release").absoluteString)")
                        var Repo = Repo()
                        if url.absoluteString.contains("apt.procurs.us") {
                            Repo.url = URL(string: "https://apt.procurs.us")!
                        } else {
                            Repo.url = url
                        }
                        Repo.name = result["Origin"] ?? "Unknown Repo"
                        Repo.label = result["Label"] ?? ""
                        Repo.description = result["Description"] ?? "Description"
                        Repo.archs = (result["Architectures"] ?? "").split(separator: " ").map { String($0) }
                        Repo.version = Double(result["Version"] ?? "0.0") ?? 0.0
                        log("gettings repo tweaks from: \(url.appendingPathComponent("Packages").absoluteString)")
                        self.get(url.appendingPathComponent("Packages")) { (result, error) in
                            if let result = result {
                                log("got repo tweaks! \(url.appendingPathComponent("Packages").absoluteString)")
                                var tweaks: [Package] = []
                                for tweak in result {
                                    let lowercasedTweak = tweak.reduce(into: [String: String]()) { result, element in
                                        let (key, value) = element
                                        result[key.lowercased()] = value
                                    }
                                    var Tweak = Package()
                                    Tweak.id = lowercasedTweak["package"] ?? "uwu.lrdsnow.unknown"
                                    Tweak.desc = lowercasedTweak["description"] ?? "Description"
                                    Tweak.author = lowercasedTweak["author"] ?? lowercasedTweak["maintainer"] ?? "Unknown Author"
                                    Tweak.arch = lowercasedTweak["architecture"] ?? ""
                                    Tweak.name = lowercasedTweak["name"] ?? "Unknown Tweak"
                                    Tweak.section = lowercasedTweak["section"] ?? "Tweaks"
                                    Tweak.version = lowercasedTweak["version"] ?? "0.0"
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
                                Repo.tweaks = tweaks
                                completion(Repo)
                            } else if let error = error {
                                log("Error getting repo tweaks: \(error.localizedDescription)")
                                completion(Repo)
                            }
                        }
                    } else if let error = error {
                        log("Error getting repo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    static func getAptSources(_ directoryPath: String) -> [URL?] {
        do {
            log("Repo Sources Directory: \(directoryPath)")
            let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            
            let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
            
            log("source Files: \(sourceFiles)")
            
            var parsedURLs: [URL?] = []
            
            for sourceFile in sourceFiles {
                let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(sourceFile)
                
                let arrayOfDictionaries = self.get_local(fileURL.path)
                
                for sourceDict in arrayOfDictionaries {
                    if let suites = sourceDict["Suites"], suites == "./" {
                        if let urlString = sourceDict["URIs"], let url = URL(string: urlString) {
                            parsedURLs.append(url)
                        } else {
                            parsedURLs.append(nil)
                        }
                    }
                }
            }
            
            log("sources: \(parsedURLs)")
            
            return parsedURLs
        } catch {
            log("Error reading directory: \(error.localizedDescription)")
            return []
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
                UIApplication.shared.alert(title: "Failed", body: "\(out) \(error)", withButton: true)
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                UIApplication.shared.alert(title: "Failed", body: "RootHelper \(desc)", withButton: true)
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
                UIApplication.shared.alert(title: "Failed", body: "\(out) \(error)", withButton: true)
            } else {
                let desc_cstring: UnsafeMutablePointer<CChar> = waitpid_decode(Int32(status));
                let desc = String(cString: desc_cstring);
                free(desc_cstring);
                UIApplication.shared.alert(title: "Failed", body: "RootHelper \(desc)", withButton: true)
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
