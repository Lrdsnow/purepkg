//
//  BrowseView.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationViewC {
            List {
                NavigationLink(destination: {
                    TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs)
                }, label: {
                    PlaceHolderRow(alltweaks: appData.pkgs.count, category: "", categoryTweaks: 0)
                }).listRowSeparatorC(false)
                SectionC("Repositories") {
                    ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.id) { repo in
                        NavigationLink(destination: {
                            RepoView(repo: repo)
                        }) {
                            RepoRow(repo: repo)
                        }.listRowSeparatorC(false)
                    }
                }
            }.navigationBarTitleC("Browse").listStyle(.plain)
            #if !os(macOS)
            .navigationBarItems(trailing: HStack {
                Button(action: {
                    refreshRepos(appData)
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                Button(action: {
                    
                }) {
                    Image(systemName: "plus")
                }
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                }
            })
            #endif
        }
    }
}
