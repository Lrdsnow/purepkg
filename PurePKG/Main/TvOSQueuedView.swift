//
//  TvOSQueuedView.swift
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

struct TvOSQueuedView: View {
    @EnvironmentObject var appData: AppData
    @State private var showLog = false
    @State private var editing = false
    @State private var installingQueue = false
    @State private var installLog = ""
    @State private var focused: Bool = false
    
    var body: some View {
        CustomNavigationView {
            VStack(alignment: .leading) {
                if !showLog {
                    List {
                        if !appData.queued.install.isEmpty {
                            Section(content: {
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
                                    }.padding(.horizontal)
                                }
                            }, header: {Text("Install/Upgrade").foregroundColor(.accentColor).padding(.leading).padding(.top)})
                        }
                        if !appData.queued.uninstall.isEmpty {
                            Section(content: {
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
                                    }.padding(.horizontal)
                                }
                            }, header: {Text("Uninstall").foregroundColor(.accentColor).padding(.leading).padding(.top)})
                        }
                    }
                } else {
                    Text(installLog).padding()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if !showLog {
                            if Jailbreak.type(appData) == .jailed {
                                UIApplication.shared.alert(title: ":frcoal:", body: "PurePKG is in Jailed Mode, You cannot install tweaks.")
                            } else {
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
                                completionCallback: { _, finish, refresh in log("completionCallback: \(finish)"); appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg/status"); showLog = true })
                                #endif
                            }
                        } else {
                            installingQueue = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                appData.queued = PKGQueue()
                                showLog = false
                            }
                        }
                    }, label: {
                        Spacer()
                        Text(showLog ? "Close" : "Install Tweaks").padding()
                        Spacer()
                    }).buttonStyle(.borderedProminent).tint(Color.accentColor.opacity(0.7))
                    Spacer()
                }.padding().padding(.bottom, 30)
            }.listStyle(.plain).BGImage(appData).largeNavBarTitle()
        }
    }
}
