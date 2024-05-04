//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
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
    let preview: Bool
    
    var body: some View {
        List {
            if #available(iOS 14.0, tvOS 14.0, *) {
                if let banner = banner {
                    LazyImage(url: banner) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ProgressView()
                                .scaledToFit()
                        }
                    }
#if !os(macOS)
                    .frame(width: (preview ? UIScreen.main.bounds.width/1.5 : UIScreen.main.bounds.width)-40, height: preview ? 100 : 200)
#endif
                    .cornerRadius(20)
                    .clipped()
                    .listRowBackground(Color.clear)
                    .listRowSeparatorC(false)
                    .padding(.bottom)
                    .padding(.top, -40)
                }
            }
            
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        if #available(iOS 14.0, tvOS 14.0, *) {
                            LazyImage(url: pkg.icon) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaledToFit()
                                } else if state.error != nil {
                                    Image(uiImageC: UIImage(named: "AppIcon") ?? UIImage(named: "App Icon")!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaledToFit()
                                } else {
                                    ProgressView()
                                        .scaledToFit()
                                }
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(15)
                            .padding(.trailing, 5)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(pkg.name)
                                .font(.headline.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(pkg.author)
                                .font(.subheadline)
                                .opacity(0.7)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        Spacer()
                        Button(action: {
                            installPKG()
                        }, label: {
                            Text(queued ? "Queued" : installed ? "Uninstall" : "Install")
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }).borderedProminentButtonC().opacity(0.7).animation(.spring()).contextMenuC(menuItems: {
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
                            if !installed, !(pkg.repo.url.path == "/"), pkg.path != "" {
                                let debURL = pkg.repo.url.appendingPathComponent(pkg.path)
                                Button(action: {
                                    UIApplication.shared.open(debURL)
                                }) {
                                    Text("Download deb")
                                }
                            }
                        })
                    }
                }
            }
            .listRowBackground(Color.clear).listRowSeparatorC(false)
            
            #if !os(macOS)
            if !preview {
                TweakDepictionView(pkg: pkg, banner: $banner).listRowBackground(Color.clear).listRowSeparatorC(false)
            }
            #endif
            
            if !(pkg.repo.url.path == "/") {
                Section(header: Text("Repo")) {
                    RepoRow(repo: pkg.repo)
                }.listRowBackground(Color.clear).listRowSeparatorC(false)
            }
            
            HStack {
                Spacer()
                Text("\(pkg.id) (\(pkg.installedVersion == "" ? pkg.version : pkg.installedVersion))\(pkg.installedVersion == "" ? "" : " (\(pkg.version) available)")").foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
            }.listRowBackground(Color.clear).listRowSeparatorC(false)
        }
        .appBG()
        .listStyle(.plain)
        .onChangeC(of: appData.queued.all.count, perform: { _ in queued = appData.queued.all.contains(pkg.id) })
        .onAppear() {
            queued = appData.queued.all.contains(pkg.id)
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
            installedPKG = appData.installed_pkgs.first(where: { $0.id == pkg.id })
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

