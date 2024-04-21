//
//  Compat.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/19/24.
//

import Foundation
import SwiftUI

#if os(macOS)
typealias UIColor = NSColor
extension NSColor {
    static var secondaryLabel: NSColor {
        return NSColor.secondaryLabelColor
    }
}
#endif

struct NavigationViewC<Content: View>: View {
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

extension View {
    @ViewBuilder
    func tintC(_ tint: Color) -> some View {
        if #available(iOS 15, tvOS 15.0, macOS 13.0, *) {
            self.tint(tint)
        } else {
            self
        }
    }
    @ViewBuilder
    func navigationBarTitleC(_ title: String) -> some View {
        #if os(iOS)
        self.navigationBarTitle(title, displayMode: .large)
        #elseif !os(macOS)
        self.navigationBarTitle(title)
        #else
        self
        #endif
    }
    @ViewBuilder
    func listRowSeparatorC(_ visible: Bool) -> some View {
        #if os(iOS)
        if #available(iOS 15, *) {
            self.listRowSeparator(visible ? .visible : .hidden)
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func borderedProminentButtonC() -> some View {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, *) {
            self.buttonStyle(.borderedProminent)
        } else {
            self
        }
    }
}

struct SectionC<Content: View>: View {
    let text: String
    let content: Content

    init(_ text: String, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    var body: some View {
        if #available(iOS 15, tvOS 15.0, macOS 12.0, *) {
            Section(text) {
                content
            }
        } else {
            Section(header: Text(text)) {
                content
            }
        }
    }
}
