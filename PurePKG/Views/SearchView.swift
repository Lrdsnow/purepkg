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
                #if !os(tvOS)
                    .padding(.horizontal, 25)
                    .background(Color.accentColor.opacity(0.05))
                #endif
                    .cornerRadius(8)
                    .autocorrectionDisabled()
                #if !os(tvOS)
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
                    ForEach(filteredPackages, id: \.id) { package in
                        NavigationLink(destination: {
                            TweakView(pkg: package)
                        }, label: {
                            TweakRow(tweak: package)
                        }).listRowBackground(Color.clear).listRowSeparatorC(false)
                    }
                }.animation(.spring(), value: filteredPackages.count)
            }
            .listStyle(.plain)
            .navigationBarTitleC("Search")
        }
    }
}
