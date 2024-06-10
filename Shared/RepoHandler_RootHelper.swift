//
//  RepoHandler+RootHelper.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/9/24.
//

import Foundation

extension RepoHandler {
    public static func RootHelper_clearRepoFiles(_ url: String) throws {
        let urlString = url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "/", with: "_")
        let fileManager = FileManager.default
        let directoryPath = "\(Jailbreak.path())/var/lib/apt/purepkglists"
        let fileURLs = try fileManager.contentsOfDirectory(atPath: directoryPath)
        
        for fileURL in fileURLs {
            if fileURL.contains(urlString) {
                try fileManager.removeItem(atPath: "\(directoryPath)/\(fileURL)")
            }
        }
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
    
    static func RootHelper_removeRepo(_ repositoryURL: URL, _ appData: AppData? = nil) throws {
        NSLog("Entering RootHelper_removeRepo")
        let directoryPath = Jailbreak.path(appData)+"/etc/apt/sources.list.d"
        let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
        
        let sourceFiles = fileURLs.filter { $0.hasSuffix(".sources") }
        
        for sourceFile in sourceFiles {
            let fileURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(sourceFile)
            
            if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                let paragraphs = fileContent.components(separatedBy: "\n\n")
                
                var modifiedContent = ""
                
                for paragraph in paragraphs {
                    let lines = paragraph.components(separatedBy: .newlines)
                    if (paragraph.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        continue;
                    }
                    
                    var shouldRemoveBlock = false
                    
                    for line in lines {
                        let components = line.components(separatedBy: ":")
                        
                        if components.count >= 2 {
                            let key = components[0].trimmingCharacters(in: .whitespaces)
                            if (key != "URIs") {
                                continue;
                            }
                            var temp_components = components;
                            temp_components.removeFirst();
                            let value = temp_components.joined(separator: ":").trimmingCharacters(in: .whitespaces);
                            var target = repositoryURL.standardized.absoluteString;
                            var actual = URL(string: value)!.standardized.absoluteString;
                            if (target.last == "/") {
                                target = String(target.dropLast());
                            }
                            if (actual.last == "/") {
                                actual = String(actual.dropLast());
                            }
                            if target == actual {
                                shouldRemoveBlock = true
                            }
                            break;
                        } else {
                            break;
                        }
                    }
                    
                    if !shouldRemoveBlock {
                        if (modifiedContent != "") {
                            modifiedContent += "\n"
                        }
                        modifiedContent += paragraph + "\n"
                    }
                }
                try modifiedContent.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }
    
    static func RootHelper_addRepo(_ repositoryURL: String, _ appData: AppData? = nil) throws {
        let fileName = "purepkg.sources"
        let fileURL = URL(fileURLWithPath: Jailbreak.path(appData)+"/etc/apt/sources.list.d").appendingPathComponent(fileName)
        var fileContent = ""
        var newRepositoryBlock = ""
        
        if repositoryURL.contains("/dists/") {
            let spliturl = repositoryURL.components(separatedBy: "dists/")
            newRepositoryBlock =
            "Types: deb\n" +
            "URIs: \(String(spliturl[0]))\n" +
            "Suites: \(String(spliturl[1]))\n" +
            "Components: main\n"
        } else {
            newRepositoryBlock =
            "Types: deb\n" +
            "URIs: \(repositoryURL)\n" +
            "Suites: ./\n" +
            "Components: \n"
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            if (fileContent != "") {
                fileContent += "\n"
            }
            fileContent += newRepositoryBlock
        } else {
            fileContent = newRepositoryBlock
        }
        
        try fileContent.write(to: fileURL, atomically: false, encoding: .utf8)
    }
}
