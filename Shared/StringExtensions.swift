//
//  StringExtensions.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/14/24.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    func removingDuplicatesBySubValue<T: Hashable>(byKey key: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(key($0)).inserted }
    }
}

extension String {
    func removingBetweenAngleBrackets() -> String {
        let regex = try! NSRegularExpression(pattern: "<.*?>", options: .caseInsensitive)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: "").trimmingCharacters(in: .whitespaces)
    }
    func removeSubstringIfExists(_ substring: String) -> String {
        if let range = self.range(of: substring) {
            let substringRange = self.startIndex..<range.lowerBound
            return String(self[substringRange])
        } else {
            return self
        }
    }
    func urlCount() -> Int {
        do {
            let regex = try NSRegularExpression(pattern: "(https://|http://)", options: [])
            let range = NSRange(location: 0, length: self.utf16.count)
            return regex.numberOfMatches(in: self, options: [], range: range)
        } catch {
            print("Error: \(error)")
            return 0
        }
    }
    func extractURLs() -> [URL] {
        do {
            let regex = try NSRegularExpression(pattern: "(https?://[^\\s]+)", options: .caseInsensitive)
            let range = NSRange(location: 0, length: self.utf16.count)
            let matches = regex.matches(in: self, options: [], range: range)
            return matches.compactMap { match in
                if let urlRange = Range(match.range, in: self) {
                    if let url = URL(string: String(self[urlRange])) {
                        return url
                    }
                }
                return nil
            }
        } catch {
            print("Error: \(error)")
            return []
        }
    }
    func compareVersion(_ otherVersion: String) -> ComparisonResult {
        let versionComponents = self.replacingOccurrences(of: "k", with: "").replacingOccurrences(of: "~", with: "").components(separatedBy: CharacterSet(charactersIn: ".-"))
        let otherComponents = otherVersion.replacingOccurrences(of: "k", with: "").replacingOccurrences(of: "~", with: "").components(separatedBy: CharacterSet(charactersIn: ".-"))
        
        // Function to compare numeric components
        func compareNumericComponent(_ component: String, with otherComponent: String) -> ComparisonResult {
            guard let numericComponent = Int(component), let otherNumericComponent = Int(otherComponent) else {
                return component.compare(otherComponent)
            }
            return numericComponent < otherNumericComponent ? .orderedAscending : (numericComponent > otherNumericComponent ? .orderedDescending : .orderedSame)
        }
        
        // Compare beta versions separately
        if versionComponents.contains(where: { $0.hasPrefix("b") }) && otherComponents.contains(where: { $0.hasPrefix("b") }) {
            let versionIndex = versionComponents.firstIndex(where: { $0.hasPrefix("b") })!
            let otherIndex = otherComponents.firstIndex(where: { $0.hasPrefix("b") })!
            let versionBeta = versionComponents[versionIndex]
            let otherBeta = otherComponents[otherIndex]
            
            if versionBeta != otherBeta {
                return versionBeta.compare(otherBeta)
            }
            
            let versionMain = versionComponents[0..<versionIndex].joined(separator: ".")
            let otherMain = otherComponents[0..<otherIndex].joined(separator: ".")
            
            return versionMain.compareVersion(otherMain)
        }
        
        // Compare revision versions separately
        if versionComponents.contains(where: { $0.hasPrefix("r") }) && otherComponents.contains(where: { $0.hasPrefix("r") }) {
            let versionIndex = versionComponents.firstIndex(where: { $0.hasPrefix("r") })!
            let otherIndex = otherComponents.firstIndex(where: { $0.hasPrefix("r") })!
            let versionRevision = versionComponents[versionIndex]
            let otherRevision = otherComponents[otherIndex]
            
            if versionRevision != otherRevision {
                return versionRevision.compare(otherRevision)
            }
            
            let versionMain = versionComponents[0..<versionIndex].joined(separator: ".")
            let otherMain = otherComponents[0..<otherIndex].joined(separator: ".")
            
            return versionMain.compareVersion(otherMain)
        }
        
        // Compare non-beta, non-alpha, non-revision versions
        for (index, component) in versionComponents.enumerated() {
            if index >= otherComponents.count {
                return .orderedDescending
            }
            
            let otherComponent = otherComponents[index]
            
            let comparisonResult: ComparisonResult
            if component.hasPrefix("b") || component.hasPrefix("a") || component.hasPrefix("r") {
                comparisonResult = component.compare(otherComponent)
            } else {
                comparisonResult = compareNumericComponent(component, with: otherComponent)
            }
            
            if comparisonResult != .orderedSame {
                return comparisonResult
            }
        }
        
        if versionComponents.count < otherComponents.count {
            return .orderedAscending
        }
        
        return .orderedSame
    }
    func isValidRepoFileFormat() -> Bool {
        if !self.contains("!DOCTYPE") {
            let lines = self.split(separator: "\n")
            for line in lines.prefix(4) {
                let components = line.split(separator: ":", maxSplits: 1)
                if components.count == 2 {
                    let firstPart = components[0].trimmingCharacters(in: .whitespaces)
                    let secondPart = components[1].trimmingCharacters(in: .whitespaces)
                    if !firstPart.isEmpty && !secondPart.isEmpty {
                        return true
                    }
                }
            }
        }
        return false
    }
}
