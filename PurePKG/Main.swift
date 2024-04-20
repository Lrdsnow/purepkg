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
    @State private var tab = 0
    @State private var importedPackage: Package? = nil
    @State private var showPackage = false
    
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
            ContentView(tab: $tab, importedPackage: $importedPackage, showPackage: $showPackage, preview: false)
                .environmentObject(appData)
        }
    }
}

// Main

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @Binding var tab: Int
    @Binding var importedPackage: Package?
    @Binding var showPackage: Bool
    let preview: Bool
    
    var body: some View {
        TabView(selection: $tab) {
            BrowseView(importedPackage: $importedPackage, showPackage: $showPackage, preview: preview)
                .tabItem {
                    Image(systemName: "globe")
                    Text("Browse")
                }
                .tag(0)
            InstalledView(preview: preview)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Installed")
                }
                .tag(1)
            SearchView(preview: preview)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
            if !appData.queued.all.isEmpty {
                QueueView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Queued")
                    }
                    .tag(3)
            }
        }.onAppear() {
            if !preview {
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
}
