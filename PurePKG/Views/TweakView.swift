//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import SwiftUI
import NukeUI
import LocalAuthentication

struct TweakView: View {
    @EnvironmentObject var appData: AppData
    @State private var installed = false
    @State private var installedPKG: Package? = nil
    @State private var queued = false
    @State private var banner: URL? = nil
    @State private var price: String = ""
    @State private var owned = false
    @State private var showConfirmSheet = false
    @State private var reqVer: String? = nil
    let pkg: Package
    let preview: Bool
    @State private var supported: Bool? = nil
    @State private var supportedVers: String? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                if #available(iOS 14.0, tvOS 14.0, *) {
                    if let banner = banner {
                        LazyImage(url: banner) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                ProgressView()
                                    .scaledToFit()
                            }
                        }
#if !os(macOS) && !os(watchOS)
                        .frame(width: (preview ? UIScreen.main.bounds.width/1.5 : UIScreen.main.bounds.width)-40, height: preview ? 100 : 200)
#endif
                        .cornerRadius(20)
                        .clipped()
                        .listRowBackground(Color.clear)
                        .listRowSeparatorC(false)
                        .padding(.bottom)
                        .padding(.top, -40)
                    }
                }
                
                Section {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            if #available(iOS 14.0, tvOS 14.0, *) {
                                LazyImage(url: pkg.icon) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .scaledToFit()
                                    } else if state.error != nil {
                                        Image(uiImageC: UIImage(named: "DisplayAppIcon")!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .scaledToFit()
                                    } else {
                                        ProgressView()
                                            .scaledToFit()
                                    }
                                }
#if os(watchOS)
                                .frame(width: 45, height: 45)
                                .cornerRadius(100)
#else
                                .frame(width: 80, height: 80)
                                .cornerRadius(15)
#endif
                                .padding(.trailing, 5)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(pkg.name)
                                    .font(.headline.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Text(pkg.author)
                                    .font(.subheadline)
                                    .opacity(0.7)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            Spacer()
#if !os(watchOS)
                            Button(action: {
                                installPKG()
                            }, label: {
                                Text(queued ? "Queued" : installed ? "Uninstall" : price != "" ? price : "Install")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }).borderedProminentButtonC().disabled(!installed && !queued && pkg.paid && (price == "" || price == "Unavailable" || !UserDefaults.standard.bool(forKey: "usePaymentAPI"))).opacity(0.7).animation(.spring()).contextMenuC(menuItems: {
                                
                                if !queued && !installed && (!pkg.paid || owned) {
                                    ForEach(pkg.versions.sorted(by: { $1.compareVersion($0) == .orderedAscending }).removingDuplicates(), id: \.self) { ver in
                                        Button(action: {installPKG(ver)}) {
                                            Text(ver)
                                        }
                                    }
                                }
                                if installed {
                                    ForEach(pkg.versions.sorted(by: { $1.compareVersion($0) == .orderedAscending }).removingDuplicates(), id: \.self) { ver in
                                        if let installedPKG = installedPKG, installedPKG.version != ver {
                                            Button(action: {installPKG(ver)}) {
                                                Text("\(installedPKG.version.compareVersion(ver) == .orderedAscending ? "Upgrade to" : "Downgrade to") \(ver)")
                                            }
                                        }
                                    }
                                }
                                if !installed, !(pkg.repo.url.path == "/"), pkg.path != "", (!pkg.paid || owned) {
                                    let debURL = pkg.repo.url.appendingPathComponent(pkg.path)
                                    Button(action: {
                                        openURL(debURL)
                                    }) {
                                        Text("Download deb")
                                    }
                                }
                            })
#endif
                        }
                    }
                }
                .padding(.horizontal)
#if os(watchOS)
                .padding(.bottom, -30)
#endif
                
                if let supported = supported, let supportedVers = supportedVers, !supported {
                    HStack {
                        Text("Warning: This tweak only supports \(supportedVers) and may be incompatible with your current \(Device().osString) version (\(Device().pretty_version))").padding()
                    }.background( RoundedRectangle(cornerRadius: 15).foregroundColor(.red).opacity(0.4) ).padding()
                }
                
#if !os(watchOS)
                if #available(iOS 14.0, tvOS 14.0, *) {
                    if let url = pkg.depiction,
                       !preview {
                        TweakDepictionView(url: url, banner: $banner, reqVer: $reqVer).padding(.horizontal).frame(maxWidth: UIScreen.main.bounds.width, maxHeight: .infinity)
                    }
                }
#endif
                
#if !os(watchOS)
                if !(pkg.repo.url.path == "/") {
                    Section(header: Text("Repo")) {
                        HStack {
                            RepoRow(repo: pkg.repo)
                            Spacer()
                        }
                    }.padding(.horizontal)
                }
#endif
                
                HStack {
                    Spacer()
                    Text("\(pkg.id) (\(pkg.installedVersion == "" ? pkg.version : pkg.installedVersion))\(pkg.installedVersion == "" ? "" : " (\(pkg.version) available)")").foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }.listRowBackground(Color.clear).listRowSeparatorC(false)
                
#if os(watchOS)
                Button(action: {
                    installPKG()
                }, label: {
                    Text(queued ? "Queued" : installed ? "Uninstall" : "Install")
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }).borderedProminentButtonC().opacity(0.7).animation(.spring()).listRowBackground(Color.clear)
#endif
            }
        }
        .appBG()
        .listStyle(.plain)
        .onChangeC(of: appData.queued.all.count, perform: { _ in queued = appData.queued.all.contains(pkg.id) })
        .onChangeC(of: reqVer, perform: { _ in supported = pkg.supportedByDevice(reqVer); supportedVers = pkg.supportedVers(reqVer) })
        .onAppear() {
            queued = appData.queued.all.contains(pkg.id)
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
            installedPKG = appData.installed_pkgs.first(where: { $0.id == pkg.id })
            supported = pkg.supportedByDevice(reqVer)
            supportedVers = pkg.supportedVers(reqVer)
            if pkg.paid {
                PaymentAPI.getPackageInfo(pkg.id, pkg.repo, completion: { info in
                    price = info?.price ?? ""
                    owned = info?.purchased ?? false
                })
            }
        }
        .sheetC(isPresented: $showConfirmSheet) {
            #if os(iOS)
            if #available(iOS 15.0, *) {
                VStack {
                    HStack {
                        if !UserDefaults.standard.bool(forKey: "hideIcons") {
                            ZStack(alignment: .bottomTrailing) {
                                VStack(alignment: .center) {
                                    Spacer()
                                    LazyImage(url: pkg.icon) { state in
                                        if let image = state.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } else if state.error != nil {
                                            Image(uiImageC: UIImage(named: "DisplayAppIcon")!)
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            ProgressView()
                                                .scaledToFit()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    .customRadius(11)
                                    Spacer()
                                }
                                
                                if appData.installed_pkgs.contains(where: { $0.id == pkg.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.accentColor)
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text(pkg.name)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(pkg.author) · \(pkg.version) · \(pkg.id)")
                                .font(.subheadline)
                                .lineLimit(1)
                                .fixedSize(horizontal: false, vertical: true)
                                .minimumScaleFactor(0.5)
                            Text(pkg.desc)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        
                        Spacer()
                    }
                    HStack {
                        Text("Price:")
                        Spacer()
                        Text(price)
                    }
                    if let supported = supported,
                       let supportedVers = supportedVers {
                        HStack {
                            Text("Version Requirement:")
                            Spacer()
                            Text(supportedVers)
                        }.foregroundColor(supported ? .green : .red)
                    }
                    Button(action: {
                        var context = LAContext()
                        var error: NSError?
                        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                            print(error?.localizedDescription ?? "Can't evaluate policy")
                            return
                        }
                        Task {
                            do {
                                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate Purchase")
                                print("success")
                            } catch let error {
                                print(error.localizedDescription)
                                showConfirmSheet = false
                            }
                        }
                    }, label: {
                        Text("Confirm Purchase")
                    }).borderedProminentButtonC().opacity(0.7).cornerRadius(20)
                }.padding(.horizontal).padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
                    .purePresentationDetents()
                    .padding(.bottom, UIApplication.shared.windows[0].safeAreaInsets.bottom > 0 ? 0 : 15)
            }
            #endif
        }
    }
    
    func installPKG(_ version: String? = nil) {
        if (!pkg.paid || owned) {
            if !queued && !installed {
                if let version = version {
                    var diffVerPKG = pkg
                    diffVerPKG.version = version
                    appData.queued.install.append(diffVerPKG)
                } else {
                    appData.queued.install.append(pkg)
                }
                appData.queued.all.append(pkg.id)
            } else if queued {
                if let index = appData.queued.install.firstIndex(where: { $0.id == pkg.id }) {
                    appData.queued.install.remove(at: index)
                }
                if let index = appData.queued.uninstall.firstIndex(where: { $0.id == pkg.id }) {
                    appData.queued.uninstall.remove(at: index)
                }
                if let index = appData.queued.all.firstIndex(where: { $0 == pkg.id }) {
                    appData.queued.all.remove(at: index)
                }
            } else if installed {
                appData.queued.uninstall.append(pkg)
                appData.queued.all.append(pkg.id)
            }
        } else {
            showConfirmSheet = true
        }
    }
}

