//
//  SearchView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct SearchView2: View {
    var body: some View {
        Text("Search View")
    }
}

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
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .background(Color.accentColor.opacity(0.05))
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    self.searchText = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 10)
                List {
                    ForEach(filteredPackages, id: \.id) { package in
                        TweakRowNavLinkWrapper(tweak: package).noListRowSeparator().listRowBackground(Color.clear).noListRowSeparator()
                    }
                    Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
                }.animation(.spring(), value: filteredPackages.count).springAnim()
            }.navigationBarTitle("Search").listStyle(.plain).BGImage(appData)
            .largeNavBarTitle()
        }.navigationViewStyle(.stack)
    }
}
