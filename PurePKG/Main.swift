//
//  ContentView.swift
//  purepkg
//
//  Created by Lrdsnow on 1/9/24.
//

import SwiftUI
import Combine

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
        UITabBar.appearance().isHidden = true
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
    @State private var queueOpen = false
    @State private var queueListopacity: Double = 1.0
    let tabItems = ["Featured", "Browse", "Installed", "Search"]
    let tabItemImages = ["Featured":Image("home_icon"), "Browse":Image("browse_icon"), "Installed":Image("installed_icon"), "Search":Image("search_icon")]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeaturedView().tag(0)
                BrowseView().tag(1)
                InstalledView().tag(2)
                SearchView().tag(3)
            }.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).ignoresSafeArea(.all)
            VStack {
                
                if !appData.queued.isEmpty {
                    VStack {
                        Button(action: {
                            queueOpen.toggle()
                        }) {
                            HStack {
                                Image("queue_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                Text("\(appData.queued.count) Queued Tweak\(appData.queued.count >= 2 ? "s" : "")").padding(.horizontal, 5).animation(.spring(), value: appData.queued.count)
                                Spacer()
                            }.padding(.horizontal, 20).padding(.vertical, 10).background(Color.black.opacity(0.001))
                        }.buttonStyle(.plain).padding(.top, queueOpen ? UIApplication.shared.windows[0].safeAreaInsets.bottom > 0  ? 50 : 25 : 0)
                        VStack(alignment: .leading) {
                            ForEach(appData.queued, id: \.id) { package in
                                HStack {
                                    TweakRow(tweak: package)
                                    Spacer()
                                    Button(action: {
                                        if appData.queued.count == 1 {
                                            queueOpen = false
                                        }
                                        appData.queued.remove(at: appData.queued.firstIndex(where: { $0.id == package.id }) ?? -2)
                                    }, label: {
                                        ZStack(alignment: .center) {
                                            RoundedRectangle(cornerRadius: 8).frame(width: 50, height: 50).foregroundColor(.red).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                                            Image("trash_icon").renderingMode(.template).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2).foregroundColor(.black)
                                        }
                                    })
                                }
                                    .opacity(queueOpen ? 1.0 : 0.0)
                                    .frame(height: queueOpen ? 56.0 : 0.0)
                                    .padding(.horizontal)
                            }
                            if queueOpen {
                                Spacer()
                            }
                            HStack {
                                if !queueOpen {
                                    Spacer()
                                }
                                Button(action: {}, label: {
                                    if queueOpen {
                                        Spacer()
                                    }
                                    Text("Install Tweaks").padding()
                                    if queueOpen {
                                        Spacer()
                                    }
                                }).buttonStyle(.borderedProminent).tint(Color.accentColor.opacity(0.7))
                                if !queueOpen {
                                    Spacer()
                                }
                            }.padding().opacity(queueOpen ? 1.0 : 0.0).frame(height: queueOpen ? 56.0 : 0.0).padding(.bottom, 30)
                        }.frame(height: queueOpen ? .infinity : 0)
                    }
                }
                
                if queueOpen && !appData.queued.isEmpty {
                    Spacer()
                }
                
                HStack {
                    ForEach(0..<4) { index in
                        Spacer()
                        Button(action: { self.selectedTab = index }) {
                            HStack {
                                tabItemImages[tabItems[index]]?
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                if self.selectedTab == index {
                                    Text("\(tabItems[index])")
                                }
                            }
                        }
                        .foregroundColor(self.selectedTab == index ? .accentColor : .primary)
                        .animation(.spring(), value: selectedTab)
                        .padding(.bottom, UIApplication.shared.windows[0].safeAreaInsets.bottom > 0 ? 30 : 16)
                        Spacer()
                    }
                }.padding(.top, appData.queued.isEmpty ? 16 : 0)
            }.frame(width: UIScreen.main.bounds.width).padding(.horizontal).background(VisualEffectView(effect: UIBlurEffect(style: .dark)).edgesIgnoringSafeArea(.all))
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: appData.queued.isEmpty).animation(.spring(), value: queueOpen).noTabBarBG()
        }.ignoresSafeArea(.all, edges: .top)
            .padding()
            .background(Color.black)
            .onAppear() {
                appData.jbdata.jbtype = Jailbreak.type()
                appData.deviceInfo = getDeviceInfo()
                appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path()+"/Library/dpkg/status")
                appData.repos = RepoHandler.getCachedRepos()
                appData.pkgs  = appData.repos.flatMap { $0.tweaks }
            }
    }
}
