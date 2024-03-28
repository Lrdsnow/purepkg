//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct CustomNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
#if os(macOS)
        NavigationStack {
            content
        }
#else
        NavigationView {
            content
        }.navigationViewStyle(.stack)
#endif
    }
}

struct BrowseView: View {
    @EnvironmentObject var appData: AppData
    @State private var isAddingRepoURLAlertPresented = false
    @State private var isAddingRepoURLAlert16Presented = false
    @State private var newRepoURL = ""
    
    var body: some View {
        CustomNavigationView {
            if !appData.repos.isEmpty {
                List {
                    PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs), alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0).listRowBackground(Color.clear).noListRowSeparator().padding(.vertical, 5).padding(.bottom, 10).noListRowSeparator()
                    Section("Repositories") {
                        ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.name) { repo in
                            RepoRowNavLinkWrapper(repo: repo).noListRowSeparator()
                        }
                    }.listRowBackground(Color.clear).noListRowSeparator().springAnim()
                    Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
                }.clearListBG().BGImage(appData).navigationTitle("Browse").animation(.spring(), value: appData.repos.count).listStyle(.plain)
                .refreshable {
                    appData.repos = []
                }.addRepoAlert(browseview: self, adding16: $isAddingRepoURLAlert16Presented, adding: $isAddingRepoURLAlertPresented, newRepoURL: $newRepoURL)
                .onChange(of: isAddingRepoURLAlertPresented) { newValue in
                    if !newValue {
                        Task {
                            await addRepo()
                        }
                    }
                }
                .largeNavBarTitle()
                #if os(macOS)
                .toolbar {
                    ToolbarItem {
                        Spacer()
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        HStack {
                            Button(action: {
                                appData.repos = []
                            }) {
                                Image("refresh_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                let clipboardString = pasteboard.string(forType: .string) ?? ""
                                if let repourl = URL(string: clipboardString) {
                                    newRepoURL = repourl.absoluteString
                                    Task {
                                        await addRepo()
                                    }
                                } else {
                                    if #available(iOS 16, *) {
                                        isAddingRepoURLAlert16Presented = true
                                    } else {
                                        isAddingRepoURLAlertPresented = true
                                    }
                                }
                            }) {
                                Image("plus_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
                #else
                .navigationBarItems(trailing:
                        HStack {
                        #if os(macOS) || os(tvOS)
                        Button(action: {
                            appData.repos = []
                        }) {
                            #if os(tvOS)
                            Image("refresh_icon")
                            #else
                            Image("refresh_icon")
                                .renderingMode(.template)
                            #endif
                        }
                        #endif
                        Button(action: {
                            #if os(tvOS)
                            if #available(tvOS 16, *) {
                                isAddingRepoURLAlert16Presented = true
                            } else {
                                isAddingRepoURLAlertPresented = true
                            }
                            #else
                            #if os(macOS)
                            let pasteboard = NSPasteboard.general
                            let clipboardString = pasteboard.string(forType: .string) ?? ""
                            #else
                            let clipboardString = UIPasteboard.general.string ?? ""
                            #endif
                            if let repourl = URL(string: clipboardString) {
                                newRepoURL = repourl.absoluteString
                                Task {
                                    await addRepo()
                                }
                            } else {
                                if #available(iOS 16, *) {
                                    isAddingRepoURLAlert16Presented = true
                                } else {
                                    isAddingRepoURLAlertPresented = true
                                }
                            }
                            #endif
                        }) {
                            #if os(tvOS)
                            Image("plus_icon")
                            #else
                            Image("plus_icon")
                                .renderingMode(.template)
                                .shadow(color: .accentColor, radius: 5)
                            #endif
                        }
                    }
                    )
                #endif
            } else {
                VStack {
                    ZStack {
                        ProgressView()
                        Text("\n\n\nGetting Repos...").foregroundColorCustom(Color.accentColor)
                    }.task() {
                        let repoCacheDir = URL.documents.appendingPathComponent("repoCache")
                        if FileManager.default.fileExists(atPath: repoCacheDir.path) {
                            try? FileManager.default.removeItem(at: repoCacheDir)
                        }
                        try? FileManager.default.createDirectory(at: repoCacheDir, withIntermediateDirectories: true, attributes: nil)
                        DispatchQueue.main.async {
                            if appData.jbdata.jbtype != .jailed {
                                let repoData = RepoHandler.getAptSources(Jailbreak.path(appData)+"/etc/apt/sources.list.d")
                                appData.repo_urls = repoData.0
                                appData.dist_repo_components = repoData.1
                            } else {
                                appData.repo_urls = [URL(string: "https://repo.chariz.com")!, URL(string: "https://luki120.github.io")!, URL(string: "https://sparkdev.me")!, URL(string: "https://havoc.app")!]
                            }
                            let repo_urls = appData.repo_urls
                            let dist_repo_components = appData.dist_repo_components
                            DispatchQueue.global(qos: .background).async {
                                RepoHandler.getRepos(repo_urls, dist_repo_components) { Repo in
                                    DispatchQueue.main.async {
                                        if !appData.repos.contains(where: { $0.url == Repo.url }) {
                                            appData.repos.append(Repo)
                                            appData.pkgs  = appData.repos.flatMap { $0.tweaks }
                                            let jsonEncoder = JSONEncoder()
                                            do {
                                                let jsonData = try jsonEncoder.encode(Repo)
                                                do {
                                                    var cleanname = Repo.name.filter { $0.isLetter || $0.isNumber }.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    if cleanname == "" {
                                                        cleanname = "\(UUID())"
                                                    }
                                                    try jsonData.write(to: repoCacheDir.appendingPathComponent("\(cleanname).json"))
                                                } catch {
                                                    log("Error saving repo data: \(error)")
                                                }
                                            } catch {
                                                log("Error encoding repo: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.BGImage(appData).navigationTitle("Browse")
                .largeNavBarTitle()
            }
        }
    }
    
    func addRepo() async {
        guard let url = URL(string: newRepoURL) else {
            UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
            return
        }
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await session.data(from: request.url!)
            let statuscode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if statuscode == 200 {
                RepoHandler.addRepo(newRepoURL)
                appData.repos = []
            } else {
                UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
            }
        } catch {
            UIApplication.shared.alert(title: "Error", body: "Invalid Repo?", withButton: true)
        }
    }
}

struct RepoView: View {
    @State var repo: Repo
    @EnvironmentObject var appData: AppData

    var body: some View {
        List {
            PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: repo.name, tweaksLabel: "All Tweaks", tweaks: repo.tweaks),
                                         alltweaks: repo.tweaks.count,
                                         category: "",
                                         categoryTweaks: 0)
            .listRowBackground(Color.clear)
            .noListRowSeparator()
            .padding(.vertical, 5)
            .padding(.bottom, 10)
            .noListRowSeparator()
            Section("Categories") {
                ForEach(Array(Set(repo.tweaks.map { $0.section })), id: \.self) { category in
                    let categoryTweaks = repo.tweaks.filter { $0.section == category }
                    PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: repo.name, tweaksLabel: category, tweaks: categoryTweaks), alltweaks: -1, category: category, categoryTweaks: categoryTweaks.count).noListRowSeparator()
                }
            }.listRowBackground(Color.clear).noListRowSeparator()
            Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
        }
        .clearListBG()
        .BGImage(appData)
        .navigationTitle(repo.name)
        .listStyle(.plain)
        .largeNavBarTitle()
    }
}

struct TweaksListView: View {
    let pageLabel: String
    let tweaksLabel: String
    let tweaks: [Package]
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        List {
            Section(tweaksLabel) {
                if !tweaks.isEmpty {
                    ForEach(tweaks, id: \.name) { tweak in
                        TweakRowNavLinkWrapper(tweak: tweak)
                    }
                } else {
                    Button(action: {}, label: {
                        HStack {
                            Spacer()
                            Text("No Tweaks Found")
                            Spacer()
                        }
                    })
                }
            }.listRowBackground(Color.clear).noListRowSeparator()
            Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
        }.clearListBG()
            .BGImage(appData)
            .navigationTitle(pageLabel)
            .listStyle(.plain)
            .largeNavBarTitle()
    }
}

struct PlaceHolderRowNavLinkWrapper<Destination: View>: View {
    let destination: Destination
    let alltweaks: Int
    let category: String
    let categoryTweaks: Int
    @FocusState private var isFocused: Bool
    @State private var focused: Bool = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            #if os(tvOS)
            PlaceHolderRow(alltweaks: alltweaks, category: category, categoryTweaks: categoryTweaks, focused: $focused)
            #else
            PlaceHolderRow(alltweaks: alltweaks, category: category, categoryTweaks: categoryTweaks, focused: .constant(false))
            #endif
        }
        #if os(tvOS)
        .focusable(true) { isFocused in
            self.isFocused = isFocused
            self.focused = isFocused
        }
        #endif
    }
}

struct PlaceHolderRow: View {
    let alltweaks: Int
    let category: String
    let categoryTweaks: Int
    @Binding var focused: Bool

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
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    Text("\(alltweaks) Tweaks Total")
                        .font(.subheadline)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                } else {
                    Text(category)
                        .font(.headline)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    Text("\(categoryTweaks) Tweaks")
                        .font(.subheadline)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                }
            }
        }
    }
}

struct RepoRowNavLinkWrapper: View {
    let repo: Repo
    @FocusState private var isFocused: Bool
    @State private var focused: Bool = false
    
    var body: some View {
        NavigationLink(destination: RepoView(repo: repo)) {
            #if os(tvOS)
            RepoRow(repo: repo, focused: $focused)
            #else
            RepoRow(repo: repo, focused: .constant(false))
            #endif
        }
        .noListRowSeparator()
        #if os(tvOS)
        .focusable(true) { isFocused in
            self.isFocused = isFocused
            self.focused = isFocused
        }
        #endif
    }
}

struct RepoRow: View {
    @EnvironmentObject var appData: AppData
    @State var repo: Repo
    @Binding var focused: Bool
    
    var body: some View {
        HStack {
            KFImage(repo.url.appendingPathComponent("CydiaIcon.png"))
                .resizable()
                .onFailureImage(UIImage(named: "DisplayAppIcon"))
               .scaledToFit()
               .frame(width: 50, height: 50)
               .cornerRadius(11)
               .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
                Text(repo.url.absoluteString.replacingOccurrences(of: "/./", with: "").removeSubstringIfExists("/dists/"))
                    .font(.subheadline)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
            }
        }.padding(.vertical, 5).contextMenu(menuItems: {
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
            Button(role: .destructive, action: {
                RepoHandler.removeRepo(repo.url)
                appData.repos = []
            }) {
                Text("Delete Repo")
                Image("trash_icon").renderingMode(.template)
            }.foregroundColor(.red)
            
        })
    }
}

struct TweakRowNavLinkWrapper: View {
    let tweak: Package
    @FocusState private var isFocused: Bool
    @State private var focused: Bool = false
    
    var body: some View {
        NavigationLink(destination: TweakView(pkg: tweak)) {
            #if os(tvOS)
            TweakRow(tweak: tweak, focused: $focused)
            #else
            TweakRow(tweak: tweak, focused: .constant(false))
            #endif
        }
        .noListRowSeparator()
        #if os(tvOS)
        .focusable(true) { isFocused in
            self.isFocused = isFocused
            self.focused = isFocused
        }
        #endif
    }
}

struct TweakRow: View {
    @EnvironmentObject var appData: AppData
    @State var tweak: Package
    @Binding var focused: Bool
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                KFImage(tweak.icon)
                    .resizable()
                    .onFailureImage(UIImage(named: "DisplayAppIcon"))
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(11)
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
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                Text("\(tweak.author) · \(tweak.version) · \(tweak.id)")
                    .font(.subheadline)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
                Text(tweak.desc)
                    .font(.footnote)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.5) : Color.accentColor.opacity(0.5))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
            }
        }.padding(.vertical, 5)
    }
}
