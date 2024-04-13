//
//  TweakView.swift
//  PurePKGwatchOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct TweakView: View {
    @EnvironmentObject var appData: AppData
    @State private var installed = false
    @State private var queued = false
    @State private var banner: URL? = nil
    let pkg: Package
    
    var body: some View {
        VStack {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        KFImage(pkg.icon)
                            .resizable()
                            .onFailureImage(UIImage(named: "DisplayAppIcon")!.downscaled(to: CGSize(width: 45, height: 45)))
                            .cacheOriginalImage()
                            .downsampling(size: CGSize(width: 45, height: 45))
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .cornerRadius(50)
                            .padding(.trailing, 5)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                        
                        VStack(alignment: .leading) {
                            Text(pkg.name)
                                .font(.headline.bold())
                                .lineLimit(1)
                            Text(pkg.author)
                                .font(.footnote)
                                .opacity(0.7)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }
            }
            .listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator().padding(.top, -10)
            
            HStack {
                Spacer()
                Text("\(pkg.id) (\(pkg.version))").foregroundColor(.gray).font(.footnote).lineLimit(1)
                Spacer()
            }.listRowBackground(Color.clear).noListRowSeparator().noListRowSeparator()
            
            Button(action: {
                if !queued && !installed {
                    appData.queued.install.append(pkg)
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
            }, label: {
                Text(queued ? "Queued" : installed ? "Uninstall" : "Install")
            }).buttonStyle(.borderedProminent).springAnim().tint(.accentColor.opacity(0.05)).padding(.top, 25).cornerRadius(8)
        }
        .onChange(of: appData.queued.all.count, perform: { _ in queued = appData.queued.all.contains(pkg.id) })
        .onAppear() {
            queued = appData.queued.all.contains(pkg.id)
            installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
        }
    }
}

