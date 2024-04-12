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
    @State private var updatableTweaks: [Package] = []
    
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
                    if !updatableTweaks.isEmpty {
                        Section(header: HStack {
                            Text("Updates")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                for pkg in updatableTweaks {
                                    if !appData.queued.all.contains(pkg.id) {
                                        appData.queued.install.append(pkg)
                                    }
                                    appData.queued.all.append(pkg.id)
                                }
                            }, label: {
                                Text("Upgrade all")
                            })
                        }) {
                            ForEach(updatableTweaks, id: \.id) { package in
                                TweakRowNavLinkWrapper(tweak: package).noListRowSeparator()
                                .listRowBackground(Color.clear).noListRowSeparator()
                            }
                        }.springAnim()
                    }
                    
                    Section(header: HStack {
                        Text("Installed Tweaks")
                            .font(.headline)
                        #if os(tvOS)
                        Spacer()
//                        Button(action: {
//                            
//                        }, label: {
//                            Text("Install local deb")
//                        })
                        #endif
                        if #available(tvOS 17.0, iOS 14.0, macCatalyst 14.0, *) {
                            #if !os(tvOS)
                            Spacer()
                            #endif
                            Menu("Sort By") {
                                Button(action: {
                                    self.appData.installed_pkgs.sort(by: { ($0.installDate ?? Date()) < ($1.installDate ?? Date()) })
                                }) {
                                    Text("Install Date")
                                }
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
                            if (updatableTweaks.first { $0.id == package.id } == nil) {
                                TweakRowNavLinkWrapper(tweak: package).noListRowSeparator()
                                    .listRowBackground(Color.clear).noListRowSeparator()
                            }
                        }
                    }.springAnim()
                    
                    #if !os(tvOS) && !os(macOS)
                    paddingBlock()
                    #endif
                }.animation(.spring(), value: filteredPackages.count)
            }
            .listStyle(.plain)
            .BGImage(appData)
            .largeNavBarTitle()
            .onAppear() {
                updatableTweaks = checkForUpdates(installed: appData.installed_pkgs, all: appData.pkgs)
            }
            #if !os(macOS)
            .navigationBarTitle("Installed")
            #endif
        }
    }
}
