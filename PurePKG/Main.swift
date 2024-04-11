//
//  ContentView.swift
//  purepkg
//
//  Created by Lrdsnow on 1/9/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Combine
import UniformTypeIdentifiers


@main
struct PureKFDBinary {
    static func main() {
        if (getuid() != 0) {
            purepkgApp.main();
        } else {
             exit(RootHelperMain());
        }
        
    }
}

struct purepkgApp: App {
    @StateObject private var appData = AppData()
    
    init() {
        #if os(macOS)
        #elseif !os(tvOS)
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
            MainView()
                .environmentObject(appData)
                .accentColor(Color(UIColor(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "") ?? UIColor(hex: "#EBC2FF")!))
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }

}

extension UTType {
    static var deb: UTType {
        UTType(exportedAs: "org.debian.deb-archive")
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
    #if os(tvOS) || os(macOS)
    @State private var basicMode = true
    #else
    @State private var basicMode = false
    #endif
    @State private var complexMode = false
    @State private var selectedTab = 0
    @State private var tweakViewPKG: Package? = nil
    @State private var showPopupTab = false
    
    var body: some View {
        if basicMode {
            TabView(selection: $selectedTab) {
                FeaturedView(tweakViewPKG: $tweakViewPKG, showTab: $showPopupTab).tag(0).tabItem {
                    HStack {
                        Image("home_icon")
                        #if os(iOS)
                            .renderingMode(.template)
                        #endif
                        Text("Featured")
                    }
                }
                BrowseView().tag(1).tabItem {
                    HStack {
                        Image("browse_icon")
                        #if os(iOS)
                            .renderingMode(.template)
                        #endif
                        Text("Browse")
                    }
                }
                InstalledView().tag(2).tabItem {
                    HStack {
                        Image("installed_icon")
                        #if os(iOS)
                            .renderingMode(.template)
                        #endif
                        Text("Installed")
                    }
                }
                SearchView().tag(3).tabItem {
                    HStack {
                        Image("search_icon")
                        #if os(iOS)
                            .renderingMode(.template)
                        #endif
                        Text("Search")
                    }
                }
                if !appData.queued.all.isEmpty {
                    QueuedView().tag(4).tabItem {
                        HStack {
                            Image("queue_icon")
                            #if os(iOS)
                                .renderingMode(.template)
                            #endif
                            Text("Queued")
                        }
                    }
                }
                #if os(macOS)
                if let tweakViewPKG = tweakViewPKG {
                    TweakView(pkg: tweakViewPKG).tag(5).tabItem { Text("Local deb") }
                }
                #endif
            }.onOpenURL { url in
                handleIncomingURL(url)
            }.onAppear() {
                appData.basicMode = basicMode
                appData.jbdata.jbtype = Jailbreak.type(appData)
                appData.jbdata.jbarch = Jailbreak.arch(appData)
                appData.jbdata.jbroot = Jailbreak.path(appData)
                appData.deviceInfo = getDeviceInfo()
                appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status")
                appData.repos = RepoHandler.getCachedRepos()
                appData.pkgs = appData.repos.flatMap { $0.tweaks }
                if !UserDefaults.standard.bool(forKey: "ignoreInitRefresh") {
                    Task(priority: .background) {
                        refreshRepos(true, appData)
                    }
                }
            }
        }
        if complexMode {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    FeaturedView(tweakViewPKG: $tweakViewPKG, showTab: $showPopupTab).tag(0)
                    BrowseView().tag(1)
                    InstalledView().tag(2)
                    SearchView().tag(3)
                }.onOpenURL { url in
                    handleIncomingURL(url)
                }
#if os(iOS)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: UIScreen.main.bounds.width)
#endif
#if os(iOS)
                tabbar(selectedTab: $selectedTab)
                    .onAppear() {
                        appData.basicMode = basicMode
                        appData.jbdata.jbtype = Jailbreak.type(appData)
                        appData.jbdata.jbarch = Jailbreak.arch(appData)
                        appData.jbdata.jbroot = Jailbreak.path(appData)
                        appData.deviceInfo = getDeviceInfo()
                        appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status")
                        appData.repos = RepoHandler.getCachedRepos()
                        appData.pkgs = appData.repos.flatMap { $0.tweaks }
                        if !UserDefaults.standard.bool(forKey: "ignoreInitRefresh") {
                            Task(priority: .background) {
                                refreshRepos(true, appData)
                            }
                        }
                    }
#endif
            }.background(Color.black).edgesIgnoringSafeArea(.bottom)
        }
        if !complexMode && !basicMode {
            VStack {
                Text("PurePKG").onAppear() {
                    var tempBasicMode = true
                    tempBasicMode = UserDefaults.standard.bool(forKey: "simpleMode")
                    #if os(iOS)
                    if !tempBasicMode {
                        UITabBar.appearance().isHidden = true
                        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.accentColor.opacity(0.4))
                        UITabBar.appearance().tintColor = UIColor(Color.accentColor)
                    }
                    #endif
                    basicMode = tempBasicMode
                    complexMode = !tempBasicMode
                }
            }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("App was opened via URL: \(url)")
        if url.absoluteString.contains("purepkg://addrepo/") {
            let repourl = url.absoluteString.replacingOccurrences(of: "purepkg://addrepo/", with: "")
            print("Adding Repo: \(repourl)")
            RepoHandler.addRepo(repourl)
        } else if url.pathExtension == "deb" {
            let info = APTWrapper.spawn(command: "\(Jailbreak.path())/\(Jailbreak.type() == .macos ? "" : "usr/")bin/dpkg-deb", args: ["dpkg-deb", "--field", url.path])
            if info.0 == 0 {
                let dict = RepoHandler.genDict(info.1)
                var tweak = RepoHandler.createPackageStruct(dict)
                tweak.debPath = url.path
                tweakViewPKG = tweak
                showPopupTab = true
                #if os(macOS)
                selectedTab = 5
                #endif
            } else {
                UIApplication.shared.alert(title: "Error", body: "There was an error reading the imported file", withButton: true)
            }
        }
    }

#if !os(tvOS) && !os(macOS)
    struct tabbar: View {
        @Binding var selectedTab: Int
        @EnvironmentObject var appData: AppData
        @State private var queueOpen = false
        @State private var installingQueue = false
        @State private var installLog = ""
        @State private var showLog = false
        @State private var editing = false
        let tabItems = ["Featured", "Browse", "Installed", "Search"]
        let tabItemImages = ["Featured":Image("home_icon"), "Browse":Image("browse_icon"), "Installed":Image("installed_icon"), "Search":Image("search_icon")]
        
        var body: some View {
            VStack {
                
                if !appData.queued.all.isEmpty {
                    VStack {
                        Button(action: {
                            if !installingQueue {
                                queueOpen.toggle()
                                editing = false
                            }
                        }) {
                            HStack {
                                Image("queue_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                Text("\(appData.queued.all.count) Queued Tweak\(appData.queued.all.count >= 2 ? "s" : "")").padding(.horizontal, 5).animation(.spring(), value: appData.queued.all.count)
                                Spacer()
                                if queueOpen {
                                    Button(action: {editing.toggle()}, label: {Image(systemName: editing ? "checkmark" : "trash")})
                                }
                            }.padding(.horizontal, 20).padding(.vertical, 10).background(Color.black.opacity(0.001)).shadow(color: .accentColor, radius: 5).foregroundColor(.accentColor)
                        }.buttonStyle(.plain).padding(.top, queueOpen ? UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0  ? 50 : 25 : 0).padding(.bottom, -20)
                        VStack(alignment: .leading) {
                            if !showLog {
                                if !appData.queued.install.isEmpty {
                                    Section(content: {
                                        ForEach(appData.queued.install, id: \.id) { package in
                                            VStack {
                                                HStack {
                                                    TweakRow(tweak: package, focused: .constant(false))
                                                    Spacer()
                                                    if editing {
                                                        Button(action: {
                                                            if appData.queued.all.count == 1 {
                                                                queueOpen = false
                                                            }
                                                            appData.queued.install.remove(at: appData.queued.install.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                            appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                        }) {
                                                            Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                                        }
                                                    }
                                                }.padding(.trailing)
                                                if installingQueue {
                                                    VStack(alignment: .leading) {
                                                        Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                                        ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                            .progressViewStyle(LinearProgressViewStyle())
                                                            .frame(height: 2)
                                                    }
                                                    .foregroundColor(.secondary).padding(.top, 5)
                                                }
                                            }.opacity(queueOpen ? 1.0 : 0.0)
                                                .frame(height: queueOpen ? 56.0 : 0.0)
                                                .padding(.horizontal)
                                        }
                                    }, header: {Text(queueOpen ? "Install" : "").foregroundColor(.accentColor).padding(.leading).padding(.top)})
                                }
                                if !appData.queued.uninstall.isEmpty {
                                    Section(content: {
                                        ForEach(appData.queued.uninstall, id: \.id) { package in
                                            VStack {
                                                HStack {
                                                    TweakRow(tweak: package, focused: .constant(false))
                                                    Spacer()
                                                    if editing {
                                                        Button(action: {
                                                            if appData.queued.all.count == 1 {
                                                                queueOpen = false
                                                            }
                                                            appData.queued.uninstall.remove(at: appData.queued.uninstall.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                            appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                        }) {
                                                            Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                                        }
                                                    }
                                                }.padding(.trailing)
                                                if installingQueue {
                                                    VStack(alignment: .leading) {
                                                        Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                                        ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                            .progressViewStyle(LinearProgressViewStyle())
                                                            .frame(height: 2)
                                                    }
                                                    .foregroundColor(.secondary).padding(.top, 5)
                                                }
                                            }.opacity(queueOpen ? 1.0 : 0.0)
                                                .frame(height: queueOpen ? 56.0 : 0.0)
                                                .padding(.horizontal)
                                        }
                                    }, header: {Text(queueOpen ? "Uninstall" : "").foregroundColor(.accentColor).padding(.leading).padding(.top)})
                                }
                            } else {
                                Text(installLog).padding().frame(height: queueOpen ? .infinity : 0)
                            }
                            if queueOpen {
                                Spacer()
                            }
                            HStack {
                                if !queueOpen {
                                    Spacer()
                                }
                                Button(action: {
                                    if !showLog {
                                        if Jailbreak.type(appData) == .jailed {
                                            UIApplication.shared.alert(title: ":frcoal:", body: "PurePKG is in Jailed Mode, You cannot install tweaks.")
                                        } else {
                                            installingQueue = true
                                            APTWrapper.performOperations(installs: appData.queued.install, removals: appData.queued.uninstall, installDeps: RepoHandler.getDeps(appData.queued.install, appData),
                                            progressCallback: { _, statusValid, statusReadable, package in
                                                log("STATUSINFO:\nStatusValid: \(statusValid)\nStatusReadable: \(statusReadable)\nPackage: \(package)")
                                                var percent: Double = 0
                                                if statusReadable.contains("Installed") {
                                                    percent = 1
                                                } else if statusReadable.contains("Configuring") {
                                                    percent = 0.7
                                                } else if statusReadable.contains("Preparing") {
                                                    percent = 0.4
                                                }
                                                if appData.queued.status[package]?.percentage ?? 0 <= percent {
                                                    appData.queued.status[package] = installStatus(message: statusReadable, percentage: percent)
                                                }
                                            },
                                            outputCallback: { output, _ in installLog += "\(output)" },
                                            completionCallback: { _, finish, refresh in log("completionCallback: \(finish)"); appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status"); showLog = true })
                                        }
                                    } else {
                                        installingQueue = false
                                        queueOpen = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            appData.queued = PKGQueue()
                                            showLog = false
                                        }
                                    }
                                }, label: {
                                    if queueOpen {
                                        Spacer()
                                    }
                                    Text(showLog ? "Close" : "Perform Actions").padding()
                                    if queueOpen {
                                        Spacer()
                                    }
                                }).borderedPromButton().tintCompat(Color.accentColor.opacity(0.7))
                                if !queueOpen {
                                    Spacer()
                                }
                            }.padding().opacity(queueOpen ? 1.0 : 0.0).frame(height: queueOpen ? 56.0 : 0.0).padding(.bottom, 30)
                        }.frame(height: queueOpen ? .infinity : 0)
                    }
                }
                
                if queueOpen && !appData.queued.all.isEmpty {
                    Spacer()
                }
                
                HStack {
                    ForEach(0..<4) { index in
                        Button(action: { if !appData.repos.isEmpty { selectedTab = index } }) {
                            HStack {
                                tabItemImages[tabItems[index]]?
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                if selectedTab == index {
                                    Text("\(tabItems[index])").lineLimit(1)
                                }
                            }.padding(.horizontal, UIScreen.main.bounds.width * 0.03)
                        }.padding(.top, 16).background(Color.black.opacity(0.001))
                        .foregroundColor(selectedTab == index ? .accentColor : .accentColor.opacity(0.2))
                        .shadow(color: selectedTab == index ? .accentColor : .accentColor.opacity(0.2), radius: 5)
                        .animation(.spring(), value: selectedTab)
                        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0 ? 35 : 16)
                    }
                }.frame(width: UIScreen.main.bounds.width)
                    .transition(.move(edge: .bottom))
                    .noTabBarBG()
            }
            .frame(width: UIScreen.main.bounds.width)
            .background(VisualEffectView(effect: UIBlurEffect(style: .dark)).edgesIgnoringSafeArea(.all))
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: appData.queued.all.isEmpty).animation(.spring(), value: queueOpen).animation(.spring(), value: editing).noTabBarBG()
        }
    }
#endif
}
