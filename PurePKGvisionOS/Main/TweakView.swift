//
//  TweakView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
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
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        KFImage(pkg.icon)
                            .resizable()
                            .onFailureImage(UIImage(named: "DisplayAppIcon"))
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(200)
                            .padding(.trailing, 5)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        VStack(alignment: .leading) {
                            Text(pkg.name)
                                .font(.title.bold())
                                .lineLimit(1)
                            Text(pkg.author)
                                .font(.title2)
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
                        }).buttonStyle(.borderedProminent).opacity(0.7).springAnim()
                    }
                }
            }
            .listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            
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
            
            paddingBlock()
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

