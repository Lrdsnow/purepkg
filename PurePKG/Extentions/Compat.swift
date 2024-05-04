//
//  Compat.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/19/24.
//

import Foundation
import SwiftUI
import Combine

#if os(macOS)
typealias UIColor = NSColor
typealias UIImage = NSImage
typealias UIApplication = NSWorkspace
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

extension Image {
    init(uiImageC: UIImage) {
        #if os(macOS)
        self = Image(nsImage: uiImageC)
        #else
        self = Image(uiImage: uiImageC)
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
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.navigationBarTitle(title, displayMode: .large)
        } else {
            self.navigationBarTitle(title)
        }
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
    @ViewBuilder
    func clearListBG() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func refreshableC(_ action: @escaping () -> Void) -> some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            self.refreshable { action() }
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func onOpenURLC(_ action: @escaping (URL) -> Void) -> some View {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            self.onOpenURL { url in action(url) }
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func onChangeC<T: Equatable>(of: T, perform: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.onChange(of: of, perform: perform)
        } else {
            self.onReceive(Just(of)) { (of) in
                perform(of)
            }
        }
    }
    @ViewBuilder
    func contextMenuC(@ViewBuilder menuItems: @escaping () -> some View) -> some View {
        if #available(tvOS 14.0, iOS 14.0, *) {
            self.contextMenu {
                menuItems()
            }
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
