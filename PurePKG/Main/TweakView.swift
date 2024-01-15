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
                   .frame(width: UIScreen.main.bounds.width-40, height: 200)
                   .cornerRadius(15)
                   .clipped()
                   .listRowBackground(Color.clear).listRowSeparator(.hidden)
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
                                appData.queued.append(pkg)
                                queued = true
                            } else if queued {
                                appData.queued.remove(at: appData.queued.firstIndex(where: { $0.id == pkg.id }) ?? -2)
                                queued = false
                            }
                        }, label: {
                            Text(installed ? "Manage" : queued ? "Queued" : "Install")
                        }).buttonStyle(.borderedProminent).opacity(0.7).animation(.spring())
                        Text("").padding(.bottom, 35).listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                }
            }
            .listRowBackground(Color.clear).listRowSeparator(.hidden)
            
            TweakDepictionView(pkg: pkg, banner: $banner).listRowBackground(Color.clear).listRowSeparator(.hidden)
            
            if !(pkg.repo.url.path == "/") {
                Section(header: Text("Repo")) {
                    RepoRow(repo: pkg.repo)
                }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            
            HStack {
                Spacer()
                Text("\(pkg.id) (\(pkg.version))").foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .BGImage()
        .listStyle(.plain)
        .onAppear() {
            queued = appData.queued.contains(where: { $0.id == pkg.id })
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
        }
    }
}

