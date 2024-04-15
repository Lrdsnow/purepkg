//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
import SwiftUI
import NukeUI

struct BrowseView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: {
                    //TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs)
                }, label: {
                    PlaceHolderRow(alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0).listRowSeparatorC(false)
                }).listRowBackground(Color.clear)
                SectionC("Repositories") {
                    ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.id) { repo in
                        NavigationLink(destination: {
                            
                        }) {
                            RepoRow(repo: repo)
                        }.listRowSeparatorC(false)
                    }
                }.listRowBackground(Color.clear)
            }.navigationBarTitleC("Browse").navigationBarItems(trailing: HStack {
                Button(action: {
                    refreshRepos(appData)
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                NavigationLink(destination: {}) {
                    Image(systemName: "gearshape.fill")
                }
            })
        }
    }
}

struct PlaceHolderRow: View {
    let alltweaks: Int
    let category: String
    let categoryTweaks: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Spacer()
                Image("DisplayAppIcon")
                    .resizable()
                    .scaledToFit()
#if os(tvOS)
                    .frame(width: 70, height: 70)
                    .cornerRadius(15)
#else
                    .frame(width: 50, height: 50)
                    .cornerRadius(11)
#endif
                Spacer()
            }
#if os(tvOS)
            .padding(.trailing, -40)
#endif
            VStack(alignment: .leading) {
                if alltweaks != -1 {
                    Text("All Tweaks")
                        .font(.headline)
                    Text("\(alltweaks) Tweaks Total")
                        .font(.subheadline)
                } else {
                    Text(category)
                        .font(.headline)
                    Text("\(categoryTweaks) Tweaks")
                        .font(.subheadline)
                }
            }
        }
    }
}

struct RepoRow: View {
    @EnvironmentObject var appData: AppData
    @State var repo: Repo
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Spacer()
                LazyImage(url: (URL(string: repo.url.absoluteString.replacingOccurrences(of: "refreshing/", with: "")) ?? URL(fileURLWithPath: "/")).appendingPathComponent("CydiaIcon.png")) { state in
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
                }
#if os(tvOS)
                    .frame(width: 70, height: 70)
                    .cornerRadius(15)
#else
                    .frame(width: 50, height: 50)
                    .cornerRadius(11)
#endif
                Spacer()
            }
#if os(tvOS)
            .padding(.trailing, -40)
#endif
            
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(repo.url.absoluteString.replacingOccurrences(of: "/./", with: "").replacingOccurrences(of: "refreshing/", with: "").removeSubstringIfExists("/dists/"))\(repo.component != "main" ? " (\(repo.component))" : "")")
                    .font(.subheadline)
                    .lineLimit(1)
                if repo.error != nil {
                    Text(repo.error ?? "")
                        .font(.footnote)
                        .lineLimit(1)
                }
            }
        }.contextMenu(menuItems: {
#if os(tvOS)
#else
            Button(action: {
#if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(repo.url.absoluteString, forType: .string)
#else
                let pasteboard = UIPasteboard.general
                pasteboard.string = repo.url.absoluteString
#endif
            }) {
                Text("Copy Repo URL")
                Image("copy_icon").renderingMode(.template)
            }
#endif
            if #available(iOS 15.0, tvOS 15.0, *) {
                Button(role: .destructive, action: {
                    RepoHandler.removeRepo(repo.url)
                    refreshRepos(appData)
                }) {
                    Text("Delete Repo")
                    Image("trash_icon").renderingMode(.template)
                }.foregroundColor(.red)
            } else {
                Button(action: {
                    RepoHandler.removeRepo(repo.url)
                    refreshRepos(appData)
                }) {
                    Text("Delete Repo")
                    Image("trash_icon").renderingMode(.template)
                }.foregroundColor(.red)
            }
        })
    }
}
