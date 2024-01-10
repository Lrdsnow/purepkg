//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct BrowseView: View {
    @State private var Repos: [Repo] = []
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: Text("Hai")) {
                    HStack {
                        WebImage(url: URL(string: "real"))
                            .resizable()
                            .placeholder(Image("folder_icon").resizable().renderingMode(.template))
                            .indicator(.progress)
                            .transition(.fade)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        VStack(alignment: .leading) {
                            Text("All Tweaks")
                                .font(.headline)
                                .foregroundColor(Color.accentColor)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            Text("0 Tweaks Total")
                                .font(.subheadline)
                                .foregroundColor(Color.accentColor.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        }
                    }
                }.listRowBackground(Color.clear).padding(.vertical, 5).padding(.bottom, 10)
                Section("Repositories") {
                    ForEach(Repos, id: \.name) { repo in
                        NavigationLink(destination: Text("Hai")) {
                            RepoRow(repo: repo)
                        }
                    }
                }.listRowBackground(Color.clear)
            }.clearListBG().BGImage().task {
                RepoHandler.getRepos([URL(string: "https://apt.procurs.us/dists/iphoneos-arm64-rootless/1800/main/binary-iphoneos-arm64"), URL(string:"https://havoc.app"), URL(string:"https://repo.chariz.com")]) { Repo in
                    if !Repos.contains(where: { $0.url == Repo.url }) {
                        Repos.append(Repo)
                    }
                }
            }.navigationTitle("Browse").navigationBarTitleDisplayMode(.large).listStyle(.plain)
        }.navigationViewStyle(.stack)
    }
}

struct RepoRow: View {
    @State var repo: Repo
//    @State var appData: AppData?
    
    var body: some View {
        HStack {
            WebImage(url: repo.url.appendingPathComponent("CydiaIcon.png"))
                .resizable()
                .placeholder(Image("folder_icon").resizable().renderingMode(.template))
                .indicator(.progress)
                .transition(.fade)
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                Text(repo.url.absoluteString)
                    .font(.subheadline)
                    .foregroundColor(Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }
        }.padding(.vertical, 5).contextMenu(menuItems: {
            Button(action: {
                let pasteboard = UIPasteboard.general
                pasteboard.string = repo.url.absoluteString
            }) {
                Text("Copy Repo URL")
                Image("copy_icon").renderingMode(.template)
            }
            Button(action: {
                deleteRepo(repo: repo)
            }) {
                Text("Delete Repo")
                Image("trash_icon").renderingMode(.template)
            }.foregroundColor(.red)
            
        })
    }
    
    private func deleteRepo(repo: Repo?) {
//        guard let repo = repo, let appData = appData else {
//            return
//        }
//        if let urlIndex = appData.RepoData.urls.firstIndex(where: { $0.absoluteString.contains(repo.url?.absoluteString ?? "") }) {
//            appData.RepoData.urls.remove(at: urlIndex)
//        }
//        if var existingRepos = appData.repoSections[repo.repotype] {
//            if let existingRepoIndex = existingRepos.firstIndex(where: { $0.name == repo.name }) {
//                existingRepos.remove(at: existingRepoIndex)
//                appData.repoSections[repo.repotype] = existingRepos
//            }
//        }
//        appData.save()
    }
}
