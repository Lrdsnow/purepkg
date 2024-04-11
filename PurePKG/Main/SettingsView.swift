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
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
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
#if os(macOS)
                HStack {
                    Text("Architecture")
                    Spacer()
                    Text("darwin-\(getMacOSArchitecture() ?? "unknown")")
                }
#else
                HStack {
                    Text("Jailbreak Type")
                    Spacer()
                    Text(appData.jbdata.jbtype == .rootful ? "Rootful (\(appData.jbdata.jbarch))" : appData.jbdata.jbtype == .tvOS_rootful ? "Rootful (\(appData.jbdata.jbarch))" : appData.jbdata.jbtype == .rootless ? "Rootless (\(appData.jbdata.jbarch))" : appData.jbdata.jbtype == .roothide ? "Roothide (\(appData.jbdata.jbarch))" : "Jailed")
                }.listRowBG()
#endif
#if !os(macOS)
                HStack {
                    Text("Jailbreak")
                    Spacer()
                    Text(jb ?? "Unknown")
                }.listRowBG()
#endif
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("\(appData.installed_pkgs.count)")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $VerifySignature, label: {
                        Text("Verify GPG Signature")
                    })
                }.listRowBG().onChange(of: VerifySignature) { _ in
                    UserDefaults.standard.set(VerifySignature, forKey: "checkSignature")
                }
                
                HStack {
                    Toggle(isOn: $RefreshOnStart, label: {
                        Text("Refresh Repos on Start")
                    })
                }.listRowBG().onChange(of: RefreshOnStart) { _ in
                    UserDefaults.standard.set(!RefreshOnStart, forKey: "ignoreInitRefresh")
                }
                
                #if os(iOS)
                if #available(iOS 15.0, *) {
                    HStack {
                        Toggle(isOn: $simpleMode, label: {
                            Text("Basic UI Mode")
                        })
                    }.listRowBG().onChange(of: simpleMode) { _ in
                        UserDefaults.standard.set(simpleMode, forKey: "simpleMode")
                    }
                }
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
            Section {
                ColorPicker("Accent color", selection: $accent).listRowBG().onChange(of: accent) { newValue in
                    UserDefaults.standard.set(newValue.toHex(), forKey: "accentColor")
                    appData.test.toggle()
                }.contextMenu(menuItems: {
                    Button(action: {
                        UserDefaults.standard.set("", forKey: "accentColor")
                        accent = Color(UIColor(hex: "#EBC2FF")!)
                        appData.test.toggle()
                    }, label: {Text("Clear Accent Color"); Image("trash_icon").renderingMode(.template)})
                }).listRowBG()
//                NavigationLink(destination: IconsView()) {
//                    Text("Change Icon")
//                }.listRowBG()
//                NavigationLink(destination: InAppIconsView()) {
//                    Text("Change InApp Icons")
//                }.listRowBG()
//                Button(action: {showBGChanger.toggle()}, label: {Text("Change Background")}).listRowBG()
            }
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
