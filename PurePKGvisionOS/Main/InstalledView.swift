//
//  InstalledView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI

struct InstalledView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    @State private var isAnimating = false
    
    var filteredPackages: [Package] {
        if searchText.isEmpty {
            return appData.installed_pkgs
        } else {
            return appData.installed_pkgs.filter { package in
                package.name.localizedCaseInsensitiveContains(searchText) ||
                package.id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search", text: $searchText)
                    .padding(7)
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 20)
                List {
                    Section() {
                        ForEach(filteredPackages, id: \.id) { package in
                            TweakRowNavLinkWrapper(tweak: package).noListRowSeparator()
                            .listRowBackground(Color.clear).noListRowSeparator()
                        }
                    }.springAnim()
                }.animation(.spring(), value: filteredPackages.count)
            }
            .listStyle(.plain)
            .largeNavBarTitle()
            .navigationBarTitle("Installed")
        }
    }
}

