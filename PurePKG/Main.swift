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
    var FeaturedIcon = Image("home_icon")
    var BrowseIcon = Image("browse_icon")
    var InstalledIcon = Image("installed_icon")
    var SearchIcon = Image("search_icon")
}

struct MainView: View {
    @EnvironmentObject var appData: AppData
    // i plan on allowing custom icons via files at some point but this will do for now
    @State private var icons = tabBarIcons()
    @State private var selectedTab = 0
    let tabItems = ["Featured", "Browse", "Installed", "Search"]
    let tabItemImages = ["Featured":Image("home_icon"), "Browse":Image("browse_icon"), "Installed":Image("installed_icon"), "Search":Image("search_icon")]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeaturedView().tag(0)
                BrowseView().tag(1)
                InstalledView().tag(2)
                SearchView().tag(3)
            }.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).ignoresSafeArea(.all, edges: .top)
            HStack {
                ForEach(0..<4) { index in
                    Spacer()
                    Button(action: { self.selectedTab = index }) {
                        HStack {
                            tabItemImages[tabItems[index]]?
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                            if self.selectedTab == index {
                                Text("\(tabItems[index])")
                            }
                        }
                    }
                    .foregroundColor(self.selectedTab == index ? .accentColor : .primary)
                    .animation(.spring(), value: selectedTab)
                    .padding(.bottom, 30)
                    Spacer()
                }
            }.frame(width: UIScreen.main.bounds.width).padding(.horizontal)
        }.ignoresSafeArea(.all, edges: .top)
        .padding()
        .background(Color.white)
        .onAppear() {
            appData.jbdata.jbtype = Jailbreak.type()
            appData.deviceInfo = getDeviceInfo()
            appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path()+"/Library/dpkg/status")
        }
    }
}
