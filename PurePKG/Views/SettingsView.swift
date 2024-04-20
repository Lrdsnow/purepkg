//
//  SettingsView.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/15/24.
//

import Foundation
import SwiftUI
import NukeUI

struct SettingsView: View {
    @EnvironmentObject var appData: AppData
    @State private var jb: String? = nil
    @State private var VerifySignature: Bool = true
    @State private var RefreshOnStart: Bool = true
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Image("DisplayAppIcon").resizable().scaledToFit().frame(width: 90, height: 90).cornerRadius(20).padding(.trailing, 5).shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        Text("PurePKG").font(.system(size: 40, weight: .bold, design: .rounded))
                    }
                }.padding(.leading, 5)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets()).listRowSeparatorC(false)
            Section {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")
                }.listRowBG()
                HStack {
                    Text("Device")
                    Spacer()
                    Text(appData.deviceInfo.modelIdentifier)
                }.listRowBG()
                HStack {
                    Text("\(osString()) Version")
                    Spacer()
                    Text("\(appData.deviceInfo.major).\(appData.deviceInfo.minor)\(appData.deviceInfo.patch == 0 ? "" : ".\(appData.deviceInfo.patch)")\(appData.deviceInfo.build_number == "0" ? "" : " (\(appData.deviceInfo.build_number))")")
                }.listRowBG()
#if !os(macOS)
                HStack {
                    Text("Jailbreak Type")
                    Spacer()
                    Text((appData.jbdata.jbtype == .rootful || appData.jbdata.jbtype == .tvOS_rootful) ? "Rootful" : appData.jbdata.jbtype == .rootless ? "Rootless" : appData.jbdata.jbtype == .roothide ? "Roothide" : "Jailed")
                }.listRowBG()
#endif
                HStack {
                    Text("Architecture")
                    Spacer()
                    Text("\(appData.jbdata.jbarch)")
                }.listRowBG()
#if !os(macOS)
                if let jb = jb {
                    HStack {
                        Text("Jailbreak")
                        Spacer()
                        Text(jb)
                    }.listRowBG()
                }
#endif
                HStack {
                    Text("Tweak Count")
                    Spacer()
                    Text("\(appData.installed_pkgs.count)")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $VerifySignature, label: {
                        Text("Verify GPG Signature")
                    }).tintC(.accentColor)
                }.onChange(of: VerifySignature) { _ in
                    UserDefaults.standard.set(VerifySignature, forKey: "checkSignature")
                }.listRowBG()
                
                HStack {
                    Toggle(isOn: $RefreshOnStart, label: {
                        Text("Refresh Repos on Start")
                    }).tintC(.accentColor)
                }.onChange(of: RefreshOnStart) { _ in
                    UserDefaults.standard.set(!RefreshOnStart, forKey: "ignoreInitRefresh")
                }.listRowBG()
#if os(iOS)
                NavigationLink(destination: UISettingsView()) {
                    Text("UI Settings")
                }.listRowBG()
#endif
#if !os(macOS)
                NavigationLink(destination: CreditsView()) {
                    Text("Credits")
                }.listRowBG()
#else
                SectionC("Credits") {
                    Link(destination: URL(string: "https://github.com/Lrdsnow")!) {
                        CreditView(name: "Lrdsnow", role: "Developer", icon: "lrdsnow")
                    }
                    Link(destination: URL(string: "https://icons8.com")!) {
                        CreditView(name: "Icons8", role: "Default Plumpy Icons", icon: "icons8")
                    }
                    Link(destination: URL(string: "https://github.com/Sileo")!) {
                        CreditView(name: "Sileo", role: "APTWrapper", icon: "sileo")
                    }
                }
#endif
            }
        }
        .onAppear() {
            jb = Jailbreak.jailbreak()
            VerifySignature = UserDefaults.standard.bool(forKey: "checkSignature")
        }
    }
}

#if os(macOS)
struct CreditView: View {
    let name: String
    let role: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .frame(width: 50, height: 50)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
#else
struct CreditsView: View {
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Link(destination: URL(string: "https://github.com/Lrdsnow")!) {
                CreditView(name: "Lrdsnow", role: "Developer", icon: URL(string: "https://github.com/lrdsnow.png")!)
            }
            Link(destination: URL(string: "https://github.com/Sileo")!) {
                CreditView(name: "Sileo", role: "APTWrapper", icon: URL(string: "https://github.com/sileo.png")!)
            }
            Spacer()
        }.padding().navigationBarTitleC("Credits")
    }
}

struct CreditView: View {
    let name: String
    let role: String
    let icon: URL
    #if os(macOS)
    @State private var scale: CGFloat = 0
    @EnvironmentObject var appData: AppData
    #else
    let scale = UIScreen.main.bounds.height/10
    #endif
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            
            LazyImage(url: icon) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                } else {
                    ProgressView()
                        .scaledToFit()
                }
            }
            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            .aspectRatio(contentMode: .fit)
            .frame(width: scale, height: scale)
            .cornerRadius(20)
            
            Spacer()
            
            VStack(alignment: .center) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(role)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(height: scale)
    }
}

#if os(iOS)

enum SideExpanded {
    case left
    case right
    case none
}

struct UISettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    // Sheets
    @State private var globalSheet: Bool = false
    @State private var tabbarSheet: Bool = false
    @State private var rowsSheet: Bool = false
    @State private var iconSheet: Bool = false
    // Preview & Button
    @State private var expanded: SideExpanded = .none
    @State private var isLandscape = false
    @State private var showPreview = true
    @State private var previewTab = 0
    @State private var showPackage = false
    // Global Settings
    @State private var accentColor: Color = .accentColor
    // Tabbar Settings
    @State private var customTabbar = false
    @State private var blurredTabbar = false
    @State private var iconGlow = true
    @State private var tabbarColor: Color = .black
    @State private var customIconColor = false
    @State private var iconColor: Color = .accentColor
    
    var body: some View {
        HStack {
            if expanded != .right || isLandscape {
                VStack {
                    if !isLandscape {
                        // Expandable
                        Button(action: {
                            if expanded != .left {
                                expanded = .left
                            } else {
                                expanded = .none
                            }
                        }, label: {
                            HStack {
                                if expanded == .left {
                                    Spacer()
                                }
                                Image(systemName: expanded == .left ? "chevron.left" : "chevron.right")
                                if expanded == .left {
                                    Text("Theme")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Spacer()
                                }
                            }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                        }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    }
                    // Global
                    Button(action: {
                        globalSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "globe")
                            if expanded == .left || isLandscape {
                                Text("Global")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Tabbar
                    Button(action: {
                        tabbarSheet.toggle()
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "dock.rectangle")
                            if expanded == .left || isLandscape {
                                Text("Tabbar")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Rows
                    Button(action: {
                        print("hai")
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "app.dashed")
                            if expanded == .left || isLandscape {
                                Text("Rows")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Icon
                    Button(action: {
                        print("hai")
                    }, label: {
                        HStack {
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "app.fill")
                            if expanded == .left || isLandscape {
                                Text("Icon")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .left && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                }
            }
            if showPreview {
                ContentView(tab: $previewTab, importedPackage: .constant(Package(id: "uwu.lrdsnow.purepkg.preview", name: "PurePKG", depiction: URL(string: "https://lrdsnow.github.io/purepkg/depiction.json"), icon: URL(string: "https://github.com/Lrdsnow/purepkg/blob/main/Icon.png?raw=true"))), showPackage: $showPackage, preview: true)
                    .frame(width: UIScreen.main.bounds.width/1.5, height: UIScreen.main.bounds.height/1.5)
                    .cornerRadius(25)
                    .allowsHitTesting(false)
                    .accentColor(accentColor)
                    .gesture(DragGesture(minimumDistance: 15)
                        .onEnded { value in
                            print(value)
                            print(value.translation)
                            if value.translation.width < 0 {
                                if expanded != .right {
                                    expanded = .right
                                } else {
                                    expanded = .none
                                }
                            } else if value.translation.width > 0 {
                                if expanded != .left {
                                    expanded = .left
                                } else {
                                    expanded = .none
                                }
                            }
                        })
            }
            if expanded != .left || isLandscape {
                VStack {
                    if !isLandscape {
                        // Expandable
                        Button(action: {
                            if expanded != .right {
                                expanded = .right
                            } else {
                                expanded = .none
                            }
                        }, label: {
                            HStack {
                                if expanded == .right {
                                    Spacer()
                                    Text("Preview")
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                Image(systemName: expanded == .right ? "chevron.right" : "chevron.left")
                                if expanded == .right {
                                    Spacer()
                                }
                            }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                        }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    }
                    // Refresh Preview
                    Button(action: {
                        showPreview = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                            showPreview = true
                        }
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "arrow.clockwise")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Refresh Preview" : "Refresh")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Browse Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 0
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "globe")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Browse Tab" : "Browse")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Installed Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 1
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "star")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Installed Tab" : "Install")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                    // Preview Search Tab
                    Button(action: {
                        showPackage = false
                        previewTab = 2
                    }, label: {
                        HStack {
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                            Image(systemName: "magnifyingglass")
                            if expanded == .right || isLandscape {
                                Text(isLandscape ? "Preview Search Tab" : "Search")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            if expanded == .right && !isLandscape {
                                Spacer()
                            }
                        }.padding().foregroundColor(colorScheme == .dark ? .white : .black)
                    }).background(Rectangle().foregroundColor(.accentColor.opacity(0.5)).cornerRadius(50)).padding(.vertical)
                }
            }
        }.gesture(DragGesture(minimumDistance: 15)
            .onEnded { value in
                print(value)
                print(value.translation)
                if value.translation.width < 0 {
                    if expanded != .right {
                        expanded = .right
                    } else {
                        expanded = .none
                    }
                } else if value.translation.width > 0 {
                    if expanded != .left {
                        expanded = .left
                    } else {
                        expanded = .none
                    }
                }
            })
        .navigationBarTitleC("UI Settings").animation(.spring)
            .onRotate { newOrientation in
                isLandscape = newOrientation.isLandscape
            }
            .onAppear() {
                guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
                isLandscape = scene.interfaceOrientation.isLandscape
            }
            .sheet(isPresented: $globalSheet, content: {
                NavigationView {
                    List {
                        Section(content: {
                            ColorPicker("Accent Color", selection: $accentColor)
                        }, footer: {
                            Text("Sets the global accent color")
                        })
                    }.navigationBarTitleC("Global")
                }
            })
            .sheet(isPresented: $tabbarSheet, content: {
                NavigationView {
                    List {
                        Section(content: {
                            Toggle("Custom Tabbar", isOn: $customTabbar).tintC(.accentColor)
                        }, footer: {
                            Text("Use a custom tabbar instead of the default SwiftUI one")
                        })
                        if customTabbar {
                            Section(content: {
                                Toggle("Blurred Background", isOn: $blurredTabbar).tintC(.accentColor)
                            }, footer: {
                                Text("Use a blurred background instead of a colored one")
                            })
                            if !blurredTabbar {
                                Section(content: {
                                    ColorPicker("Tabbar Color", selection: $tabbarColor)
                                }, footer: {
                                    Text("Sets the tabbar background color")
                                })
                            }
                            Section(content: {
                                Toggle("Icon Glow", isOn: $iconGlow).tintC(.accentColor)
                            }, footer: {
                                Text("Adds glow around the icons")
                            })
                            Section(content: {
                                Toggle("Custom Icon Color", isOn: $customIconColor).tintC(.accentColor)
                            }, footer: {
                                Text("Use a custom icon color")
                            })
                            if customIconColor {
                                Section(content: {
                                    ColorPicker("Icon Color", selection: $iconColor)
                                }, footer: {
                                    Text("Sets the icon color")
                                })
                            }
                        }
                    }.navigationBarTitleC("Tabbar")
                }
            })
    }
}
#endif
#endif
