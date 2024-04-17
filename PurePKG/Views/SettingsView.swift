//
//  SettingsView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI
import NukeUI

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
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        Text("PurePKG").font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                }.padding(.leading, 5)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets()).listRowSeparatorC(false)
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
                    }).tintC(.accentColor)
                }.onChange(of: VerifySignature) { _ in
                    UserDefaults.standard.set(VerifySignature, forKey: "checkSignature")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $RefreshOnStart, label: {
                        Text("Refresh Repos on Start")
                    }).tintC(.accentColor)
                }.onChange(of: RefreshOnStart) { _ in
                    UserDefaults.standard.set(!RefreshOnStart, forKey: "ignoreInitRefresh")
                }.listRowBG()
#if !os(macOS)
                NavigationLink(destination: CreditsView()) {
                    Text("Credits")
                }.listRowBG()
#else
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
#endif
            }
        }
        .onAppear() {
            jb = Jailbreak.jailbreak()
            VerifySignature = UserDefaults.standard.bool(forKey: "checkSignature")
        }
    }
}

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
                CreditView(name: "Lrdsnow", role: "Developer", icon: URL(string: "https://github.com/lrdsnow.png")!)
            }
            Link(destination: URL(string: "https://github.com/Sileo")!) {
                CreditView(name: "Sileo", role: "APTWrapper", icon: URL(string: "https://github.com/sileo.png")!)
            }
            Spacer()
        }.padding().navigationBarTitleC("Credits")
    }
}

struct CreditView: View {
    let name: String
    let role: String
    let icon: URL
    #if os(macOS)
    @State private var scale: CGFloat = 0
    @EnvironmentObject var appData: AppData
    #else
    let scale = UIScreen.main.bounds.height/10
    #endif
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
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
#endif
