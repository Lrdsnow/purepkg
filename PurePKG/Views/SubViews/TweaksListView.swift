//
//  TweaksListView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI

struct TweaksListView: View {
    let pageLabel: String
    let tweaksLabel: String
    let tweaks: [Package]
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        List {
            SectionC(tweaksLabel) {
                if !tweaks.isEmpty {
                    ForEach(tweaks, id: \.name) { tweak in
                        NavigationLink(destination: {
                            TweakView(pkg: tweak, preview: false)
                        }, label: {
                            TweakRow(tweak: tweak)
                        })
                    }
                } else {
                    Button(action: {}, label: {
                        HStack {
                            Spacer()
                            Text("No Tweaks Found")
                            Spacer()
                        }
                    })
                }
            }.listRowSeparatorC(false).listRowBackground(Color.clear)
        }.navigationBarTitleC(pageLabel).listStyle(.plain).appBG()
    }
}
