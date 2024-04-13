//
//  BrowseView.swift
//  PurePKGwatchOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct BrowseView: View {
    @EnvironmentObject var appData: AppData
    @State private var isAddingRepoURLAlertPresented = false
    @State private var isAddingRepoURLAlert16Presented = false
    @State private var newRepoURL = ""
    
    var body: some View {
        NavigationView {
            if !appData.repos.isEmpty {
                List {
                    PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs), alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0).listRowBackground(Color.clear).noListRowSeparator().padding(.vertical, 5).padding(.bottom, -15).noListRowSeparator()
                    Section("Repositories") {
                        ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.name) { repo in
                            RepoRowNavLinkWrapper(repo: repo).noListRowSeparator()
                        }
                    }.listRowBackground(Color.clear).noListRowSeparator().springAnim()
                }.clearListBG().navigationTitle("Browse").animation(.spring(), value: appData.repos.count).listStyle(.plain)
                .refreshable_compat {
                    appData.repos = []
                }
                .onChange(of: isAddingRepoURLAlertPresented) { newValue in
                    if !newValue {
                        Task {
                            await addRepo()
                        }
                    }
                }
                .largeNavBarTitle()
            } else {
                VStack {
                    ZStack {
                        ProgressView()
                        Text("\n\n\nGetting Repos...").foregroundColorCustom(Color.accentColor)
                    }.task() {
                        refreshRepos(false, appData)
                    }
                }.navigationTitle("Browse").largeNavBarTitle()
            }
        }
    }
    
    func addRepo() async {
        guard let url = URL(string: newRepoURL) else {
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
            }
        } catch {}
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
            .padding(.bottom, -15)
            .noListRowSeparator()
            Section("Categories") {
                ForEach(Array(Set(repo.tweaks.map { $0.section })), id: \.self) { category in
                    let categoryTweaks = repo.tweaks.filter { $0.section == category }
                    PlaceHolderRowNavLinkWrapper(destination: TweaksListView(pageLabel: repo.name, tweaksLabel: category, tweaks: categoryTweaks), alltweaks: -1, category: category, categoryTweaks: categoryTweaks.count).noListRowSeparator()
                }
            }.listRowBackground(Color.clear).noListRowSeparator()
            paddingBlock()
        }
        .clearListBG()
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
            paddingBlock()
        }.clearListBG()
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
                    .frame(width: 35, height: 35)
                    .cornerRadius(40)
                Spacer()
            }
            VStack(alignment: .leading) {
                if alltweaks != -1 {
                    Text("All Tweaks")
                        .font(.headline)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                    Text("\(alltweaks) Tweaks Total")
                        .font(.footnote)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                } else {
                    Text(category)
                        .font(.headline)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                    Text("\(categoryTweaks) Tweaks")
                        .font(.footnote)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
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
                    .onFailureImage(UIImage(named: "DisplayAppIcon")!.downscaled(to: CGSize(width: 35, height: 35)))
                    .cacheOriginalImage()
                    .downsampling(size: CGSize(width: 35, height: 35))
                    .scaledToFit()
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .frame(width: 35, height: 35)
                    .cornerRadius(40)
                Spacer()
            }
            
            VStack(alignment: .leading) {
                Text(repo.name)
                    .font(.headline)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
                if let error = repo.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                } else {
                    Text(repo.url.absoluteString.replacingOccurrences(of: "/./", with: "").removeSubstringIfExists("/dists/"))
                        .font(.footnote)
                        .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .lineLimit(1)
                }
            }
        }.padding(.vertical, 5).contextMenu(menuItems: {
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
                VStack(alignment: .center) {
                    Spacer()
                    KFImage(tweak.icon)
                        .resizable()
                        .onFailureImage(UIImage(named: "DisplayAppIcon")!.downscaled(to: CGSize(width: 35, height: 35)))
                        .cacheOriginalImage()
                        .downsampling(size: CGSize(width: 35, height: 35))
                        .scaledToFit()
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .frame(width: 35, height: 35)
                        .cornerRadius(40)
                    Spacer()
                }
                if appData.installed_pkgs.contains(where: { $0.id == tweak.id }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.accentColor)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        .offset(x: 5, y: 0)
                }
            }
            
            VStack(alignment: .leading) {
                Text(tweak.name)
                    .font(.subheadline)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8) : Color.accentColor)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                Text("\(tweak.author) · \(tweak.version)")
                    .font(.footnote)
                    .foregroundColorCustom(focused ? Color.accentColor.darker(0.8).opacity(0.7) : Color.accentColor.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                    .lineLimit(1)
            }
        }.padding(.vertical, 5)
    }
}
