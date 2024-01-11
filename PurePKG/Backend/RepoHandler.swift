//
//  RepoHandler.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

public class RepoHandler {
    public static func getRepoRelease(_ url: URL, completion: @escaping ([String: String]?, Error?) -> Void) {
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
    
    public static func getRepoTweaks(_ url: URL, completion: @escaping ([[String: String]]?, Error?) -> Void) {
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
    
    static func getRepos(_ urls: [URL?], completion: @escaping (Repo) -> Void) {
        for url in urls {
            if let url = url {
                self.getRepoRelease(url.appendingPathComponent("Release")) { (result, error) in
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
                        self.getRepoTweaks(url.appendingPathComponent("Packages")) { (result, error) in
                            if let result = result {
                                var tweaks: [Package] = []
                                for tweak in result {
                                    var Tweak = Package()
                                    Tweak.id = tweak["Package"] ?? "uwu.lrdsnow.unknown"
                                    Tweak.desc = tweak["Description"] ?? "Description"
                                    Tweak.author = tweak["Author"] ?? tweak["Maintainer"] ?? "Unknown Author"
                                    Tweak.arch = tweak["Architecture"] ?? ""
                                    Tweak.name = tweak["Name"] ?? "Unknown Tweak"
                                    Tweak.depends = (tweak["Depends"] ?? "").components(separatedBy: ", ").map { String($0) }
                                    Tweak.section = tweak["Section"] ?? "Tweaks"
                                    Tweak.version = tweak["Version"] ?? "0.0"
                                    if let depiction = tweak["Depiction"] {
                                        Tweak.depiction = URL(string: depiction)
                                    }
                                    if let icon = tweak["Icon"] {
                                        Tweak.icon = URL(string: icon)
                                    }
                                    Tweak.repo = Repo
                                    if !tweaks.contains(where: { $0.id == Tweak.id }) {
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
}
