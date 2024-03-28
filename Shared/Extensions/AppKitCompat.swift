//
//  AppKitCompat.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/27/24.
//

#if os(macOS)
import Foundation
import AppKit

typealias UIColor = NSColor
typealias UIScreen = NSScreen
typealias UIBezierPath = NSBezierPath
typealias UIFont = NSFont
typealias UIImage = NSImage
typealias UIEdgeInsets = NSEdgeInsets
typealias UIViewController = NSViewController
typealias UIView = NSView
typealias UIScrollView = NSScrollView
typealias UIActivityIndicatorView = NSProgressIndicator
typealias UIApplication = NSApplication
typealias UIDevice = Host
typealias UIPasteboard = NSPasteboard

extension NSColor {
    static var secondaryLabel: NSColor {
        return NSColor.secondaryLabelColor
    }
}

#endif
