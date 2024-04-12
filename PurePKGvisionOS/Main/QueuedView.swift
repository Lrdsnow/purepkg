//
//  QueuedView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI

struct QueuedView: View {
    @EnvironmentObject var appData: AppData
    @State private var showLog = false
    @State private var editing = false
    @State private var installingQueue = false
    @State private var installLog = ""
    @State private var focused: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !showLog {
                        if !appData.queued.install.isEmpty {
                            Section("Install") {
                                ForEach(appData.queued.install, id: \.id) { package in
                                    VStack {
                                        HStack {
                                            TweakRow(tweak: package, focused: .constant(false))
                                            Spacer()
                                            if editing {
                                                Button(action: {
                                                    appData.queued.install.remove(at: appData.queued.install.firstIndex(where: { $0.id == package.id }) ?? -2)
                                                    appData.queued.all.remove(at: appData.queued.all.firstIndex(where: { $0 == package.id }) ?? -2)
                                                }) {
                                                    Image(systemName: "trash").shadow(color: .accentColor, radius: 5)
                                                }
                                            }
                                        }.padding(.trailing)
                                        if installingQueue {
                                            VStack(alignment: .leading) {
                                                Text(appData.queued.status[package.id]?.message ?? "Queued...")
                                                ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                    .progressViewStyle(LinearProgressViewStyle())
                                                    .frame(height: 2)
                                            }
                                            .foregroundColor(.secondary).padding(.top, 5)
                                        }
                                    }
                                }
                            }
                        }
                        if !appData.queued.uninstall.isEmpty {
                            Section("Uninstall") {
                                ForEach(appData.queued.uninstall, id: \.id) { package in
                                    VStack {
                                        HStack {
                                            TweakRow(tweak: package, focused: .constant(false))
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
                                                ProgressView(value: appData.queued.status[package.id]?.percentage ?? 0)
                                                    .progressViewStyle(LinearProgressViewStyle())
                                                    .frame(height: 2)
                                            }
                                            .foregroundColor(.secondary).padding(.top, 5)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Text(installLog)
                    }
                }.padding()
                HStack {
                    Spacer()
                    Button(action: {
                        if !showLog {
                            installingQueue = true
#if targetEnvironment(simulator)
                            installLog += "Simulator doesnt support installing tweaks..."
                            showLog = true
#else
                            APTWrapper.performOperations(installs: appData.queued.install, removals: appData.queued.uninstall, installDeps: RepoHandler.getDeps(appData.queued.install, appData),
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
                                if appData.queued.status[package]?.percentage ?? 0 <= percent {
                                    appData.queued.status[package] = installStatus(message: statusReadable, percentage: percent)
                                }
                            },
                                                         outputCallback: { output, _ in installLog += "\(output)" },
                                                         completionCallback: { _, finish, refresh in log("completionCallback: \(finish)"); appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg"); showLog = true })
#endif
                        } else {
                            installingQueue = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                appData.queued = PKGQueue()
                                showLog = false
                            }
                        }
                    }, label: {
                        Spacer()
                        Text(showLog ? "Close" : "Install Queued").padding()
                        Spacer()
                    }).buttonStyle(.borderedProminent)
                    Spacer()
                }.padding()
            }.listStyle(.plain).navigationTitle("Queued")
        }
    }
}
