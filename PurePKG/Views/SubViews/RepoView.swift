//
//  RepoView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI
import NukeUI

struct RepoView: View {
    @State var repo: Repo
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        List {
#if os(iOS)
            if let paidRepoInfo = repo.paidRepoInfo,
               appData.userInfo[repo.name] == nil,
               #available(iOS 14.0, *),
               Device().uniqueIdentifier != "" {
                SignInButton(repo: repo, paidRepoInfo: paidRepoInfo)
            }
#endif
            NavigationLink(destination: {
                TweaksListView(pageLabel: repo.name, tweaksLabel: "All Tweaks", tweaks: repo.tweaks)
            }, label: {
                PlaceHolderRow(alltweaks: repo.tweaks.count, category: "", categoryTweaks: 0)
            }).listRowSeparatorC(false).listRowBackground(Color.clear)
            SectionC("Categories") {
                ForEach(Array(Set(repo.tweaks.map { $0.section })), id: \.self) { category in
                    let categoryTweaks = repo.tweaks.filter { $0.section == category }
                    NavigationLink(destination: {
                        TweaksListView(pageLabel: repo.name, tweaksLabel: category, tweaks: categoryTweaks)
                    }, label: {
                        PlaceHolderRow(alltweaks: -1, category: category, categoryTweaks: categoryTweaks.count)
                    })
                }
            }.listRowSeparatorC(false).listRowBackground(Color.clear)
        }
        .navigationBarTitleC(repo.name)
        .listStyle(.plain)
        .appBG()
    }
}

#if os(iOS)
@available(iOS 14.0, *)
struct SignInButton: View {
    @EnvironmentObject var appData: AppData
    @StateObject private var viewModel = PaymentAPI_AuthenticationViewModel()
    let repo: Repo
    let paidRepoInfo: PaidRepoInfo
    
    var body: some View {
        Button(action: {
            viewModel.auth(repo, appData: appData)
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Tap to \(paidRepoInfo.description.lowercaseFirstLetter())").foregroundColor(Color.secondary).minimumScaleFactor(0.5).padding()
                }
                Spacer()
            }
            .background(Rectangle().foregroundColor(.accentColor.opacity(0.05)).cornerRadius(15))
        }
    }
}
#endif
