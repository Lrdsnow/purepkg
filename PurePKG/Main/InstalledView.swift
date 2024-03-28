//
//  InstalledView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
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
        CustomNavigationView {
            VStack {
                TextField("Search Installed Tweaks", text: $searchText)
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
                    Section(header: HStack {
                        Text("Installed Tweaks")
                            .font(.headline)
                        if #available(tvOS 17.0, iOS 14.0, macCatalyst 14.0, *) {
                            Spacer()
                            Menu("Sort By") {
                                Button(action: {
                                    self.appData.installed_pkgs.sort(by: { $0.installed_size < $1.installed_size })
                                }) {
                                    Text("Install Size")
                                }
                                Button(action: {
                                    self.appData.installed_pkgs.sort(by: { $0.name < $1.name })
                                }) {
                                    Text("Name")
                                }
                            }
                            .accentShadow()
                        }
                    }) {
                        ForEach(filteredPackages, id: \.id) { package in
                            TweakRowNavLinkWrapper(tweak: package).noListRowSeparator()
                            .listRowBackground(Color.clear).noListRowSeparator()
                        }
                    }.springAnim()
                    Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
                }.animation(.spring(), value: filteredPackages.count)
            }
            .listStyle(.plain)
            .BGImage(appData)
            .largeNavBarTitle()
            #if !os(macOS)
            .navigationBarTitle("Installed")
            #endif
        }
    }
}
