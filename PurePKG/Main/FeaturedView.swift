//
//  FeaturedView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct FeaturedView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Featured View")
                NavigationLink(destination: SettingsView(), label: {Text("Settings")})
            }
        }.navigationTitle("Featured").navigationViewStyle(.stack)
    }
}
