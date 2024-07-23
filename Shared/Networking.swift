//
//  Networking.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/9/24.
//

import Foundation

public class Networking {
    public static func get_dict_compressed(_ url: URL, completion: @escaping ([String: String]?, Error?) -> Void) {
        let suffixes = ["", "zst", "xz", "lzma", "gz", "bz2"]
        var attempt = 0
        
        func attemptFetch(url: URL) {
            get_dict(url) { (dict, error) in
                if let dict = dict as? [String:String] {
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
        let suffixes = ["", "zst", "xz", "lzma", "gz", "bz2"]
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
    
    public static func get_dict(_ url: URL, json: Bool = false, completion: @escaping ([String: Any]?, Error?) -> Void) {
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
            
            if (String(data: _data, encoding: .utf8) ?? "").contains("<html>") {
                completion(nil, "Invalid data received")
                return
            }
            
            if !json {
                var data = _data
                
                if let archiveType = url.archiveType() {
                    data = _data.decompress(archiveType) ?? _data
                }
                
                if let fileContent = String(data: data, encoding: .utf8) {
                    if fileContent.isValidRepoFileFormat() || (url.pathComponents.last ?? "").contains(".gpg") {
                        
#if !os(macOS)
                        if ((url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release")) {
                            let fileName = RepoHandler.getSavedRepoFileName(url);
                            let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                            do {
                                try data.write(to: tempFilePath)
                                spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                            } catch {
                                
                            }
                        }
#endif
                                                
                        var dictionary: [String: String] = genDict(fileContent) as? [String : String] ?? [:]
                        
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
            } else {
                do {
                    completion(try JSONSerialization.jsonObject(with: _data, options: []) as? [String: Any], nil)
                } catch {
                    completion(nil, "Failed to decode data")
                }
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
                if ((url.pathComponents.last ?? "").contains("Packages") || (url.pathComponents.last ?? "").contains("Release")) {
                    let fileName = RepoHandler.getSavedRepoFileName(url);
                    let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    do {
                        try data.write(to: tempFilePath)
                        spawnRootHelper(args: ["saveRepoFiles", tempFilePath.path])
                    } catch {
                        
                    }
                }
                
                var arrayOfDictionaries: [[String: String]] = genArrayOfDicts(fileContent) as? [[String : String]] ?? []
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let elapsedTime = endTime - startTime
                log("Time taken to get \(url.absoluteString): \(elapsedTime) seconds")
                completion(arrayOfDictionaries, nil)
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
}
