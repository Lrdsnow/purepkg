//
//  ContentView.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import SwiftUI

// App

@main
struct PurePKGBinary {
    static func main() {
        if (getuid() != 0) {
            PurePKGApp.main();
        } else {
             exit(RootHelperMain());
        }
        
    }
}

struct PurePKGApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        #if !os(tvOS) && !os(macOS)
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(Color.accentColor)]
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = .clear
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

// Main

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        TabView {
            BrowseView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Browse")
                }
            HomeView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Installed")
                }
            HomeView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            if !appData.queued.all.isEmpty {
                HomeView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Queued")
                    }
            }
        }.onAppear() {
            appData.jbdata.jbtype = Jailbreak.type(appData)
            appData.jbdata.jbarch = Jailbreak.arch(appData)
            appData.jbdata.jbroot = Jailbreak.path(appData)
            appData.deviceInfo = getDeviceInfo()
            appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg")
            appData.repos = RepoHandler.getCachedRepos()
            appData.pkgs = appData.repos.flatMap { $0.tweaks }
            if !UserDefaults.standard.bool(forKey: "ignoreInitRefresh") {
                Task(priority: .background) {
                    refreshRepos(appData)
                }
            }
        }
    }
}
