//
//  SearchView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    let preview: Bool
    
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
        NavigationViewC {
            VStack {
                TextField("Search", text: $searchText)
                    .padding(7)
                #if !os(tvOS)
                    .padding(.horizontal, 25)
                    .background(Color.accentColor.opacity(0.05))
                #endif
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                #if os(iOS)
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
                #endif
                List {
                    ForEach(filteredPackages.prefix(preview ? 10 : filteredPackages.count), id: \.id) { package in
                        NavigationLink(destination: {
                            TweakView(pkg: package, preview: false)
                        }, label: {
                            TweakRow(tweak: package)
                        }).listRowBackground(Color.clear).listRowSeparatorC(false)
                    }
                }.animation(.spring(), value: filteredPackages.count)
            }
            .appBG()
            .listStyle(.plain)
            .navigationBarTitleC("Search")
        }
    }
}
