//
//  ColorExtensions.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/21/24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

#if TARGET_IOS_MAJOR_13
extension Color {
    public func toHex() -> String {
        return UIColor(self).toHex()
    }
    
    public init?(hex: String) {
        if let uicolor = UIColor(hex: hex) {
            self = Color(uicolor)
        } else {
            return nil
        }
    }
}
#endif

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
