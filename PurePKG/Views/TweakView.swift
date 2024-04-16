//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI
import NukeUI

struct TweakView: View {
    @EnvironmentObject var appData: AppData
    @State private var installed = false
    @State private var installedPKG: Package? = nil
    @State private var queued = false
    @State private var banner: URL? = nil
    let pkg: Package
    
    var body: some View {
        List {
            HStack {
                LazyImage(url: pkg.icon) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                    } else if state.error != nil {
                        Image("DisplayAppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                    } else {
                        ProgressView()
                            .scaledToFit()
                    }
                }.frame(width: 100, height: 100).cornerRadius(20).padding(.trailing, 5)
                VStack {
                    Text(pkg.name).font(.system(size: 30, weight: .bold, design: .rounded))
                }
                Spacer()
                Button(action: {
                    installPKG()
                }, label: {
                    Text(queued ? "Queued" : installed ? "Uninstall" : "Install")
                }).contextMenu(menuItems: {
                    if !queued && !installed {
                        ForEach(pkg.versions.sorted(by: { $1.compareVersion($0) == .orderedAscending }).removingDuplicates(), id: \.self) { ver in
                            Button(action: {installPKG(ver)}) {
                                Text(ver)
                            }
                        }
                    }
                    if installed {
                        ForEach(pkg.versions.sorted(by: { $1.compareVersion($0) == .orderedAscending }).removingDuplicates(), id: \.self) { ver in
                            if let installedPKG = installedPKG, installedPKG.version != ver {
                                Button(action: {installPKG(ver)}) {
                                    Text("\(installedPKG.version.compareVersion(ver) == .orderedAscending ? "Upgrade to" : "Downgrade to") \(ver)")
                                }
                            }
                        }
                    }
                })
            }.padding().listRowInsets(EdgeInsets()).listRowBackground(Color.clear).listRowSeparatorC(false)
            
            if !(pkg.repo.url.path == "/") {
                Section(header: Text("Repo")) {
                    RepoRow(repo: pkg.repo)
                }.listRowBackground(Color.clear).listRowSeparatorC(false)
            }
            
            HStack {
                Spacer()
                Text("\(pkg.id) (\(pkg.installedVersion == "" ? pkg.version : pkg.installedVersion))\(pkg.installedVersion == "" ? "" : " (\(pkg.version) available)")").foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
            }.listRowBackground(Color.clear).listRowSeparatorC(false)
        }.onAppear() {
            queued = appData.queued.all.contains(pkg.id)
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
            installedPKG = appData.installed_pkgs.first(where: { $0.id == pkg.id })
            print(pkg)
        }
    }
    
    func installPKG(_ version: String? = nil) {
        if !queued && !installed {
            if let version = version {
                var diffVerPKG = pkg
                diffVerPKG.version = version
                appData.queued.install.append(diffVerPKG)
            } else {
                appData.queued.install.append(pkg)
            }
            appData.queued.all.append(pkg.id)
        } else if queued {
            if let index = appData.queued.install.firstIndex(where: { $0.id == pkg.id }) {
                appData.queued.install.remove(at: index)
            }
            if let index = appData.queued.uninstall.firstIndex(where: { $0.id == pkg.id }) {
                appData.queued.uninstall.remove(at: index)
            }
            if let index = appData.queued.all.firstIndex(where: { $0 == pkg.id }) {
                appData.queued.all.remove(at: index)
            }
        } else if installed {
            appData.queued.uninstall.append(pkg)
            appData.queued.all.append(pkg.id)
        }
    }
}
