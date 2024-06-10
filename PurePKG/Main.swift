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
            if #available(iOS 14.0, tvOS 14.0, *) {
                PurePKGApp.main();
            } else {
#if !os(macOS) && !os(watchOS)
                UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self));
#endif
            }
        } else {
             exit(RootHelperMain());
        }
        
    }
}

#if !os(macOS) && !os(watchOS)
class AppDelegate: UIResponder, UIApplicationDelegate {
    @ObservedObject private var appData = AppData()
    @State private var tab = 0
    @State private var importedPackage: Package? = nil
    @State private var showPackage = false

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if os(iOS)
        UINavigationBar.appearance().prefersLargeTitles = true
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = .clear
        #endif
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
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let viewController = UIHostingController(rootView: ContentView(tab: $tab, importedPackage: $importedPackage, showPackage: $showPackage, preview: false).environmentObject(appData).accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "#EBC2FF")).onAppear() { if !UserDefaults.standard.bool(forKey: "seenWarning") { showPopup("Warning", "While iOS 13 is compatible it is NOT supported and will be buggy"); UserDefaults.standard.setValue(true, forKey: "seenWarning") } })
        window.rootViewController = viewController
        return true
    }
}
#endif

@available(iOS 14.0, tvOS 14.0, *)
struct PurePKGApp: App {
    @StateObject private var appData = AppData()
    @State private var tab = 0
    @State private var importedPackage: Package? = nil
    @State private var showPackage = false
    
    init() {
        #if os(iOS)
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
            #if os(watchOS)
            ContentViewWatchOS(tab: $tab, importedPackage: $importedPackage, showPackage: $showPackage)
                .environmentObject(appData)
                .accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "#EBC2FF"))
            #else
            ContentView(tab: $tab, importedPackage: $importedPackage, showPackage: $showPackage, preview: false)
                .environmentObject(appData)
                .accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? "#EBC2FF"))
            #endif
        }
    }
}

// Main

#if os(watchOS)
struct ContentViewWatchOS: View {
    @EnvironmentObject var appData: AppData
    @Binding var tab: Int
    @Binding var importedPackage: Package?
    @Binding var showPackage: Bool
    
    var body: some View {
        NavigationViewC {
            List {
                NavigationLink(destination: BrowseView(importedPackage: $importedPackage, showPackage: $showPackage, preview: false), label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Browse")
                    }
                })
                NavigationLink(destination: InstalledView(preview: false), label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Installed")
                    }
                })
                NavigationLink(destination: SearchView(preview: false), label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                })
                if !appData.queued.all.isEmpty {
                    NavigationLink(destination: QueueView(), label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Queued")
                        }
                    })
                }
                NavigationLink(destination: SettingsView(), label: {
                    HStack {
                        if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                            Image(systemName: "gearshape.fill")
                        } else {
                            Image(systemName: "gear")
                        }
                        Text("Settings")
                    }
                })
            }.navigationBarTitleC("PurePKG").onAppear() { startup() }
        }
    }
    
    private func startup() {
        if #available(iOS 14.0, tvOS 14.0, *) {
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
#else
struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @Binding var tab: Int
    @Binding var importedPackage: Package?
    @Binding var showPackage: Bool
    let preview: Bool
    
    var body: some View {
        if !UserDefaults.standard.bool(forKey: "customTabbar") {
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
            }.onAppear() { startup() }.onOpenURLC { url in
                handleIncomingURL(url)
            }
        } else {
            ZStack(alignment: .bottom) {
                TabView(selection: $tab) {
                    BrowseView(importedPackage: $importedPackage, showPackage: $showPackage, preview: preview)
                        .tag(0)
                    InstalledView(preview: preview)
                        .tag(1)
                    SearchView(preview: preview)
                        .tag(2)
                }.onOpenURLC { url in
                    handleIncomingURL(url)
                }
#if os(iOS)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: preview ? UIScreen.main.bounds.width/1.5 : UIScreen.main.bounds.width)
#endif
#if os(iOS)
                tabbar(selectedTab: $tab, preview: preview)
#endif
            }.edgesIgnoringSafeArea(.bottom).onAppear() { startup() }
        }
    }
    
    private func startup() {
        if #available(iOS 14.0, tvOS 14.0, *) {
            if !preview {
                appData.jbdata.jbtype = Jailbreak.type(appData)
                appData.jbdata.jbarch = Jailbreak.arch(appData)
                appData.jbdata.jbroot = Jailbreak.path(appData)
                appData.deviceInfo = getDeviceInfo()
                log(appData.deviceInfo)
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
    
    private func handleIncomingURL(_ url: URL) {
        print("App was opened via URL: \(url)")
        if url.absoluteString.contains("purepkg://addrepo/") {
            let repourl = url.absoluteString.replacingOccurrences(of: "purepkg://addrepo/", with: "")
            print("Adding Repo: \(repourl)")
            RepoHandler.addRepo(repourl)
        } else if url.pathExtension == "deb" {
            let info = APTWrapper.spawn(command: "\(Jailbreak.path())/\(Jailbreak.type() == .macos ? "" : "usr/")bin/dpkg-deb", args: ["dpkg-deb", "--field", url.path])
            if info.0 == 0 {
                let dict = Networking.genDict(info.1)
                var tweak = RepoHandler.createPackageStruct(dict)
                tweak.debPath = url.path
                importedPackage = tweak
                showPackage = true
            } else {
                showPopup("Error", "There was an error reading the imported file")
            }
        }
    }
    
#if os(iOS)
    struct tabbar: View {
        @Binding var selectedTab: Int
        @EnvironmentObject var appData: AppData
        @State private var queueOpen = false
        @State private var installingQueue = false
        @State private var installLog = ""
        @State private var showLog = false
        @State private var editing = false
        let tabItems = ["Browse", "Installed", "Search"]
        let tabItemImages = ["Browse":Image(systemName: "globe"), "Installed":Image(systemName: "star.fill"), "Search":Image(systemName: "magnifyingglass")]
        @State private var deps: [Package] = []
        @State private var toInstall: [Package] = []
        let preview: Bool
        
        var body: some View {
            VStack {
                
                if !appData.queued.all.isEmpty {
                    VStack {
                        Button(action: {
                            if !installingQueue {
                                queueOpen.toggle()
                                editing = false
                                refresh()
                            }
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
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
                                        ForEach(toInstall, id: \.id) { package in
                                            VStack {
                                                HStack {
                                                    TweakRow(tweak: package)
                                                        .padding(.leading, (deps.contains(where: { $0.id == package.id }) && !appData.queued.install.contains(where: { $0.id == package.id })) ? 10 : 0)
                                                    Spacer()
                                                    if editing && !(deps.contains(where: { $0.id == package.id }) && !appData.queued.install.contains(where: { $0.id == package.id }))  {
                                                        Button(action: {
                                                            appData.queued.install.remove(at: appData.queued.install.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                            appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                            refresh()
                                                        }) {
                                                            Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                                        }
                                                    }
                                                }.padding(.trailing)
                                                if installingQueue {
                                                    VStack(alignment: .leading) {
                                                        Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                                        if #available(iOS 14.0, tvOS 14.0, *) {
                                                            ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                                .progressViewStyle(LinearProgressViewStyle())
                                                                .frame(height: 2)
                                                        }
                                                    }
                                                    .foregroundColor(.secondary).padding(.top, 5)
                                                }
                                            }.padding(.horizontal).opacity(queueOpen ? 100 : 0)
                                        }
                                    }, header: {
                                        Text("Install/Upgrade").foregroundColor(.accentColor.opacity(queueOpen ? 100 : 0)).padding(.leading).padding(.top)
                                    })
                                }
                                if !appData.queued.uninstall.isEmpty {
                                    Section(content: {
                                        ForEach(appData.queued.uninstall, id: \.id) { package in
                                            VStack {
                                                HStack {
                                                    TweakRow(tweak: package)
                                                    Spacer()
                                                    if editing {
                                                        Button(action: {
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
                                                        if #available(iOS 14.0, tvOS 14.0, *) {
                                                            ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                                .progressViewStyle(LinearProgressViewStyle())
                                                                .frame(height: 2)
                                                        }
                                                    }
                                                    .foregroundColor(.secondary).padding(.top, 5)
                                                }
                                            }.padding(.horizontal)
                                        }
                                    }, header: {
                                        Text("Uninstall").foregroundColor(.accentColor)
                                        #if !os(iOS)
                                            .padding(.leading).padding(.top)
                                        #endif
                                    })
                                }
                            } else {
                                Text(installLog).padding().frame(height: queueOpen ? .infinity : 0)
                            }
                            if queueOpen {
                                Spacer()
                            }
                            InstallQueuedButton(showLog: $showLog, installingQueue: $installingQueue, installLog: $installLog, deps: $deps).padding(.bottom, 30).padding().opacity(queueOpen ? 1.0 : 0.0).frame(height: queueOpen ? 56.0 : 0.0).padding(.bottom, 30)
                        }.frame(height: queueOpen ? .infinity : 0)
                    }
                }
                
                if queueOpen && !appData.queued.all.isEmpty {
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    ForEach(0..<3) { index in
                        Button(action: { selectedTab = index }) {
                            HStack {
                                tabItemImages[tabItems[index]]?
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: preview ? 25 : 32, height: preview ? 25 : 32)
                                if selectedTab == index {
                                    Text("\(tabItems[index])").lineLimit(1).minimumScaleFactor(0.5)
                                }
                            }.padding(.horizontal, UIScreen.main.bounds.width * 0.03)
                        }.padding(.top, 16).background(Color.black.opacity(0.001))
                        .foregroundColor(selectedTab == index ? .accentColor : .accentColor.opacity(0.2))
                        .shadow(color: selectedTab == index ? .accentColor : .accentColor.opacity(0.2), radius: UserDefaults.standard.bool(forKey: "iconGlow") ? 5 : 0)
                        .animation(.spring(), value: selectedTab)
                        .padding(.bottom, preview ? 16 : UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0 ? 35 : 16)
                        Spacer()
                    }
                }.frame(width: preview ? UIScreen.main.bounds.width/1.5 : UIScreen.main.bounds.width).transition(.move(edge: .bottom))
            }
            .frame(width: preview ? UIScreen.main.bounds.width/1.5 : UIScreen.main.bounds.width)
            .customTabbarBG()
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: appData.queued.all.isEmpty).animation(.spring(), value: queueOpen).animation(.spring(), value: editing)
            .accentColor(UserDefaults.standard.bool(forKey: "customIconColor") ? (Color(hex: UserDefaults.standard.string(forKey: "iconColor") ?? UserDefaults.standard.string(forKey: "accentColor") ?? "#EBC2FF") ?? .accentColor) : .accentColor)
        }
        
        private func refresh() {
            deps = RepoHandler.getDeps(appData.queued.install, appData)
            toInstall = appData.queued.install + deps.filter { dep in appData.queued.install.first(where: { $0.id == dep.id }) == nil }
        }
    }
#endif
}
#endif
