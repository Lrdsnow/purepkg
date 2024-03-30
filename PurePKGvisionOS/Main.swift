//
//  ContentView.swift
//  PurePKG visionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import SwiftUI
import RealityKit

struct tabBarIcons {
    var FeaturedIcon = Image("home_icon")
    var BrowseIcon = Image("browse_icon")
    var InstalledIcon = Image("installed_icon")
    var SearchIcon = Image("search_icon")
}

struct MainView: View {
    @EnvironmentObject var appData: AppData
    @State private var icons = tabBarIcons()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeaturedView().tag(0).tabItem {
                HStack {
                    Image("home_icon")
                    Text("Featured")
                }
            }
            BrowseView().tag(1).tabItem {
                HStack {
                    Image("browse_icon")
                    Text("Browse")
                }
            }
            InstalledView().tag(2).tabItem {
                HStack {
                    Image("installed_icon")
                    Text("Installed")
                }
            }
            SearchView().tag(3).tabItem {
                HStack {
                    Image("search_icon")
                    Text("Search")
                }
            }
            if !appData.queued.all.isEmpty {
                QueuedView().tag(4).tabItem {
                    HStack {
                        Image("queue_icon")
                        Text("Queued")
                    }
                }
            }
        }.onAppear() {
            appData.jbdata.jbtype = Jailbreak.type(appData)
            appData.deviceInfo = getDeviceInfo()
            appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status")
            appData.repos = RepoHandler.getCachedRepos()
            appData.pkgs = appData.repos.flatMap { $0.tweaks }
            if appData.repos.isEmpty {
                selectedTab = 1
            }
        }
    }
}
