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
                }).listRowBackground(Color.clear).listRowSeparatorC(false)
                SectionC("Repositories") {
                    ForEach(appData.repos.sorted { $0.name < $1.name }, id: \.id) { repo in
                        NavigationLink(destination: {
                            RepoView(repo: repo)
                        }) {
                            RepoRow(repo: repo)
                        }.listRowBackground(Color.clear).listRowSeparatorC(false)
                    }
                }
                if let importedPackage = importedPackage,
                   showPackage == true {
                    NavigationLink(destination: TweakView(pkg: importedPackage, preview: preview), isActive: $showPackage, label: {})
                }
            }.appBG().navigationBarTitleC("Browse").listStyle(.plain).refreshableC { refreshRepos(appData) }
            #if os(macOS)
            .toolbar {
                refreshButton()
                addRepoButton()
                settingsButton()
            }
            #elseif !os(watchOS)
            .navigationBarItems(trailing: HStack {
                refreshButton()
                addRepoButton()
                settingsButton()
            })
            #endif
        }
    }
    
    struct refreshButton: View {
        @EnvironmentObject var appData: AppData
        
        var body: some View {
            Button(action: {
                refreshRepos(appData)
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    struct addRepoButton: View {
        @EnvironmentObject var appData: AppData
        
        var body: some View {
            Button(action: {
                #if !os(tvOS) && !os(watchOS)
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                let clipboardString = pasteboard.string(forType: .string) ?? ""
                #else
                let clipboardString = UIPasteboard.general.string ?? ""
                #endif
                let urlCount = clipboardString.urlCount()
                #else
                let clipboardString = ""
                let urlCount = 0
                #endif
                if urlCount > 1 {
                    let urls = clipboardString.extractURLs()
                    Task {
                        addBulkRepos(urls)
                    }
                } else if urlCount == 1, let repourl = URL(string: clipboardString) {
                    Task {
                        await addRepoByURL(repourl)
                    }
                } else {
                    showTextInputPopup("Add Repo", "Enter Repo URL", .URL, completion: { url in
                        if url != "" {
                            if let url = url {
                                if let url = URL(string: url) {
                                    RepoHandler.manageRepo(url, operation: "addRepo")
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
        }
        
        func addBulkRepos(_ urls: [URL]) {
            for url in urls {
                RepoHandler.manageRepo(url, operation: "addRepo")
            }
            refreshRepos(appData)
        }
        
        func addRepoByURL(_ url: URL) async {
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            do {
                let (_, response) = try await session.data(from: request.url!)
                let statuscode = (response as? HTTPURLResponse)?.statusCode ?? 0
                
                if statuscode == 200 {
                    RepoHandler.manageRepo(url, operation: "addRepo")
                    refreshRepos(appData)
                } else {
                    showPopup("Error", "Invalid Repo?")
                }
            } catch {
                showPopup("Error", "Invalid Repo?")
            }
        }
    }
    
    struct settingsButton: View {
        var body: some View {
            NavigationLink(destination: SettingsView()) {
                if #available(iOS 14.0, tvOS 14.0, *) {
                    Image(systemName: "gearshape.fill")
                } else {
                    Image(systemName: "gear")
                }
            }
        }
    }
}
