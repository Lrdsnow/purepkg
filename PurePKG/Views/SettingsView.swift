//
//  SettingsView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI
import NukeUI
import PhotosUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var jb: String? = nil
    @State private var VerifySignature: Bool = true
    @State private var RefreshOnStart: Bool = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        #if os(watchOS)
                        Image(uiImageC: UIImage(named: "DisplayAppIcon")!).resizable().scaledToFit().frame(width: 50, height: 50).cornerRadius(100).padding(.trailing, 5)
                        Text("PurePKG").font(.system(size: 20, weight: .bold, design: .rounded))
                        #else
                        Image(uiImageC: UIImage(named: "DisplayAppIcon")!).resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        Text("PurePKG").font(.system(size: 40, weight: .bold, design: .rounded))
                        #endif
                    }
                }.padding(.leading, 5)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets()).listRowSeparatorC(false)
            #if os(watchOS)
                .padding(.bottom, -15)
            #endif
            Section {
                HStack {
                    Text("App Version").minimumScaleFactor(0.5)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0").minimumScaleFactor(0.5)
                }.listRowBG()
                HStack {
                    Text("Device").minimumScaleFactor(0.5)
                    Spacer()
                    Text(Device().modelIdentifier).minimumScaleFactor(0.5)
                }.listRowBG()
                HStack {
                    #if os(watchOS)
                    Text("watchOS Ver").minimumScaleFactor(0.5)
                    #else
                    Text("\(Device().osString) Version").minimumScaleFactor(0.5)
                    #endif
                    Spacer()
                    #if os(watchOS)
                    Text("\(Device().pretty_version)").minimumScaleFactor(0.5)
                    #else
                    Text("\(Device().pretty_version)\(Device().build_number == "" ? "" : " (\(Device().build_number))")").minimumScaleFactor(0.5)
                    #endif
                }.listRowBG()
#if !os(macOS)
                HStack {
                    #if os(watchOS)
                    Text("JB Type").minimumScaleFactor(0.5)
                    #else
                    Text("Jailbreak Type").minimumScaleFactor(0.5)
                    #endif
                    Spacer()
                    Text(Jailbreak().pretty_type).minimumScaleFactor(0.5)
                }.listRowBG()
#endif
                HStack {
                    #if os(watchOS)
                    Text("Arch").minimumScaleFactor(0.5)
                    #else
                    Text("Architecture").minimumScaleFactor(0.5)
                    #endif
                    Spacer()
                    Text(Jailbreak().arch).minimumScaleFactor(0.5)
                }.listRowBG()
#if !os(macOS)
                if let jb = jb {
                    HStack {
                        Text("Jailbreak").minimumScaleFactor(0.5)
                        Spacer()
                        Text(jb).minimumScaleFactor(0.5)
                    }.listRowBG()
                }
#endif
                HStack {
                    Text("Tweak Count").minimumScaleFactor(0.5)
                    Spacer()
                    Text("\(appData.installed_pkgs.count)").minimumScaleFactor(0.5)
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $VerifySignature, label: {
                        Text("Verify GPG Signature").minimumScaleFactor(0.5)
                    }).tintC(.accentColor)
                }.onChangeC(of: VerifySignature) { _ in
                    UserDefaults.standard.set(VerifySignature, forKey: "checkSignature")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $RefreshOnStart, label: {
                        Text("Refresh Repos on Start").minimumScaleFactor(0.5)
                    }).tintC(.accentColor)
                }.onChangeC(of: RefreshOnStart) { _ in
                    UserDefaults.standard.set(!RefreshOnStart, forKey: "ignoreInitRefresh")
                }.listRowBG()
#if os(iOS)
                if #available(iOS 14.0, tvOS 16.0, *) {
                    NavigationLink(destination: PaymentSettingsView()) {
                        Text("Payment Settings").minimumScaleFactor(0.5)
                    }.listRowBG()
                }
#endif
#if os(iOS)
                NavigationLink(destination: UISettingsView()) {
                    Text("UI Settings").minimumScaleFactor(0.5)
                }.listRowBG()
#endif
#if !os(macOS)
                NavigationLink(destination: CreditsView()) {
                    Text("Credits").minimumScaleFactor(0.5)
                }.listRowBG()
#else
                SectionC("Credits") {
                    Link(destination: URL(string: "https://github.com/Lrdsnow")!) {
                        CreditView(name: "Lrdsnow", role: "Developer", icon: "lrdsnow")
                    }
                    Link(destination: URL(string: "https://icons8.com")!) {
                        CreditView(name: "Icons8", role: "Default Plumpy Icons", icon: "icons8")
                    }
                    Link(destination: URL(string: "https://github.com/Sileo")!) {
                        CreditView(name: "Sileo", role: "APTWrapper", icon: "sileo")
                    }
                }
#endif
//                NavigationLink(destination: TroubleshootingView()) {
//                    Text("Troubleshooting")
//                }.listRowBG()
            }
        }
        .clearListBG()
        .appBG()
        .onAppear() {
            jb = Jailbreak.jailbreak()
            VerifySignature = UserDefaults.standard.bool(forKey: "checkSignature")
        }
    }
}

#if os(iOS)
@available(iOS 14.0, tvOS 16.0, *)
struct PaymentSettingsView: View {
    @StateObject private var viewModel = PaymentAPI_AuthenticationViewModel()
    @EnvironmentObject var appData: AppData
    @State private var usePaymentAPI: Bool = UserDefaults.standard.bool(forKey: "usePaymentAPI")
    @State private var hidePaidTweaks: Bool = UserDefaults.standard.bool(forKey: "hidePaidTweaks")
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $hidePaidTweaks, label: {
                    Text("Hide Paid Tweaks")
                }).tintC(.accentColor).onChangeC(of: hidePaidTweaks) { _ in
                    UserDefaults.standard.set(hidePaidTweaks, forKey: "hidePaidTweaks")
                }.listRowBG()
                if !hidePaidTweaks {
                    Toggle(isOn: $usePaymentAPI, label: {
                        Text("Use Payment API")
                    }).tintC(.accentColor).onChangeC(of: usePaymentAPI) { _ in
                        UserDefaults.standard.set(usePaymentAPI, forKey: "usePaymentAPI")
                    }.listRowBG()
                }
            }
            if !hidePaidTweaks && usePaymentAPI {
                Section {
                    ForEach(appData.repos.filter( { $0.paidRepoInfo != nil } ), id:\.id) { repo in
                        if let paidRepoInfo = repo.paidRepoInfo {
#if os(tvOS)
                            if let authURL = repo.paymentAPI.authURL {
                                NavigationLink(destination: WebAuthView(url: authURL) { v in log(v) }) {
                                    buttonLabel(repo: repo, paidRepoInfo: paidRepoInfo)
                                }
                            }
#else
                            Button(action: {
                                if (appData.userInfo[repo.name] != nil) {
                                    showConfirmPopup("Sign Out", "Are you sure you'd like to sign out of \(repo.name)?") { confirmed in
                                        if confirmed {
                                            PaymentAPI.logOut(repo) {
                                                DispatchQueue.main.async {
                                                    appData.userInfo.removeValue(forKey: repo.name)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    viewModel.auth(repo, appData: appData)
                                }
                            }, label: {
                                buttonLabel(repo: repo, paidRepoInfo: paidRepoInfo)
                            }).padding(.vertical, 5)
#endif
                        }
                    }
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets()).listRowSeparatorC(false)
            }
        }
    }
    
    struct buttonLabel: View {
        @EnvironmentObject var appData: AppData
        let repo: Repo
        let paidRepoInfo: PaidRepoInfo
        let scale = UIScreen.main.bounds.height/10
        
        var body: some View {
            HStack {
                if #available(iOS 14.0, tvOS 14.0, *) {
                    LazyImage(url: paidRepoInfo.icon) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                                .scaledToFit()
                        }
                    }
                    .frame(width: scale, height: scale)
                    .cornerRadius(15)
                }
                VStack(alignment: .leading) {
                    Text(paidRepoInfo.name).font(.system(size: 25, design: .rounded).bold()).minimumScaleFactor(0.5).lineLimit(1)
                    Text((appData.userInfo[repo.name] != nil) ? "Logged in as \(appData.userInfo[repo.name]?.user.name ?? "Unknown")" : paidRepoInfo.description).font(.system(size: 15)).foregroundColor(Color.secondary).minimumScaleFactor(0.5).lineLimit(1)
                }
                Spacer()
            }.background(Rectangle().foregroundColor(.accentColor.opacity(0.05)).cornerRadius(15))
        }
    }
}
#endif

#if os(macOS)
struct CreditView: View {
    let name: String
    let role: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .frame(width: 50, height: 50)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
#else
struct CreditsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Button(action: {
                if let url = URL(string: "https://github.com/Lrdsnow") {
                    openURL(url)
                }
            }) {
                CreditView(name: "Lrdsnow", role: "Developer", icon: URL(string: "https://github.com/lrdsnow.png")!)
            }
            Button(action: {
                if let url = URL(string: "https://github.com/Sileo") {
                    openURL(url)
                }
            }) {
                CreditView(name: "Sileo", role: "APTWrapper", icon: URL(string: "https://github.com/sileo.png")!)
            }
            Spacer()
        }.appBG().padding().navigationBarTitleC("Credits")
    }
}

struct CreditView: View {
    let name: String
    let role: String
    let icon: URL
    #if os(watchOS) || os(macOS)
    let scale: CGFloat = 0
    #else
    let scale = UIScreen.main.bounds.height/10
    #endif
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if #available(iOS 14.0, tvOS 14.0, *) {
                LazyImage(url: icon) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaledToFit()
                    } else {
                        ProgressView()
                            .scaledToFit()
                    }
                }
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .aspectRatio(contentMode: .fit)
                .frame(width: scale, height: scale)
                .cornerRadius(20)
                
                Spacer()
            }
            
            VStack(alignment: .center) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(role)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(height: scale)
    }
}

#if os(iOS)

enum SideExpanded {
    case left
    case right
    case none
}

struct UISettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    // Sheets
    @State private var globalSheet: Bool = false
    @State private var tabbarSheet: Bool = false
    @State private var rowsSheet: Bool = false
    @State private var iconSheet: Bool = false
    // Preview & Button
    @State private var expanded: SideExpanded = .none
    @State private var isLandscape = false
    @State private var showPreview = true
    @State private var previewTab = 0
    @State private var showPackage = false
    // Global Settings
    @State private var accentColor: Color = .accentColor
    @State private var useCustomBackground: Bool = false
    @State private var customBackground: UIImage? = nil
    @State private var isShowingImagePicker: Bool = false
    // Tabbar Settings
    @State private var customTabbar = false
    @State private var blurredTabbar = false
    @State private var iconGlow = true
    @State private var tabbarColor: Color = .black
    @State private var customIconColor = false
    @State private var iconColor: Color = .accentColor
    // Rows Settings
    @State private var showIcons: Bool = true
    @State private var circleIcons: Bool = false
    
    var body: some View {
        HStack {
            if expanded != .right || isLandscape {
                VStack {
                    if !isLandscape {
                        // Expandable
                        Button(action: {
                            if expanded != .left {
                                expanded = .left
                            } else {
                                expanded = .none
                            }
                        }, label: {
                            HStack {
                                if expanded == .left {
                                    Spacer()
                                }
                                Image(systemName: expanded == .left ? "chevron.left" : "chevron.right")
                                if expanded == .left {
                                    Text("Theme")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Spacer()
                                }
                            }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                        }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    }
                    // Global
                    Button(action: {
                        globalSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "globe")
                            if expanded == .left || isLandscape {
                                Text("Global")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Tabbar
                    Button(action: {
                        tabbarSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "dock.rectangle")
                            if expanded == .left || isLandscape {
                                Text("Tabbar")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Rows
                    Button(action: {
                        rowsSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "app.dashed")
                            if expanded == .left || isLandscape {
                                Text("Rows")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Icon
                    Button(action: {
                        iconSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "app.fill")
                            if expanded == .left || isLandscape {
                                Text("Icon")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                }
            }
            if showPreview {
                ContentView(tab: $previewTab, importedPackage: .constant(Package(id: "uwu.lrdsnow.purepkg.preview", name: "PurePKG", depiction: URL(string: "https://lrdsnow.github.io/purepkg/depiction.json"), icon: URL(string: "https://github.com/Lrdsnow/purepkg/blob/main/Icon.png?raw=true"))), showPackage: $showPackage, preview: true)
                    .frame(width: UIScreen.main.bounds.width/1.5, height: UIScreen.main.bounds.height/1.5)
                    .cornerRadius(25)
                    .allowsHitTesting(false)
                    .accentColor(accentColor)
                    .gesture(DragGesture(minimumDistance: 15)
                        .onEnded { value in
                            print(value)
                            print(value.translation)
                            if value.translation.width < 0 {
                                if expanded != .right {
                                    expanded = .right
                                } else {
                                    expanded = .none
                                }
                            } else if value.translation.width > 0 {
                                if expanded != .left {
                                    expanded = .left
                                } else {
                                    expanded = .none
                                }
                            }
                        })
            }
            if expanded != .left || isLandscape {
                VStack {
                    if !isLandscape {
                        // Expandable
                        Button(action: {
                            if expanded != .right {
                                expanded = .right
                            } else {
                                expanded = .none
                            }
                        }, label: {
                            HStack {
                                if expanded == .right {
                                    Spacer()
                                    Text("Preview")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                Image(systemName: expanded == .right ? "chevron.right" : "chevron.left")
                                if expanded == .right {
                                    Spacer()
                                }
                            }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                        }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    }
                    // Refresh Preview
                    Button(action: {
                        showPreview = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                            showPreview = true
                        }
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "arrow.clockwise")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Refresh Preview" : "Refresh")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Browse Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 0
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "globe")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Browse Tab" : "Browse")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Installed Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 1
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "star")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Installed Tab" : "Install")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Search Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 2
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "magnifyingglass")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Search Tab" : "Search")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                }
            }
        }.gesture(DragGesture(minimumDistance: 15)
            .onEnded { value in
                print(value)
                print(value.translation)
                if value.translation.width < 0 {
                    if expanded != .right {
                        expanded = .right
                    } else {
                        expanded = .none
                    }
                } else if value.translation.width > 0 {
                    if expanded != .left {
                        expanded = .left
                    } else {
                        expanded = .none
                    }
                }
            })
        .navigationBarTitleC("UI Settings").animation(.spring)
            .onRotate { newOrientation in
                isLandscape = newOrientation.isLandscape
            }
            .onAppear() {
                guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
                isLandscape = scene.interfaceOrientation.isLandscape
                if let accentColorHex = UserDefaults.standard.string(forKey: "accentColor") {
                    accentColor = Color(hex: accentColorHex) ?? .accentColor
                } else {
                    UserDefaults.standard.set(accentColor.toHex(), forKey: "accentColor")
                }
                if UserDefaults.standard.object(forKey: "useCustomBackground") != nil {
                    useCustomBackground = UserDefaults.standard.bool(forKey: "useCustomBackground")
                } else {
                    UserDefaults.standard.set(useCustomBackground, forKey: "useCustomBackground")
                }
                if UserDefaults.standard.object(forKey: "customTabbar") != nil {
                    customTabbar = UserDefaults.standard.bool(forKey: "customTabbar")
                } else {
                    UserDefaults.standard.set(customTabbar, forKey: "customTabbar")
                }
                if UserDefaults.standard.object(forKey: "blurredTabbar") != nil {
                    blurredTabbar = UserDefaults.standard.bool(forKey: "blurredTabbar")
                } else {
                    UserDefaults.standard.set(blurredTabbar, forKey: "blurredTabbar")
                }
                if let tabbarColorHex = UserDefaults.standard.string(forKey: "tabbarColor") {
                    tabbarColor = Color(hex: tabbarColorHex) ?? .black
                } else {
                    UserDefaults.standard.set(tabbarColor.toHex(), forKey: "tabbarColor")
                }
                if UserDefaults.standard.object(forKey: "iconGlow") != nil {
                    iconGlow = UserDefaults.standard.bool(forKey: "iconGlow")
                } else {
                    UserDefaults.standard.set(iconGlow, forKey: "iconGlow")
                }
                if UserDefaults.standard.object(forKey: "customIconColor") != nil {
                    customIconColor = UserDefaults.standard.bool(forKey: "customIconColor")
                } else {
                    UserDefaults.standard.set(customIconColor, forKey: "customIconColor")
                }
                if let iconColorHex = UserDefaults.standard.string(forKey: "iconColor") {
                    iconColor = Color(hex: iconColorHex) ?? .accentColor
                } else {
                    UserDefaults.standard.set(iconColor.toHex(), forKey: "iconColor")
                }
                if UserDefaults.standard.object(forKey: "showIcons") != nil {
                    showIcons = !UserDefaults.standard.bool(forKey: "hideIcons")
                } else {
                    UserDefaults.standard.set(!showIcons, forKey: "hideIcons")
                }
                if UserDefaults.standard.object(forKey: "circleIcons") != nil {
                    circleIcons = UserDefaults.standard.bool(forKey: "circleIcons")
                } else {
                    UserDefaults.standard.set(circleIcons, forKey: "circleIcons")
                }
                if UserDefaults.standard.object(forKey: "customBackground") != nil {
                    customBackground = UserDefaults.standard.imageForKey("customBackground")
                } else {
                    UserDefaults.standard.setImage(customBackground, forKey: "customBackground")
                }
            }
            .sheet(isPresented: $globalSheet, content: {
                NavigationView {
                    List {
                        if #available(iOS 14.0, tvOS 14.0, *) {
                            Section(content: {
                                ColorPicker("Accent Color", selection: $accentColor).onChangeC(of: accentColor) { newValue in
                                    UserDefaults.standard.set(newValue.toHex(), forKey: "accentColor")
                                }.contextMenu(menuItems: {
                                    Button(action: {
                                        UserDefaults.standard.set("", forKey: "accentColor")
                                        accentColor = Color(hex: "#EBC2FF")!
                                    }, label: {Text("Clear Accent Color"); Image("trash_icon").renderingMode(.template)})
                                })
                            }, footer: {
                                Text("Sets the global accent color")
                            })
                        }
                        Section(content: {
                            Toggle("Custom Background", isOn: $useCustomBackground).tintC(.accentColor).onChangeC(of: useCustomBackground, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "useCustomBackground")})
                        }, footer: {
                            Text("Use a custom background")
                        })
                        if useCustomBackground {
                            Section(content: {
                                Button(action: {
                                    globalSheet = false
                                    isShowingImagePicker = true
                                }, label: {
                                    Text("Set Custom Background Image")
                                })
                            }, footer: {
                                Text(customBackground != nil ? "There is currently an image set" : "No image set")
                            })
                        }
                    }.navigationBarTitleC("Global")
                }.accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? ""))
            })
            .sheet(isPresented: $tabbarSheet, content: {
                NavigationView {
                    List {
                        Section(content: {
                            Toggle("Custom Tabbar", isOn: $customTabbar).tintC(.accentColor).onChangeC(of: customTabbar, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "customTabbar")})
                        }, footer: {
                            Text("Use a custom tabbar instead of the default SwiftUI one")
                        })
                        if customTabbar {
                            Section(content: {
                                Toggle("Blurred Background", isOn: $blurredTabbar).tintC(.accentColor).onChangeC(of: blurredTabbar, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "blurredTabbar")})
                            }, footer: {
                                Text("Use a blurred background instead of a colored one")
                            })
                            if #available(iOS 14.0, tvOS 14.0, *) {
                                if !blurredTabbar {
                                    Section(content: {
                                        ColorPicker("Tabbar Color", selection: $tabbarColor).onChangeC(of: tabbarColor, perform: { newValue in UserDefaults.standard.set(newValue.toHex(), forKey: "tabbarColor")})
                                    }, footer: {
                                        Text("Sets the tabbar background color")
                                    })
                                }
                            }
                            Section(content: {
                                Toggle("Icon Glow", isOn: $iconGlow).tintC(.accentColor).onChangeC(of: iconGlow, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "iconGlow")})
                            }, footer: {
                                Text("Adds glow around the icons")
                            })
                            if #available(iOS 14.0, tvOS 14.0, *) {
                                Section(content: {
                                    Toggle("Custom Icon Color", isOn: $customIconColor).tintC(.accentColor).onChangeC(of: customIconColor, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "customIconColor")})
                                }, footer: {
                                    Text("Use a custom icon color")
                                })
                                if customIconColor {
                                    Section(content: {
                                        ColorPicker("Icon Color", selection: $iconColor).onChangeC(of: iconColor, perform: { newValue in UserDefaults.standard.set(newValue.toHex(), forKey: "iconColor")})
                                    }, footer: {
                                        Text("Sets the icon color")
                                    })
                                }
                            }
                        }
                    }.navigationBarTitleC("Tabbar")
                }.accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? ""))
            })
            .sheet(isPresented: $rowsSheet, content: {
                NavigationView {
                    List {
                        if #available(iOS 14.0, tvOS 14.0, *) {
                            Section(content: {
                                Toggle("Show Icons", isOn: $showIcons).tintC(.accentColor).onChangeC(of: showIcons, perform: { newValue in UserDefaults.standard.set(!newValue, forKey: "hideIcons")})
                            }, footer: {
                                Text("Show Icons")
                            })
                            if showIcons {
                                Section(content: {
                                    Toggle("Circle Icons", isOn: $circleIcons).tintC(.accentColor).onChangeC(of: circleIcons, perform: { newValue in UserDefaults.standard.set(newValue, forKey: "circleIcons")})
                                }, footer: {
                                    Text("Make icons circular")
                                })
                            }
                        } else {
                            Text("All options normally found here are unavailable for iOS 13 users.")
                        }
                    }.navigationBarTitleC("Rows")
                }.accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? ""))
            })
            .sheet(isPresented: $iconSheet, content: {
                NavigationView {
                    List {
                        Button(action: {
                            UIApplication.shared.setAlternateIconName(nil, completionHandler: nil)
                        }, label: {
                            HStack {
                                Image(uiImageC: UIImage(named: "AppIcon") ?? UIImage(named: "DisplayAppIcon")!)
                                    .resizable()
                                    .frame(width: 85, height: 85)
                                    .cornerRadius(15)
                                VStack(alignment: .leading) {
                                    Text("PurePKG").font(.system(size: 25, design: .rounded).bold())
                                    Text("Lrdsnow").font(.system(size: 15)).foregroundColor(Color.secondary)
                                }
                                Spacer()
                            }.background(Rectangle().foregroundColor(.accentColor.opacity(0.1)).cornerRadius(15))
                        })
                        Button(action: {
                            UIApplication.shared.setAlternateIconName("AppIcon1", completionHandler: nil)
                        }, label: {
                            HStack {
                                Image(uiImageC: UIImage(named: "AppIcon1") ?? UIImage(named: "DisplayAppIcon")!)
                                    .resizable()
                                    .frame(width: 85, height: 85)
                                    .cornerRadius(15)
                                VStack(alignment: .leading) {
                                    Text("PurePKG VisionOS").font(.system(size: 25, design: .rounded).bold())
                                    Text("dor4a").font(.system(size: 15)).foregroundColor(Color.secondary)
                                }
                                Spacer()
                            }.background(Rectangle().foregroundColor(.accentColor.opacity(0.1)).cornerRadius(15))
                        })
                        Button(action: {
                            UIApplication.shared.setAlternateIconName("AppIcon2", completionHandler: nil)
                        }, label: {
                            HStack {
                                Image(uiImageC: UIImage(named: "AppIcon2") ?? UIImage(named: "DisplayAppIcon")!)
                                    .resizable()
                                    .frame(width: 85, height: 85)
                                    .cornerRadius(15)
                                VStack(alignment: .leading) {
                                    Text("DopaPKG").font(.system(size: 25, design: .rounded).bold())
                                    Text("dor4a").font(.system(size: 15)).foregroundColor(Color.secondary)
                                }
                                Spacer()
                            }.background(Rectangle().foregroundColor(.accentColor.opacity(0.1)).cornerRadius(15))
                        })
                    }.listStyle(.plain).navigationBarTitleC("Icons")
                }.accentColor(Color(hex: UserDefaults.standard.string(forKey: "accentColor") ?? ""))
            })
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $customBackground)
            }
            .onChangeC(of: isShowingImagePicker, perform: { _ in
                if isShowingImagePicker == false {
                    globalSheet = true
                }
            })
            .onChangeC(of: customBackground, perform: { newValue in
                if newValue != nil {
                    UserDefaults.standard.setImage(newValue, forKey: "customBackground")
                }
            })
            .appBG()
    }
}
#endif
#endif
