//
//  ContentView.swift
//  purepkg
//
//  Created by Lrdsnow on 1/9/24.
//

import SwiftUI

@main
struct purepkgApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        if #unavailable(iOS 16) {
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
            UITableView.appearance().backgroundColor = .clear
            UITabBar.appearance().unselectedItemTintColor = UIColor(Color.accentColor.opacity(0.4))
            UITabBar.appearance().tintColor = UIColor(Color.accentColor)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appData)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var appData: AppData
    // i plan on allowing custom icons via files at some point but this will do for now
    @State private var featuredIcon = Image("home_icon")
    @State private var browseIcon = Image("browse_icon")
    @State private var installedIcon = Image("installed_icon")
    @State private var searchIcon = Image("search_icon")
    
    var body: some View {
        TabView {
            FeaturedView()
                .tabItem {
                    featuredIcon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Featured")
                }
            BrowseView()
                .tabItem {
                    browseIcon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Browse")
                }
            InstalledView()
                .tabItem {
                    installedIcon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Installed")
                }
            SearchView()
                .tabItem {
                    searchIcon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                    Text("Search")
                }
        }.task {
            appData.jbdata.jbtype = Jailbreak.type()
            appData.deviceInfo = getDeviceInfo()
            RepoHandler.getRepos(appData.repo_urls) { Repo in
                appData.repos.append(Repo)
                appData.pkgs  = appData.repos.flatMap { $0.tweaks }
            }
        }
    }
}
