//
//  RepoHandler.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

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
    
    static func getRepos(_ urls: [URL?], completion: @escaping (Repo) -> Void) {
        for url in urls {
            if let url = url {
                self.get_dict(url.appendingPathComponent("Release")) { (result, error) in
                    if let result = result {
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
                        self.get(url.appendingPathComponent("Packages")) { (result, error) in
                            if let result = result {
                                var tweaks: [Package] = []
                                for tweak in result {
                                    let lowercasedTweak = tweak.reduce(into: [String: String]()) { result, element in
                                        let (key, value) = element
                                        result[key.lowercased()] = value
                                    }
                                    print(lowercasedTweak)
                                    var Tweak = Package()
                                    Tweak.id = lowercasedTweak["package"] ?? "uwu.lrdsnow.unknown"
                                    Tweak.desc = lowercasedTweak["description"] ?? "Description"
                                    Tweak.author = lowercasedTweak["author"] ?? lowercasedTweak["maintainer"] ?? "Unknown Author"
                                    Tweak.arch = lowercasedTweak["architecture"] ?? ""
                                    Tweak.name = lowercasedTweak["name"] ?? "Unknown Tweak"
                                    Tweak.depends = (lowercasedTweak["depends"] ?? "").components(separatedBy: ", ").map { String($0) }
                                    Tweak.section = lowercasedTweak["section"] ?? "Tweaks"
                                    Tweak.version = lowercasedTweak["version"] ?? "0.0"
                                    Tweak.installed_size = Int(lowercasedTweak["installed-size"] ?? "0") ?? 0
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
                                        let existingTweak = tweaks[index]
                                        if Tweak.version.compare(existingTweak.version, options: .numeric) == .orderedDescending {
                                            tweaks[index] = Tweak
                                        }
                                    } else {
                                        tweaks.append(Tweak)
                                    }
                                }
                                Repo.tweaks = tweaks
                                completion(Repo)
                            } else if let error = error {
                                print("Error getting repo tweaks: \(error.localizedDescription)")
                            }
                        }
                    } else if let error = error {
                        print("Error getting repo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    static func getAptSources(_ directoryPath: String) -> [URL?] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
            
            let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
            
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
            
            return parsedURLs
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
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
            Tweak.depends = (tweak["Depends"] ?? "").components(separatedBy: ", ").map { String($0) }
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
            Tweak.author = Tweak.author.removingBetweenAngleBrackets()
            if !tweaks.contains(where: { $0.id == Tweak.id }) {
                tweaks.append(Tweak)
            }
        }
        return tweaks
    }
    
    static func getCachedRepos() -> [Repo] {
        let fileManager = FileManager.default
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let repoCacheDirectory = documentDirectory.appendingPathComponent("repoCache")

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: repoCacheDirectory, includingPropertiesForKeys: nil)

            var repos: [Repo] = []

            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let repo = try JSONDecoder().decode(Repo.self, from: data)
                    repos.append(repo)
                } catch {
                    print("Error decoding JSON from \(fileURL.path): \(error.localizedDescription)")
                }
            }

            return repos

        } catch {
            print("Error reading directory \(repoCacheDirectory.path): \(error.localizedDescription)")
            return []
        }
    }
}
