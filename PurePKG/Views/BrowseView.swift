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
    @Binding var importedPackage: Package?
    @Binding var showPackage: Bool
    let preview: Bool
    
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
                if let importedPackage = importedPackage {
                    NavigationLink(destination: TweakView(pkg: importedPackage, preview: preview), isActive: $showPackage, label: {})
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
                    #if os(macOS)
                    let pasteboard = NSPasteboard.general
                    let clipboardString = pasteboard.string(forType: .string) ?? ""
                    #else
                    let clipboardString = UIPasteboard.general.string ?? ""
                    #endif
                    let urlCount = clipboardString.urlCount()
                    if urlCount > 1 {
                        let urls = clipboardString.extractURLs()
                        Task {
                            await addBulkRepos(urls)
                        }
                    } else if urlCount == 1, let repourl = URL(string: clipboardString) {
                        Task {
                            await addRepoByURL(repourl)
                        }
                    } else {
                        showTextInputPopup("Add Repo", "Enter Repo URL", .URL, completion: { url in
                            if url != "" {
                                if let url = url {
                                    if URL(string: url) != nil {
                                        RepoHandler.addRepo(url)
                                    } else {
                                        showPopup("Error", "Invalid Repo URL")
                                    }
                                }
                            }
                        })
                    }
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
    
    func addRepoByURL(_ url: URL) async {
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await session.data(from: request.url!)
            let statuscode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if statuscode == 200 {
                RepoHandler.addRepo(url.absoluteString)
                refreshRepos(appData)
            } else {
                showPopup("Error", "Invalid Repo?")
            }
        } catch {
            showPopup("Error", "Invalid Repo?")
        }
    }
    
    func addBulkRepos(_ urls: [URL]) {
        for url in urls {
            RepoHandler.addRepo(url.absoluteString)
        }
        refreshRepos(appData)
    }
}
