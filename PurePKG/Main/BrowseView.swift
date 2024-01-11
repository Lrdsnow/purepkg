//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import TextFieldAlert

struct BrowseView: View {
    @State private var isAddingRepoURLAlertPresented = false
    @State private var isAddingRepoURLAlert16Presented = false
    @State private var RepoURLS: [URL?] = [URL(string: "https://apt.procurs.us/dists/iphoneos-arm64-rootless/1800/main/binary-iphoneos-arm64"), URL(string:"https://havoc.app"), URL(string:"https://repo.chariz.com")]
    @State private var Repos: [Repo] = []
    @State private var allTweaks: [Package] = []
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: allTweaks)) {
                    PlaceHolderRow(alltweaks: allTweaks.count, category: "", categoryTweaks: 0)
                }.listRowBackground(Color.clear).padding(.vertical, 5).padding(.bottom, 10).listRowSeparator(.hidden)
                Section("Repositories") {
                    ForEach(Repos, id: \.name) { repo in
                        NavigationLink(destination: RepoView(repo: repo)) {
                            RepoRow(repo: repo)
                        }.listRowSeparator(.hidden)
                    }
                }.listRowBackground(Color.clear)
            }.clearListBG().BGImage().task {
                if Repos.isEmpty {
                    RepoHandler.getRepos(RepoURLS) { Repo in
                        if !Repos.contains(where: { $0.url == Repo.url }) {
                            Repos.append(Repo)
                            allTweaks = Repos.flatMap { $0.tweaks }
                        }
                    }
                }
            }.navigationTitle("Browse").navigationBarTitleDisplayMode(.large).listStyle(.plain)
                .navigationBarItems(trailing:
                Button(action: {
                    if #available(iOS 16, *) {
                        isAddingRepoURLAlert16Presented = true
                    } else {
                        isAddingRepoURLAlertPresented = true
                    }
                }) {
                    Image("plus_icon")
                        .renderingMode(.template)
                }
                )
        }.navigationViewStyle(.stack)
    }
}

struct RepoView: View {
    @State var repo: Repo

    var body: some View {
        List {
            NavigationLink(destination: TweaksListView(pageLabel: repo.name, tweaksLabel: "All Tweaks", tweaks: repo.tweaks)) {
                PlaceHolderRow(alltweaks: repo.tweaks.count, category: "", categoryTweaks: 0)
            }.listRowBackground(Color.clear).padding(.vertical, 5).padding(.bottom, 10).listRowSeparator(.hidden)
            Section("Categories") {
                ForEach(Array(Set(repo.tweaks.map { $0.section })), id: \.self) { category in
                    let categoryTweaks = repo.tweaks.filter { $0.section == category }
                    NavigationLink(destination: TweaksListView(pageLabel: repo.name, tweaksLabel: category, tweaks: categoryTweaks)) {
                        PlaceHolderRow(alltweaks: -1, category: category, categoryTweaks: categoryTweaks.count)
                    }.listRowSeparator(.hidden)
                }
            }.listRowBackground(Color.clear)
        }
        .clearListBG()
        .BGImage()
        .navigationTitle(repo.name)
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.plain)
    }
}

struct TweaksListView: View {
    let pageLabel: String
    let tweaksLabel: String
    let tweaks: [Package]
    
    var body: some View {
        List {
            Section(tweaksLabel) {
                ForEach(tweaks, id: \.name) { tweak in
                    NavigationLink(destination: Text("Hai")) {
                        TweakRow(tweak: tweak)
                    }.listRowSeparator(.hidden)
                }
            }.listRowBackground(Color.clear)
        }.clearListBG()
            .BGImage()
            .navigationTitle(pageLabel)
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.plain)
    }
}

struct PlaceHolderRow: View {
    let alltweaks: Int
    let category: String
    let categoryTweaks: Int
    
    var body: some View {
        HStack {
            Image("DisplayAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            VStack(alignment: .leading) {
                if alltweaks != -1 {
                    Text("All Tweaks")
                        .font(.headline)
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    Text("\(alltweaks) Tweaks Total")
                        .font(.subheadline)
                        .foregroundColor(Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                } else {
                    Text(category)
                        .font(.headline)
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    Text("\(categoryTweaks) Tweaks")
                        .font(.subheadline)
                        .foregroundColor(Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                }
            }
        }
    }
}

struct RepoRow: View {
    @State var repo: Repo
//    @State var appData: AppData?
    
    var body: some View {
        HStack {
            WebImage(url: repo.url.appendingPathComponent("CydiaIcon.png"))
                .resizable()
                .placeholder(Image("DisplayAppIcon").resizable())
                .indicator(.progress)
                .scaledToFit()
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

struct TweakRow: View {
    @State var tweak: Package
    var body: some View {
        HStack {
            WebImage(url: tweak.icon)
                .resizable()
                .placeholder(Image("DisplayAppIcon").resizable())
                .indicator(.progress)
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            
            VStack(alignment: .leading) {
                Text(tweak.name)
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                Text(tweak.desc)
                    .font(.subheadline)
                    .foregroundColor(Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            }
        }.padding(.vertical, 5)
    }
}
