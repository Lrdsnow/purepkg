//
//  InstalledView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

enum sortInstalledBy {
    case date
    case size
    case name
}

struct InstalledView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    @State private var isAnimating = false
    @State private var updatableTweaks: [Package] = []
    let preview: Bool
    
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
        NavigationViewC {
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
                                NavigationLink(destination: {
                                    TweakView(pkg: package, preview: preview)
                                }, label: {
                                    TweakRow(tweak: package)
                                }).listRowBackground(Color.clear).listRowSeparatorC(false)
                            }
                        }
                    }
                    
                    Section(header: HStack {
                        Text("Installed Tweaks")
                            .font(.headline)
                        if #available(tvOS 17.0, iOS 14.0, macCatalyst 14.0, *) {
                            Spacer()
                            Menu("Sort By") {
                                Button(action: {
                                    self.sort(.date)
                                }) {
                                    Text("Install Date")
                                }
                                Button(action: {
                                    self.sort(.size)
                                }) {
                                    Text("Install Size")
                                }
                                Button(action: {
                                    self.sort(.name)
                                }) {
                                    Text("Name")
                                }
                            }
                        }
                    }) {
                        ForEach(filteredPackages.prefix(preview ? 10 : filteredPackages.count), id: \.id) { package in
                            if (updatableTweaks.first { $0.id == package.id } == nil) {
                                NavigationLink(destination: {
                                    TweakView(pkg: package, preview: preview)
                                }, label: {
                                    TweakRow(tweak: package)
                                }).listRowBackground(Color.clear).listRowSeparatorC(false)
                            }
                        }
                    }
                    
                }.animation(.spring(), value: filteredPackages.count)
            }
            .listStyle(.plain)
            .onAppear() {
                if !preview {
                    updatableTweaks = checkForUpdates(installed: appData.installed_pkgs, all: appData.pkgs)
                }
                self.sort()
            }
            .navigationBarTitleC("Installed")
        }
    }
    
    func sort(_ sort: sortInstalledBy? = nil) {
        if let sort = sort {
            UserDefaults.standard.setValue((sort == .date ? 0 : sort == .size ? 1 : 2), forKey: "sortInstalledBy")
            switch sort {
            case .date:
                self.appData.installed_pkgs.sort(by: { ($0.installDate ?? Date()) < ($1.installDate ?? Date()) })
            case .size:
                self.appData.installed_pkgs.sort(by: { $0.installed_size < $1.installed_size })
            case .name:
                self.appData.installed_pkgs.sort(by: { $0.name < $1.name })
            }
        } else {
            let savedSortInt = UserDefaults.standard.integer(forKey: "sortInstalledBy")
            var savedSort: sortInstalledBy = .date
            if savedSortInt == 1 { savedSort = .size } else if savedSortInt == 2 { savedSort = .name }
            self.sort(savedSort)
        }
    }
}
