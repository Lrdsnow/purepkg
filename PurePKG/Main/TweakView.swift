//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct TweakView: View {
    @EnvironmentObject var appData: AppData
    @State private var installed = false
    @State private var queued = false
    @State private var banner: URL? = nil
    let pkg: Package
    
    var body: some View {
        List {
            if let banner = banner {
               KFImage(banner)
                   .resizable()
                   .aspectRatio(contentMode: .fill)
                #if targetEnvironment(macCatalyst)
                   .frame(width: appData.size.width-40, height: 200)
                #else
                   .frame(width: UIScreen.main.bounds.width-40, height: 200)
                #endif
                   .cornerRadius(20)
                   .clipped()
                   .listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
                   .padding(.bottom)
                   .padding(.top, -40)
            }
            
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        KFImage(pkg.icon)
                            .resizable()
                            .onFailureImage(UIImage(named: "DisplayAppIcon"))
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(15)
                            .padding(.trailing, 5)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        VStack(alignment: .leading) {
                            Text(pkg.name)
                                .font(.headline.bold())
                                .lineLimit(1)
                            Text(pkg.author)
                                .font(.subheadline)
                                .opacity(0.7)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: {
                            if !queued && !installed {
                                appData.queued.install.append(pkg)
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
                        }, label: {
                            Text(queued ? "Queued" : installed ? "Uninstall" : "Install")
                        }).buttonStyle(.borderedProminent).opacity(0.7).animation(.spring())
                    }
                }
            }
            .listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            
            TweakDepictionView(pkg: pkg, banner: $banner).listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            
            if !(pkg.repo.url.path == "/") {
                Section(header: Text("Repo")) {
                    RepoRow(repo: pkg.repo, focused: .constant(false))
                }.listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            }
            
            HStack {
                Spacer()
                Text("\(pkg.id) (\(pkg.version))").foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
            }.listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            
            Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
        }
        .BGImage(appData)
        .listStyle(.plain)
        .onChange(of: appData.queued.all.count, perform: { _ in queued = appData.queued.all.contains(pkg.id) })
        .onAppear() {
            queued = appData.queued.all.contains(pkg.id)
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
        }
    }
}

