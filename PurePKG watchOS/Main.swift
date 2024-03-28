//
//  Main.swift
//  PurePKGwatchOS
//
//  Created by Lrdsnow on 3/28/24.
//

import SwiftUI

@main
struct PureKFDBinary {
    static func main() {
        if (getuid() != 0) {
            PurePKGwatchOSApp.main();
        } else {
             exit(RootHelperMain());
        }
        
    }
}

struct PurePKGwatchOSApp: App {
    @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appData)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @State private var refreshed = false
    
    var body: some View {
        NavigationView {
            List {
                if !appData.queued.all.isEmpty {
                    NavigationLink(destination: QueuedView()) {
                        HStack {
                            Image("queue_icon")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                            Text("Queued")
                            Spacer()
                        }
                    }.listRowBG()
                }
                NavigationLink(destination: BrowseView()) {
                    HStack {
                        Image("browse_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text("Browse")
                        Spacer()
                    }
                }.listRowBG()
                NavigationLink(destination: InstalledView()) {
                    HStack {
                        Image("installed_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text("Installed")
                        Spacer()
                    }
                }.listRowBG()
                NavigationLink(destination: SearchView()) {
                    HStack {
                        Image("search_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text("Search")
                        Spacer()
                    }
                }.listRowBG()
                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image("gear_icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text("Settings")
                        Spacer()
                    }
                }.listRowBG()
            }.navigationTitle("PurePKG").navigationBarTitleDisplayMode(.large).onAppear() {
                if !refreshed {
                    appData.jbdata.jbtype = Jailbreak.type(appData)
                    appData.deviceInfo = getDeviceInfo()
                    appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status")
                    appData.repos = RepoHandler.getCachedRepos()
                    appData.pkgs = appData.repos.flatMap { $0.tweaks }
                    refreshed = true
                    Task(priority: .background) {
                        refreshRepos(true, appData)
                    }
                }
            }
        }
    }
}

