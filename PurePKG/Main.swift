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
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UITableView.appearance().backgroundColor = .clear
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.accentColor.opacity(0.4))
        UITabBar.appearance().tintColor = UIColor(Color.accentColor)
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = .clear
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appData)
        }
    }
}

struct tabBarIcons {
    var featuredIcon = Image("home_icon")
    var browseIcon = Image("browse_icon")
    var installedIcon = Image("installed_icon")
    var searchIcon = Image("search_icon")
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
        }.onAppear() {
            appData.jbdata.jbtype = Jailbreak.type()
            appData.deviceInfo = getDeviceInfo()
            appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path()+"/Library/dpkg/status")
        }
    }
}
