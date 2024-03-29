//
//  BrowseView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
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
    @State private var newRepoURL = ""
    @State private var addingRepo = false
    
    var body: some View {
        CustomNavigationView {
            if !appData.repos.isEmpty {
                List {
                    PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs), alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0).listRowBackground(Color.clear).noListRowSeparator().padding(.vertical, 5).padding(.bottom, -30).noListRowSeparator()
                    Section("Repositories") {
                        ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.name) { repo in
                            RepoRowNavLinkWrapper(repo: repo).noListRowSeparator()
                        }
                    }.listRowBackground(Color.clear).noListRowSeparator().springAnim()
                }.clearListBG().BGImage(appData).navigationTitle("Browse").animation(.spring(), value: appData.repos.count).listStyle(.plain)
                .refreshable {
                    appData.repos = []
                }
                .alert("Add Repo", isPresented: $addingRepo, actions: {
                    TextField("URL", text: $newRepoURL)
                    Button("Save", action: {
                        Task {
                            await addRepo()
                        }
                    })
                    Button("Cancel", role: .cancel, action: {})
                })
                .largeNavBarTitle()
                .navigationBarItems(trailing:
                        HStack {
                        Button(action: {
                            appData.repos = []
                        }) {
                            Image("refresh_icon")
                                .renderingMode(.template)
                        }
                        Button(action: {
                            addingRepo.toggle()
                        }) {
                            Image("plus_icon")
                                .renderingMode(.template)
                        }
                    }
                    )
            } else {
                VStack {
                    ZStack {
                        ProgressView()
                        Text("\n\n\nGetting Repos...").foregroundColorCustom(Color.accentColor)
                    }.task() {
                        refreshRepos(false, appData)
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
            .padding(.bottom, -30)
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
            PlaceHolderRow(alltweaks: alltweaks, category: category, categoryTweaks: categoryTweaks, focused: .constant(false))
        }
    }
}

struct PlaceHolderRow: View {
    let alltweaks: Int
    let category: String
    let categoryTweaks: Int
    @Binding var focused: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Spacer()
                Image("DisplayAppIcon")
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .frame(width: 70, height: 70)
                    .cornerRadius(100)
                Spacer()
            }
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
            RepoRow(repo: repo, focused: .constant(false))
        }
        .noListRowSeparator()
    }
}

struct RepoRow: View {
    @EnvironmentObject var appData: AppData
    @State var repo: Repo
    @Binding var focused: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Spacer()
                KFImage(repo.url.appendingPathComponent("CydiaIcon.png"))
                    .resizable()
                    .onFailureImage(UIImage(named: "DisplayAppIcon"))
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .frame(width: 70, height: 70)
                    .cornerRadius(100)
                Spacer()
            }
            
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
                if let error = repo.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                }
            }
        }.padding(.vertical, 5).contextMenu(menuItems: {
            Button(action: {
                let pasteboard = UIPasteboard.general
                pasteboard.string = repo.url.absoluteString
            }) {
                Text("Copy Repo URL")
                Image("copy_icon").renderingMode(.template)
            }
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
            TweakRow(tweak: tweak, focused: .constant(false))
        }
        .noListRowSeparator()
    }
}

struct TweakRow: View {
    @EnvironmentObject var appData: AppData
    @State var tweak: Package
    @Binding var focused: Bool
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .center) {
                    Spacer()
                    KFImage(tweak.icon)
                        .resizable()
                        .onFailureImage(UIImage(named: "DisplayAppIcon"))
                        .scaledToFit()
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .frame(width: 70, height: 70)
                        .cornerRadius(100)
                    Spacer()
                }
                if appData.installed_pkgs.contains(where: { $0.id == tweak.id }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .offset(x: 5, y: -15)
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
