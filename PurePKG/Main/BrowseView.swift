//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import Kingfisher
import TextFieldAlert

struct BrowseView: View {
    @EnvironmentObject var appData: AppData
    @State private var isAddingRepoURLAlertPresented = false
    @State private var isAddingRepoURLAlert16Presented = false
    
    var body: some View {
        NavigationView {
            if !appData.repos.isEmpty {
                List {
                    NavigationLink(destination: TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs)) {
                        PlaceHolderRow(alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0)
                    }.listRowBackground(Color.clear).padding(.vertical, 5).padding(.bottom, 10).listRowSeparator(.hidden)
                    Section("Repositories") {
                        ForEach(appData.repos, id: \.name) { repo in
                            NavigationLink(destination: RepoView(repo: repo)) {
                                RepoRow(repo: repo)
                            }.listRowSeparator(.hidden)
                        }
                    }.listRowBackground(Color.clear)
                }.clearListBG().BGImage().navigationTitle("Browse").animation(.spring(), value: appData.repos.count).navigationBarTitleDisplayMode(.large).listStyle(.plain)
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
                    ).refreshable {
                        appData.repos = []
                    }
            } else {
                VStack {
                    ZStack {
                        ProgressView()
                        Text("\n\n\nGetting Repos...").foregroundColor(Color.accentColor)
                    }.task() {
                        DispatchQueue.main.async {
                            appData.repo_urls = RepoHandler.getAptSources(Jailbreak.path()+"/etc/apt/sources.list.d")
                            DispatchQueue.global(qos: .background).async {
                                RepoHandler.getRepos(appData.repo_urls) { Repo in
                                    DispatchQueue.main.async {
                                        if !appData.repos.contains(where: { $0.url == Repo.url }) {
                                            appData.repos.append(Repo)
                                            appData.pkgs  = appData.repos.flatMap { $0.tweaks }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.BGImage().navigationTitle("Browse").navigationBarTitleDisplayMode(.large)
            }
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
                    NavigationLink(destination: TweakView(pkg: tweak)) {
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
            KFImage(repo.url.appendingPathComponent("CydiaIcon.png"))
                .resizable()
                .onFailureImage(UIImage(named: "DisplayAppIcon"))
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
        
    }
}

struct TweakRow: View {
    @EnvironmentObject var appData: AppData
    @State var tweak: Package
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                KFImage(tweak.icon)
                    .resizable()
                    .onFailureImage(UIImage(named: "DisplayAppIcon"))
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                if appData.installed_pkgs.contains(where: { $0.id == tweak.id }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .offset(x: 5, y: 5)
                }
            }
            
            VStack(alignment: .leading) {
                Text(tweak.name)
                    .font(.headline)
                    .foregroundColor(Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                Text("\(tweak.author) · \(tweak.version) · \(tweak.id)")
                    .font(.subheadline)
                    .foregroundColor(Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
                Text(tweak.desc)
                    .font(.footnote)
                    .foregroundColor(Color.accentColor.opacity(0.5))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
            }
        }.padding(.vertical, 5)
    }
}
