//
//  SettingsView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var accent = Color.accentColor
    @State private var showBGChanger = false
    @State private var jb: String? = nil
    @State private var VerifySignature: Bool = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 100, height: 100).cornerRadius(200).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
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
                    Text("visionOS Version")
                    Spacer()
                    Text("\(appData.deviceInfo.major).\(appData.deviceInfo.minor)\(appData.deviceInfo.patch == 0 ? "" : ".\(appData.deviceInfo.minor)")\(appData.deviceInfo.build_number == "0" ? "" : " (\(appData.deviceInfo.build_number))")")
                }.listRowBG()
                HStack {
                    Text("Jailbreak Type")
                    Spacer()
                    Text(appData.jbdata.jbtype == .visionOS_rootful ? "Rootful (xros-arm64)" : "Jailed")
                }.listRowBG()
                HStack {
                    Text("Jailbreak")
                    Spacer()
                    Text(jb ?? "Unknown")
                }.listRowBG()
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("\(appData.installed_pkgs.filter { (pkg: Package) -> Bool in return pkg.section == "Tweaks"}.count)")
                }.listRowBG()
            }
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
        }
        .clearListBG()
        .BGImage(appData)
        .onAppear() { jb = Jailbreak.jailbreak() }
        .listStyleInsetGrouped()
    }
}

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
                .frame(width: 70, height: 70)
                .cornerRadius(100)
                .aspectRatio(contentMode: .fit)
            
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
