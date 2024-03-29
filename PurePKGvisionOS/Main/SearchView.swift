//
//  SearchView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    
    var filteredPackages: [Package] {
        if searchText.isEmpty {
            return appData.pkgs
        } else {
            return appData.pkgs.filter { package in
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
                    ForEach(filteredPackages, id: \.id) { package in
                        TweakRowNavLinkWrapper(tweak: package).noListRowSeparator().listRowBackground(Color.clear).noListRowSeparator()
                    }
                }.animation(.spring(), value: filteredPackages.count).springAnim()
            }
            .listStyle(.plain)
            .largeNavBarTitle()
            .navigationBarTitle("Search")
        }
    }
}

