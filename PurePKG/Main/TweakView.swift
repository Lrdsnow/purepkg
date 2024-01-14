//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct TweakView: View {
    @EnvironmentObject var appData: AppData
    @State private var installed = false
    @State private var banner: URL? = nil
    let pkg: Package
    
    var body: some View {
        GeometryReader { geometry in
           List {
               if let banner = banner {
                   KFImage(banner)
                       .resizable()
                       .aspectRatio(contentMode: .fill)
                       .frame(width: UIScreen.main.bounds.width, height: 200)
                       .clipped()
                       .listRowBackground(Color.clear).listRowSeparator(.hidden)
                       .listRowInsets(EdgeInsets())
                       .padding(.bottom)
               }
                
                Section {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            KFImage(pkg.icon)
                                .resizable()
                                .onFailureImage(UIImage(named: "DisplayAppIcon"))
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .cornerRadius(15)
                                .padding(.trailing, 5)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            
                            VStack(alignment: .leading) {
                                Text(pkg.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(pkg.author)
                                    .font(.subheadline)
                                    .opacity(0.7)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button(action: {}, label: {
                                Text("Install")
                            }).buttonStyle(.borderedProminent).opacity(0.7)
                        }
                    }
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                
                TweakDepictionView(pkg: pkg, banner: $banner).listRowBackground(Color.clear).listRowSeparator(.hidden)
                
                if !(pkg.repo.url.path == "/") {
                    Section(header: Text("Repo")) {
                        RepoRow(repo: pkg.repo)
                    }.listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
                
                HStack {
                    Spacer()
                    Text("\(pkg.id) (\(pkg.version))").foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            .BGImage()
            .listStyle(.plain)
            .onAppear() {
                installed = appData.installed_pkgs.contains(where: { $0.id == pkg.id })
            }.ignoresSafeArea(.all, edges: banner != nil ? .top : [])
        }
    }
}

