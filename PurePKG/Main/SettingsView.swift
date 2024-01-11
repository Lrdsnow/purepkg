//
//  SettingsView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    var body: some View {
            List {
                Section {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20).padding(.trailing, 5)
                            Text("PurePKG").font(.system(size: 40, weight: .bold, design: .rounded))
                        }
                    }.padding(.leading, 5)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                Section() {
                    HStack {
                        Text("App version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")
                    }.listRowBG()
                    HStack {
                        Text("Device")
                        Spacer()
                        Text("iPhone 13 (iPhone14,5)")
                    }.listRowBG()
                    HStack {
                        Text("iOS version")
                        Spacer()
                        Text("16.6 (20G5026e)")
                    }.listRowBG()
                    HStack {
                        Text("Jailbreak type")
                        Spacer()
                        Text("RootHide")
                    }.listRowBG()
                    HStack {
                        Text("Installed tweak count")
                        Spacer()
                        Text("156")
                    }.listRowBG()
                    NavigationLink(destination: Text("Credits")) {
                        Text("Credits")
                    }.listRowBG()
                }
                Section() {
                    ColorPicker("Accent color", selection: .constant(.accent)).listRowBG()
                    Toggle(isOn: .constant(false), label: {Text("Use fluid gradient background")}).listRowBG().tint(.accent)
                    NavigationLink(destination: Text("Icons")) {
                        Text("Change Icon")
                    }.listRowBG()
                }
            }.listStyle(.insetGrouped).clearListBG().BGImage()
    }
}
