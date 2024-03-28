//
//  FeaturedView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import Kingfisher

struct FeaturedView: View {
    @EnvironmentObject var appData: AppData
    @State private var featured: [Package] = []
    @State private var otherFeatured: [Package] = []
    @State private var generatedFeatured = false
    
    var body: some View {
        CustomNavigationView {
            VStack {
                List {
                    #if !os(tvOS) && !os(macOS)
                    if featured.count >= 4 {
                        VStack {
                            HStack {
                                CustomNavigationLink {TweakView(pkg: featured[0])} label: {
                                    FeaturedAppRectangle(pkg: featured[0], flipped: false)
                                }
                                .transition(.move(edge: .leading))
                                .springAnim()
                                #if !os(macOS)
                                .padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 0.1 : 0)
                                #endif
                                CustomNavigationLink {TweakView(pkg: featured[1])} label: {
                                    FeaturedAppSquare(pkg: featured[1])
                                }.transition(.move(edge: .trailing)).springAnim()
                            }
                            HStack {
                                CustomNavigationLink {TweakView(pkg: featured[2])} label: {
                                    FeaturedAppSquare(pkg: featured[2])
                                }.transition(.move(edge: .leading)).springAnim()
                                CustomNavigationLink {TweakView(pkg: featured[3])} label: {
                                    FeaturedAppRectangle(pkg: featured[3], flipped: true)
                                }
                                .transition(.move(edge: .trailing))
                                .springAnim()
                                #if !os(macOS)
                                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 0.1 : 0)
                                #endif
                            }
                        }.listRowBackground(Color.clear).noListRowSeparator()
                    }
                    #endif
                    if otherFeatured.count >= 1 {
                        Section("Need Ideas?") {
                            ForEach(otherFeatured, id: \.id) { tweak in
                                TweakRowNavLinkWrapper(tweak: tweak).listRowBackground(Color.clear).noListRowSeparator()
                            }
                        }.springAnim()
                    }
                    Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
                }.listStyle(.plain).clearListBG()
            }.BGImage(appData).navigationTitle("Featured")
            #if os(macOS)
                .toolbar {
                    ToolbarItem {
                        Spacer()
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        HStack {
                            Spacer()
                            Button(action: {
                                generateFeatured()
                            }) {
                                Image("refresh_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            NavigationLink(destination: SettingsView()) {
                                Image("gear_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
            #else
                .navigationBarItems(trailing: HStack {
                    #if os(tvOS)
                    Button(action: {
                        generateFeatured()
                    }) {
                        Image("refresh_icon")
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                    }
                    #endif
                    gearButton
                })
            #endif
        }
            .onChange(of: appData.pkgs.count, perform: { _ in if !generatedFeatured { generateFeatured() } })
            .refreshable { generateFeatured() }
        
    }
    
    func generateFeatured() {
        featured = []
        
        let cleanPKGS = appData.pkgs.filter { $0.icon != nil && $0.name != "Unknown Tweak" && $0.desc != "Unknown Desc" && $0.id != "uwu.lrdsnow.unknown" }
        
        if cleanPKGS.isEmpty {
            return
        }
        
        #if !os(tvOS) && !os(macOS)
        let addToFeatured = { (id: String) in
            if let index = cleanPKGS.firstIndex(where: { $0.id == id }) {
                featured.append(cleanPKGS[index])
            } else {
                while true {
                    let newpkg = cleanPKGS[Int(arc4random_uniform(UInt32(cleanPKGS.count)))]
                    if !featured.contains(where: { $0.name == newpkg.name }) && !otherFeatured.contains(where: { $0.name == newpkg.name }) {
                        featured.append(newpkg)
                        break
                    }
                    if featured.count + otherFeatured.count == cleanPKGS.count {
                        break
                    }
                }
            }
        }
        
        if 4 <= cleanPKGS.count {
            addToFeatured("com.mtac.alpine")
            addToFeatured("ws.hbang.newterm2")
            addToFeatured("com.mtac.lynxtwo")
            addToFeatured("com.spark.aion")
        }
        #endif
        
        while featured.count + otherFeatured.count < cleanPKGS.count && featured.count < 8 {
            let newpkg = cleanPKGS[Int(arc4random_uniform(UInt32(cleanPKGS.count)))]
            print(newpkg.name)
            if !featured.contains(where: { $0.name == newpkg.name }) && !otherFeatured.contains(where: { $0.name == newpkg.name }) {
                otherFeatured.append(newpkg)
            }
        }
        
        print(otherFeatured.count)
        
        generatedFeatured = true
    }
    
    private var gearButton: some View {
        NavigationLink(destination: SettingsView()) {
            #if os(tvOS)
            Image("gear_icon")
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
            #else
            Image("gear_icon")
                .renderingMode(.template)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .shadow(color: .accentColor, radius: 5)
            #endif
        }
    }
}

#if !os(tvOS) && !os(macOS)
struct FeaturedAppRectangle: View {
    let pkg: Package
    let flipped: Bool
    let scale = UIScreen.main.bounds.height/7.717

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if flipped {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Spacer()
                }
                VStack {
                    Text(pkg.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(pkg.desc)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }.padding(.horizontal).padding(.horizontal)
            }
            
            KFImage(pkg.icon)
                .resizable()
                .onFailureImage(UIImage(named: "DisplayAppIcon"))
                .scaledToFit()
                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                .aspectRatio(contentMode: .fit)
                .frame(width: scale, height: scale)
                .cornerRadius(20)
            
            if !flipped {
                VStack(alignment: .center) {
                    Text(pkg.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(pkg.desc)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }.padding(.horizontal).padding(.horizontal)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Spacer()
                }
            }
        }
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(height: scale)
        .SystemFillRoundedBG()
    }
}

struct FeaturedAppSquare: View {
    let pkg: Package
    let scale = UIScreen.main.bounds.height/7.717
    
    var body: some View {
        KFImage(pkg.icon)
            .resizable()
            .onFailureImage(UIImage(named: "DisplayAppIcon"))
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            .aspectRatio(contentMode: .fit)
            .frame(width: scale, height: scale)
            .cornerRadius(20)
    }
}
#endif
