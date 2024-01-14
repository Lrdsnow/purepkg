//
//  Misc.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    static var documents: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension String {
    func removingBetweenAngleBrackets() -> String {
        let regex = try! NSRegularExpression(pattern: "<.*?>", options: .caseInsensitive)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "").trimmingCharacters(in: .whitespaces)
    }
}
