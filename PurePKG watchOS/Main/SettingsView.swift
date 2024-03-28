//
//  SettingsView.swift
//  PurePKGwatchOS
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
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 40, height: 40).cornerRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        Text("PurePKG").font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }.padding(.leading, 5).padding(.bottom, -10)
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
                    Text("watchOS Ver")
                    Spacer()
                    Text("\(appData.deviceInfo.major).\(appData.deviceInfo.minor)\(appData.deviceInfo.patch == 0 ? "" : ".\(appData.deviceInfo.minor)")")
                }.listRowBG()
                HStack {
                    Text("Arch")
                    Spacer()
                    Text(appData.jbdata.jbtype == .watchOS_rootful ? "watchos-arm" : "none (jailed)")
                }.listRowBG()
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("\(appData.installed_pkgs.filter { (pkg: Package) -> Bool in return pkg.section == "Tweaks"}.count)")
                }.listRowBG()
            }.listRowBG()
            Section("Credits") {
                Link(destination: URL(string: "https://github.com/Lrdsnow")!) {
                    CreditView(name: "Lrdsnow", role: "Developer", icon: "lrdsnow")
                }.listRowBG()
                Link(destination: URL(string: "https://icons8.com")!) {
                    CreditView(name: "Icons8", role: "Default Plumpy Icons", icon: "icons8")
                }.listRowBG()
                Link(destination: URL(string: "https://github.com/Sileo")!) {
                    CreditView(name: "Sileo", role: "APTWrapper", icon: "sileo")
                }.listRowBG()
            }.listRowBG()
        }
        .clearListBG()
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
