//
//  RepoView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI

struct RepoView: View {
    @State var repo: Repo
    @EnvironmentObject var appData: AppData

    var body: some View {
        List {
            NavigationLink(destination: {
                TweaksListView(pageLabel: repo.name, tweaksLabel: "All Tweaks", tweaks: repo.tweaks)
            }, label: {
                PlaceHolderRow(alltweaks: repo.tweaks.count, category: "", categoryTweaks: 0)
            }).listRowSeparatorC(false)
            SectionC("Categories") {
                ForEach(Array(Set(repo.tweaks.map { $0.section })), id: \.self) { category in
                    let categoryTweaks = repo.tweaks.filter { $0.section == category }
                    NavigationLink(destination: {
                        TweaksListView(pageLabel: repo.name, tweaksLabel: category, tweaks: categoryTweaks)
                    }, label: {
                        PlaceHolderRow(alltweaks: -1, category: category, categoryTweaks: categoryTweaks.count)
                    }).listRowSeparatorC(false)
                }
            }.listRowSeparatorC(false)
        }
        .navigationBarTitleC(repo.name)
        .listStyle(.plain)
    }
}

