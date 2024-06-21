//
//  QueuedView.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/26/24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

struct QueueView: View {
    @EnvironmentObject var appData: AppData
    @State private var showLog = false
    @State private var editing = false
    @State private var installingQueue = false
    @State private var installLog = ""
    @State private var focused: Bool = false
    @State private var deps: [Package] = []
    @State private var toInstall: [Package] = []
    
    var body: some View {
        NavigationViewC {
            VStack(alignment: .leading) {
                if !showLog {
                    List {
                        if appData.queued.all.isEmpty {
                            Text("No Queued Tweaks")
                        } else {
                        if !appData.queued.install.isEmpty {
                            Text("Install/Upgrade").foregroundColor(.accentColor)
                            ForEach(toInstall, id: \.id) { package in
                                VStack {
                                    HStack {
                                        TweakRow(tweak: package)
                                            .padding(.leading, (deps.contains(where: { $0.id == package.id }) && !appData.queued.install.contains(where: { $0.id == package.id })) ? 10 : 0)
                                        Spacer()
                                        if editing && !(deps.contains(where: { $0.id == package.id }) && !appData.queued.install.contains(where: { $0.id == package.id }))  {
                                            Button(action: {
                                                appData.queued.install.remove(at: appData.queued.install.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                refresh()
                                            }) {
                                                Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                            }
                                        }
                                    }.padding(.trailing)
                                    if installingQueue {
                                        VStack(alignment: .leading) {
                                            Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                            if #available(iOS 14.0, tvOS 14.0, *) {
                                                ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                    .progressViewStyle(LinearProgressViewStyle())
                                                    .frame(height: 2)
                                            }
                                        }
                                        .foregroundColor(.secondary).padding(.top, 5)
                                    }
                                }.padding(.horizontal)
                            }.onDelete(perform: { indexSet in
                                for index in indexSet {
                                    let package = toInstall[index]
                                    appData.queued.install.remove(at: appData.queued.install.firstIndex(where: { $0.id == package.id }) ?? -1)
                                    appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -1)
                                    refresh()
                                }
                            })
                        }
                        if !appData.queued.uninstall.isEmpty {
                            Text("Uninstall").foregroundColor(.accentColor)
                                ForEach(appData.queued.uninstall, id: \.id) { package in
                                    VStack {
                                        HStack {
                                            TweakRow(tweak: package)
                                            Spacer()
                                            if editing {
                                                Button(action: {
                                                    appData.queued.uninstall.remove(at: appData.queued.uninstall.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                    appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                }) {
                                                    Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                                }
                                            }
                                        }.padding(.trailing)
                                        if installingQueue {
                                            VStack(alignment: .leading) {
                                                Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                                if #available(iOS 14.0, tvOS 14.0, *) {
                                                    ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                        .progressViewStyle(LinearProgressViewStyle())
                                                        .frame(height: 2)
                                                }
                                            }
                                            .foregroundColor(.secondary).padding(.top, 5)
                                        }
                                    }.padding(.horizontal)
                                }.onDelete(perform: { indexSet in
                                    for index in indexSet {
                                        let package = appData.queued.uninstall[index]
                                        appData.queued.uninstall.remove(at: appData.queued.uninstall.firstIndex(where: { $0.id == package.id }) ?? -2)
                                        appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                        refresh()
                                    }
                                })
                        }
                    }
                    }
                } else {
                    Text(installLog).padding()
                }
                Spacer()
                InstallQueuedButton(showLog: $showLog, installingQueue: $installingQueue, installLog: $installLog, deps: $deps)
                #if !os(watchOS)
                    .padding().padding(.bottom, 30)
                #endif
            }.appBG().listStyle(.plain).onAppear() {
                refresh()
            }
            #if os(iOS)
                .navigationBarTitleC("Queued")
            #endif
            #if !os(macOS) && !os(watchOS)
                .navigationBarItems(trailing: HStack {
                    if !appData.queued.all.isEmpty {
                        Button(action: {
                            editing.toggle()
                        }, label: {
                            Image(systemName: "pencil")
                        })
                    }
                })
            #endif
        }
    }
    
    private func refresh() {
        deps = RepoHandler.getDeps(appData.queued.install, appData)
        toInstall = appData.queued.install + deps.filter { dep in appData.queued.install.first(where: { $0.id == dep.id }) == nil }
    }
}

struct InstallQueuedButton: View {
    @EnvironmentObject var appData: AppData
    @Binding var showLog: Bool
    @Binding var installingQueue: Bool
    @Binding var installLog: String
    @Binding var deps: [Package]
    @State var buttonText = "Perform Actions"
    @State var done = false
    
    var body: some View {
        HStack {
            Spacer()
            if done && !showLog && !appData.queued.all.isEmpty {
                Button(action: {
                    showLog = true
                }, label: {
                    Image(systemName: "doc.text.below.ecg").padding().font(.subheadline)
                }).padding(.trailing, 3).borderedProminentButtonC().tintC(Color.accentColor.opacity(0.7))
            }
            Button(action: {
                if done {
                    installingQueue = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        appData.queued = PKGQueue()
                        showLog = false
                    }
                } else {
                    if Jailbreak().type == .jailed {
                        showPopup("bruh", "PurePKG is in demo mode, you cannot install tweaks")
                    } else {
                        installingQueue = true
                        installLog = ""
#if targetEnvironment(simulator)
                        installLog += "Simulator doesnt support installing tweaks..."
                        done = true
                        buttonText = "Close"
#if os(watchOS)
                        showLog = true
#endif
#else
                        let paid_pkgs = appData.queued.install.filter({ $0.paid == true })
                        if !paid_pkgs.isEmpty  {
                            appData.queued.install.removeAll(where: { $0.paid == true })
                            for paid_pkg in paid_pkgs {
                                if let url_str = paid_pkg.debPath,
                                   let url = URL(string: url_str) {
                                    let task = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
                                        if let tempURL = tempURL {
                                            var temp_pkg = paid_pkg
                                            temp_pkg.debPath = tempURL.path
                                            appData.queued.install.append(temp_pkg)
                                        } else if let error = error {
                                            appData.queued.status[paid_pkg.id] = installStatus(message: "Failed to download package", percentage: 1.0)
                                        }
                                    }
                                    
                                    let progressObservation = task.progress.observe(\.fractionCompleted) { (progress, _) in
                                        DispatchQueue.main.async {
                                            appData.queued.status[paid_pkg.id] = installStatus(message: "Downloading...", percentage: progress.fractionCompleted)
                                        }
                                    }
                                    
                                    task.resume()
                                }
                            }
                        }
                        APTWrapper.performOperations(installs: appData.queued.install, removals: appData.queued.uninstall, installDeps: deps,
                                                     progressCallback: { _, statusValid, statusReadable, package in
                            log("STATUSINFO:\nStatusValid: \(statusValid)\nStatusReadable: \(statusReadable)\nPackage: \(package)")
                            var percent: Double = 0
                            if statusReadable.contains("Installed") {
                                percent = 1
                            } else if statusReadable.contains("Configuring") {
                                percent = 0.7
                            } else if statusReadable.contains("Preparing") {
                                percent = 0.4
                            }
                            DispatchQueue.main.async {
                                if appData.queued.status[package]?.percentage ?? 0 <= percent {
                                    appData.queued.status[package] = installStatus(message: statusReadable, percentage: percent)
                                }
                            }
                        },
                                                     outputCallback: { output, _ in installLog += "\(output)" },
                                                     completionCallback: { _, finish, refresh in
                            log("completionCallback: \(finish)");
                            refreshRepos(appData)
                            done = true;
                            buttonText = "Close"
#if os(watchOS)
                            showLog = true
#endif
                        })
#endif
                    }
                }
            }, label: {
                Spacer()
                Text(buttonText)
#if !os(watchOS)
                    .padding()
#endif
                Spacer()
            }).borderedProminentButtonC().tintC(Color.accentColor.opacity(0.7)).disabled(appData.queued.all.isEmpty || installingQueue)
            Spacer()
        }
    }
}
