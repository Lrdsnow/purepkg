//
//  Misc.swift
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
import SwiftUI


#if !os(watchOS) && !os(macOS)
public extension UIDevice {
    var modelName: String {
        #if targetEnvironment(simulator)
            let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Unknown"
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        #endif
        return identifier
    }
}
#endif

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    static var documents: URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/var/mobile/.purepkg")
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: documentDirectory.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            return documentDirectory
        } else {
            return URL(fileURLWithPath: "/var/mobile/.purepkg")
        }
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
    func removeSubstringIfExists(_ substring: String) -> String {
        if let range = self.range(of: substring) {
            let substringRange = self.startIndex..<range.lowerBound
            return String(self[substringRange])
        } else {
            return self
        }
    }
}

extension Color {
    private func makeColor(componentDelta: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var blue: CGFloat = 0
        var green: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Extract r,g,b,a components from the current UIColor
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Create a new UIColor modifying each component by componentDelta
        return UIColor(
            red: add(componentDelta, toComponent: red),
            green: add(componentDelta, toComponent: green),
            blue: add(componentDelta, toComponent: blue),
            alpha: alpha
        )
    }
    
    func darker(_ componentDelta: CGFloat = 0.1) -> Color {
        return Color(makeColor(componentDelta: -1 * componentDelta))
    }
    
    private func add(_ delta: CGFloat, toComponent component: CGFloat) -> CGFloat {
        return max(0, min(1, component + delta))
    }
}

#if os(watchOS)
#elseif os(macOS)
extension UIApplication {
    
    func dismissAlert(animated: Bool) {
    }
    
    func alert(title: String = "", body: String, animated: Bool = true, withButton: Bool = true) {
    }
}
#else
// Alert++
// credit: sourcelocation & TrollTools
var currentUIAlertController: UIAlertController?


fileprivate let errorString = NSLocalizedString("Error", comment: "")
fileprivate let okString = NSLocalizedString("OK", comment: "")
fileprivate let cancelString = NSLocalizedString("Cancel", comment: "")

extension UIApplication {
    
    func dismissAlert(animated: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController?.dismiss(animated: animated)
        }
    }
    
    func alert(title: String = errorString, body: String, animated: Bool = true, withButton: Bool = true) {
        DispatchQueue.main.async {
            var body = body
            
            if title == errorString {
                // append debug info
                let device = UIDevice.current
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                _ = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
                let systemVersion = device.systemVersion
                body += "\n\(device.systemName) \(systemVersion), PurePKG v\(appVersion)"
            }
            
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if withButton { currentUIAlertController?.addAction(.init(title: okString, style: .cancel)) }
            self.present(alert: currentUIAlertController!)
        }
    }
    func confirmAlert(title: String = errorString, body: String, confirmTitle: String = okString, onOK: @escaping () -> (), noCancel: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if !noCancel {
                currentUIAlertController?.addAction(.init(title: cancelString, style: .cancel))
            }
            currentUIAlertController?.addAction(.init(title: confirmTitle, style: noCancel ? .cancel : .default, handler: { _ in
                onOK()
            }))
            self.present(alert: currentUIAlertController!)
        }
    }
    func change(title: String = errorString, body: String) {
        DispatchQueue.main.async {
            currentUIAlertController?.title = title
            currentUIAlertController?.message = body
        }
    }
    
    func present(alert: UIAlertController) {
        if var topController = self.windows.first?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true)
            // topController should now be your topmost view controller
        }
    }
}
#endif

func log(_ text: Any...) {
    let logFilePath = URL.documents.appendingPathComponent("purepkg_app_logs.txt").path
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    let timestamp = dateFormatter.string(from: Date())
    
    let logContent = text.map { "\($0)" }.joined(separator: " ")
    let logEntry = "\(timestamp): \(logContent)\n"
    NSLog(logContent)
    
    if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
        fileHandle.seekToEndOfFile()
        if let logData = logEntry.data(using: .utf8) {
            fileHandle.write(logData)
        }
        fileHandle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
            fileHandle.seekToEndOfFile()
            if let logData = logEntry.data(using: .utf8) {
                fileHandle.write(logData)
            }
            fileHandle.closeFile()
        }
    }
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

extension UIImage {
    func downscaled(to size: CGSize) -> UIImage? {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

struct CustomNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
#if os(macOS)
        NavigationStack {
            content
        }
#else
        NavigationView {
            content
        }.navigationViewStyle(.stack)
#endif
    }
}

struct CustomHStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if UserDefaults.standard.bool(forKey: "lazyLoadRows") {
            LazyHStack {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}


extension String {
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
        let versionComponents = self.replacingOccurrences(of: "k", with: "").components(separatedBy: CharacterSet(charactersIn: ".-"))
        let otherComponents = otherVersion.replacingOccurrences(of: "k", with: "").components(separatedBy: CharacterSet(charactersIn: ".-"))
        
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
}


extension String {
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

struct paddingBlock: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        if !appData.basicMode {
            Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
        }
    }
}

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    func toHex(includeAlpha: Bool = true) -> String {
        guard let components = cgColor?.components, let numberOfComponents = cgColor?.numberOfComponents else {
            return ""
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1.0

        if numberOfComponents >= 3 {
            red = components[0]
            green = components[1]
            blue = components[2]
        }

        if numberOfComponents >= 4 {
            alpha = components[3]
        }

        let redValue = Int(red * 255)
        let greenValue = Int(green * 255)
        let blueValue = Int(blue * 255)
        let alphaValue = Int(alpha * 255)

        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", redValue, greenValue, blueValue, alphaValue)
        } else {
            return String(format: "#%02X%02X%02X", redValue, greenValue, blueValue)
        }
    }
}

extension UIColor {
    public func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
            
        getRed(&r, green: &g, blue: &b, alpha: &a)
            
        let redComponent = Int(r * 255)
        let greenComponent = Int(g * 255)
        let blueComponent = Int(b * 255)
        let alphaComponent = Int(a * 255)
            
        let hexString = String(format: "#%02X%02X%02X%02X", redComponent, greenComponent, blueComponent, alphaComponent)
        
        return hexString
    }
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 || hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    if hexColor.count == 6 {
                        r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        b = CGFloat(hexNumber & 0x000000ff) / 255
                        a = 1.0
                    } else {
                        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                        a = CGFloat(hexNumber & 0x000000ff) / 255
                    }

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
