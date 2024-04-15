//
//  Compat.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/19/24.
//

import Foundation
import SwiftUI

// stuff for iOS 14 and below - once i work on adding support for those vers

extension View {
    @ViewBuilder
    func tintC(_ tint: Color) -> some View {
        if #available(iOS 15, tvOS 15.0, *) {
            self.tint(tint)
        } else {
            self
        }
    }
    @ViewBuilder
    func navigationBarTitleC(_ title: String) -> some View {
        #if os(iOS)
        self.navigationBarTitle(title, displayMode: .large)
        #else
        self.navigationBarTitle(title)
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
}

struct SectionC<Content: View>: View {
    let text: String
    let content: Content

    init(_ text: String, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    var body: some View {
        if #available(iOS 15, tvOS 15.0, *) {
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

struct BorderedProminentC: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 15.0, tvOS 15.0, *) {
            configuration.label
                .buttonStyle(.borderedProminent)
        } else {
            configuration.label
                .buttonStyle(.plain)
        }
    }
}

extension ButtonStyle where Self == BorderedProminentC {
    static var borderedProminentC: Self { Self() }
}
