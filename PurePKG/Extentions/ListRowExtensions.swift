//
//  ListRowExtensions.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func listRowBG() -> some View {
        #if os(macOS) || os(visionOS)
        self
        #elseif os(watchOS)
        self.listRowBackground(Color.accentColor.opacity(0.05).cornerRadius(8))
        #elseif os(tvOS)
        self.listRowBackground(Color.accentColor.opacity(0.05).cornerRadius(10))
        #else
        self.listRowBackground(Color.accentColor.opacity(0.05))
        #endif
    }
}
