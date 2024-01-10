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
            Section() {
                VStack(alignment: .leading) {
                    HStack(alignment: .bottom) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20)
                        Text("PurePKG").font(.system(size: 40).bold())
                    }
                }
            }.listRowBackground(Color.clear)
            Section() {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")
                }.listRowBG()
                HStack {
                    Text("Jailbreak Type")
                    Spacer()
                    Text("None")
                }.listRowBG()
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("0")
                }.listRowBG()
            }
        }.listStyle(.insetGrouped).clearListBG().BGImage()
    }
}
