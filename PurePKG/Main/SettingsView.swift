//
//  SettingsView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var accent = Color.accentColor
    @State private var showBGChanger = false
    @State private var jb: String? = nil
    @State private var VerifySignature: Bool = true
    @State private var RefreshOnStart: Bool = true
    @State private var simpleMode: Bool = false
    @State private var uiSettingsExpanded: Bool = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).customRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        Text("PurePKG").font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                }.padding(.leading, 5)
            }.listRowBackground(Color.clear).noListRowSeparator().listRowInsets(EdgeInsets())
            Section {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")
                }.listRowBG()
                HStack {
                    Text("Device")
                    Spacer()
                    Text(appData.deviceInfo.modelIdentifier)
                }.listRowBG()
                HStack {
                    Text("\(osString()) Version")
                    Spacer()
                    Text("\(appData.deviceInfo.major).\(appData.deviceInfo.minor)\(appData.deviceInfo.patch == 0 ? "" : ".\(appData.deviceInfo.patch)")\(appData.deviceInfo.build_number == "0" ? "" : " (\(appData.deviceInfo.build_number))")")
                }.listRowBG()
#if !os(macOS)
                HStack {
                    Text("Jailbreak Type")
                    Spacer()
                    Text((appData.jbdata.jbtype == .rootful || appData.jbdata.jbtype == .tvOS_rootful) ? "Rootful" : appData.jbdata.jbtype == .rootless ? "Rootless" : appData.jbdata.jbtype == .roothide ? "Roothide" : "Jailed")
                }.listRowBG()
#endif
                HStack {
                    Text("Architecture")
                    Spacer()
                    Text("\(appData.jbdata.jbarch)")
                }.listRowBG()
#if !os(macOS)
                if let jb = jb {
                    HStack {
                        Text("Jailbreak")
                        Spacer()
                        Text(jb)
                    }.listRowBG()
                }
#endif
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("\(appData.installed_pkgs.count)")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $VerifySignature, label: {
                        Text("Verify GPG Signature")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: VerifySignature) { _ in
                    UserDefaults.standard.set(VerifySignature, forKey: "checkSignature")
                }
                
                HStack {
                    Toggle(isOn: $RefreshOnStart, label: {
                        Text("Refresh Repos on Start")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: RefreshOnStart) { _ in
                    UserDefaults.standard.set(!RefreshOnStart, forKey: "ignoreInitRefresh")
                }
                
#if !os(macOS) && !os(tvOS)
                DisclosureGroup("UI Settings", isExpanded: $uiSettingsExpanded) {
#if os(iOS)
                    if #available(iOS 15.0, *) {
                        HStack {
                            Toggle(isOn: $simpleMode, label: {
                                Text("Basic UI Mode")
                            }).tintCompat(.accentColor)
                        }.listRowBG().onChange(of: simpleMode) { _ in
                            UserDefaults.standard.set(simpleMode, forKey: "simpleMode")
                        }
                    }
#endif
                    ColorPicker("Accent color", selection: $accent).listRowBG().onChange(of: accent) { newValue in
                        UserDefaults.standard.set(newValue.toHex(), forKey: "accentColor")
                        appData.test.toggle()
                    }.contextMenu(menuItems: {
                        Button(action: {
                            UserDefaults.standard.set("", forKey: "accentColor")
                            accent = Color(UIColor(hex: "#EBC2FF")!)
                            appData.test.toggle()
                        }, label: {Text("Clear Accent Color"); Image("trash_icon").renderingMode(.template)})
                    })
                    NavigationLink(destination: AdvancedUISettingsView()) {
                        Text("Advanced UI Settings")
                    }.listRowBG()
                    //                NavigationLink(destination: IconsView()) {
                    //                    Text("Change Icon")
                    //                }.listRowBG()
                    //                NavigationLink(destination: InAppIconsView()) {
                    //                    Text("Change InApp Icons")
                    //                }.listRowBG()
                    //                Button(action: {showBGChanger.toggle()}, label: {Text("Change Background")}).listRowBG()
                }.listRowBG()
#elseif os(tvOS)
                NavigationLink(destination: AdvancedUISettingsView()) {
                    Text("UI Settings")
                }.listRowBG()
#endif
#if !os(macOS)
                NavigationLink(destination: CreditsView()) {
                    Text("Credits")
                }.listRowBG()
#endif
            }
#if os(macOS)
            Section("Credits") {
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
#elseif !os(tvOS)
            paddingBlock()
#endif
        }
        .clearListBG()
        .BGImage(appData)
        .onAppear() {
            jb = Jailbreak.jailbreak()
            VerifySignature = UserDefaults.standard.bool(forKey: "checkSignature")
            simpleMode = UserDefaults.standard.bool(forKey: "simpleMode")
        }
        .listStyleInsetGrouped()
#if !os(macOS) && !os(tvOS)
        .sheet(isPresented: $showBGChanger) {ChangeBGView().blurredBG()}
#endif
    }
}

#if !os(macOS) && !os(tvOS)
struct ChangeBGView: View {
    var body: some View {
        VStack {
            Spacer()
            Text(":frcoal:")
            Spacer()
        }.padding()
    }
}

struct InAppIconsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Spacer()
            Text(":frcoal:")
            Spacer()
        }.padding().BGImage(appData).navigationTitle("InApp Icons")
    }
}

struct IconsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Button(action: {}) {
                CreditView(name: "PurePKG", role: "By Lrdsnow", icon: "DisplayAppIcon")
            }
            Spacer()
        }.padding().BGImage(appData).navigationTitle("Icons")
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

struct AdvancedUISettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var lazyLoadRows: Bool = false
    @State private var circleIcons: Bool = false
    @State private var hideFeatured: Bool = false
    @State private var usePlainNavBar: Bool = false
    @State private var disableAnimations: Bool = false
    @State private var disableBackground: Bool = false
    
    var body: some View {
        List {
            DescriptionSection(desc: "Increases Performance - Breaks row alignment sometimes") {
                HStack {
                    Toggle(isOn: $lazyLoadRows, label: {
                        Text("Lazy Load Rows")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: lazyLoadRows) { _ in
                    UserDefaults.standard.set(lazyLoadRows, forKey: "lazyLoadRows")
                }
            }
#if os(iOS)
            DescriptionSection(desc: "Increases Performance - Hides upper part in the featured page") {
                HStack {
                    Toggle(isOn: $hideFeatured, label: {
                        Text("Hide Featured")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: hideFeatured) { _ in
                    UserDefaults.standard.set(hideFeatured, forKey: "hideFeatured")
                }
            }
#endif
            DescriptionSection(desc: "Makes icons circle") {
                HStack {
                    Toggle(isOn: $circleIcons, label: {
                        Text("Circle Icons")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: circleIcons) { _ in
                    UserDefaults.standard.set(circleIcons, forKey: "circleIcons")
                }
            }
#if os(iOS)
            DescriptionSection(desc: "Increases Performance - Uses basic tabbar even when basic mode is not enabled") {
                HStack {
                    Toggle(isOn: $usePlainNavBar, label: {
                        Text("Basic Tabbar")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: usePlainNavBar) { _ in
                    UserDefaults.standard.set(usePlainNavBar, forKey: "usePlainNavBar")
                }
            }
#endif
            DescriptionSection(desc: "Increases Performance - Disables animations") {
                HStack {
                    Toggle(isOn: $disableAnimations, label: {
                        Text("Disable Animations")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: disableAnimations) { _ in
                    UserDefaults.standard.set(disableAnimations, forKey: "disableAnimations")
                }
            }
            
            DescriptionSection(desc: "Increases Performance - Disables background") {
                HStack {
                    Toggle(isOn: $disableBackground, label: {
                        Text("Disable Background")
                    }).tintCompat(.accentColor)
                }.listRowBG().onChange(of: disableBackground) { _ in
                    UserDefaults.standard.set(disableBackground, forKey: "disableBackground")
                }
            }
        }.padding(.vertical).BGImage(appData).navigationTitle("UI Settings").onAppear() {
            lazyLoadRows = UserDefaults.standard.bool(forKey: "lazyLoadRows")
            circleIcons = UserDefaults.standard.bool(forKey: "circleIcons")
            hideFeatured = UserDefaults.standard.bool(forKey: "hideFeatured")
            usePlainNavBar = UserDefaults.standard.bool(forKey: "usePlainNavBar")
            disableAnimations = UserDefaults.standard.bool(forKey: "disableAnimations")
            disableBackground = UserDefaults.standard.bool(forKey: "disableBackground")
        }
    }
}

struct CreditsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Link(destination: URL(string: "https://github.com/Lrdsnow")!) {
                CreditView(name: "Lrdsnow", role: "Developer", icon: "lrdsnow")
            }
            Link(destination: URL(string: "https://icons8.com")!) {
                CreditView(name: "Icons8", role: "Default Icons", icon: "icons8")
            }
            Link(destination: URL(string: "https://github.com/Sileo")!) {
                CreditView(name: "Sileo", role: "APTWrapper", icon: "sileo")
            }
            Spacer()
        }.padding().BGImage(appData).navigationTitle("Credits")
    }
}

struct CreditView: View {
    let name: String
    let role: String
    let icon: String
    #if os(macOS)
    @State private var scale: CGFloat = 0
    @EnvironmentObject var appData: AppData
    #else
    let scale = UIScreen.main.bounds.height/10
    #endif
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
            Image(icon)
                .resizable()
                .scaledToFit()
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .aspectRatio(contentMode: .fit)
                .frame(width: scale, height: scale)
                .cornerRadius(20)
            
            Spacer()
            
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
        .SystemFillRoundedBG()
    }
}
#endif
