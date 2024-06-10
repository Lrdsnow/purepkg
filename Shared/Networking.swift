//
//  Networking.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/9/24.
//

import Foundation

public class Networking {
    public static func get_dict_compressed(_ url: URL, completion: @escaping ([String: String]?, Error?) -> Void) {
        let suffixes = ["zst", "xz", "lzma", "gz", "bz2", ""]
        var attempt = 0
        
        func attemptFetch(url: URL) {
            get_dict(url) { (dict, error) in
                if let dict = dict {
                    completion(dict, nil)
                } else if attempt < suffixes.count - 1 {
                    attempt += 1
                    var newURL = url
                    if let baseURL = URL(string: url.absoluteString) {
                        newURL = baseURL.deletingPathExtension().appendingPathExtension(suffixes[attempt])
                    }
                    attemptFetch(url: newURL)
                } else {
                    completion(nil, error)
                }
            }
        }
        
        attemptFetch(url: url.deletingPathExtension().appendingPathExtension(suffixes[attempt]))
    }
    
    public static func get_compressed(_ url: URL, completion: @escaping ([[String: String]]?, Error?, URL?) -> Void) {
        let suffixes = ["zst", "xz", "lzma", "gz", "bz2", ""]
        var attempt = 0
        
        func attemptFetch(url: URL) {
            log("getting repo tweaks from: \(url.absoluteString)")

            get(url) { (data, error) in
                if let data = data {
                    completion(data, nil, url)
                } else if attempt < suffixes.count - 1 {
                    attempt += 1
                    var newURL = url
                    if let baseURL = URL(string: url.absoluteString) {
                        newURL = baseURL.deletingPathExtension().appendingPathExtension(suffixes[attempt])
                    }
                    attemptFetch(url: newURL)
                } else {
                    completion(nil, error, nil)
                }
            }
        }
        attemptFetch(url: url.deletingPathExtension().appendingPathExtension(suffixes[attempt]))

    }
    
    public static func get_dict(_ url: URL, completion: @escaping ([String: String]?, Error?) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let task = URLSession.shared.dataTask(with: url) { (_data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let _data = _data else {
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
            
            var data = _data
            
            if (String(data: data, encoding: .utf8) ?? "").contains("<html>") {
                completion(nil, "Invalid data received")
                return
            }
            
            if let archiveType = url.archiveType() {
                data = _data.decompress(archiveType) ?? _data
            }
            
            if let fileContent = String(data: data, encoding: .utf8) {
                if fileContent.isValidRepoFileFormat() || (url.pathComponents.last ?? "").contains(".gpg") {
                    
                    #if !os(macOS)
                    if ((url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release")) {
                        let fileName = url.deletingPathExtension().absoluteString
                            .replacingOccurrences(of: "https://", with: "")
                            .replacingOccurrences(of: "http://", with: "")
                            .replacingOccurrences(of: "/", with: "_")
                            .replacingOccurrences(of: ".zst", with: "")
                            .replacingOccurrences(of: ".bz2", with: "")
                            .replacingOccurrences(of: ".gz", with: "")
                            .replacingOccurrences(of: ".xz", with: "")
                            .replacingOccurrences(of: ".lzma", with: "")
                        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        do {
                            try data.write(to: tempFilePath)
                            spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                        } catch {
                            
                        }
                    }
                    #endif
                    
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
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let elapsedTime = endTime - startTime
                    log("Time taken to get \(url.absoluteString): \(elapsedTime) seconds")
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
    
    public static func get(_ url: URL, completion: @escaping ([[String: String]]?, Error?) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let task = URLSession.shared.dataTask(with: url) { (_data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let _data = _data else {
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
            
            var data = _data
            
            if (String(data: data, encoding: .utf8) ?? "").contains("<html>") {
                completion(nil, "Invalid data received")
                return
            }
            
            if let archiveType = url.archiveType() {
                data = _data.decompress(archiveType) ?? _data
            }
            
            if let fileContent = String(data: data, encoding: .utf8) {
                do {
                    
                    #if !os(macOS)
                    if ((url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release")) {
                        var modifiedURL: URL;
                        if (url.absoluteString.hasSuffix(".gpg")) {
                            modifiedURL = url;
                        } else {
                            modifiedURL = url.deletingPathExtension();
                        }
                        let fileName = modifiedURL.deletingPathExtension().absoluteString
                            .replacingOccurrences(of: "https://", with: "")
                            .replacingOccurrences(of: "http://", with: "")
                            .replacingOccurrences(of: "/", with: "_")
                            .replacingOccurrences(of: ".zst", with: "")
                            .replacingOccurrences(of: ".bz2", with: "")
                            .replacingOccurrences(of: ".gz", with: "")
                            .replacingOccurrences(of: ".xz", with: "")
                            .replacingOccurrences(of: ".lzma", with: "")
                        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        do {
                            try data.write(to: tempFilePath)
                            spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                        } catch {
                            
                        }
                    }
                    #endif
                    
                    let paragraphs = fileContent.components(separatedBy: "\n\n")
                    
                    var arrayOfDictionaries: [[String: String]] = []
                    
                    for paragraph in paragraphs {
                        let dictionary = genDict(paragraph)
                        
                        if !dictionary.isEmpty {
                            arrayOfDictionaries.append(dictionary)
                        }
                    }
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let elapsedTime = endTime - startTime
                    log("Time taken to get \(url.absoluteString): \(elapsedTime) seconds")
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
    
    // technically not networking but wtv
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
    
    static func genDict(_ paragraph: String) -> [String:String] {
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
        
        return dictionary
    }
}
