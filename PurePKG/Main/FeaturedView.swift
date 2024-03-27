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
        NavigationView {
            VStack {
                List {
                    if featured.count >= 4 {
                        #if os(tvOS)
                        #else
                        VStack {
                            HStack {
                                CustomNavigationLink {TweakView(pkg: featured[0])} label: {
                                    FeaturedAppRectangle(pkg: featured[0], flipped: false)
                                }.transition(.move(edge: .leading)).animation(.spring()).padding(.trailing, UIDevice.current.userInterfaceIdiom == .pad ? 0.1 : 0)
                                CustomNavigationLink {TweakView(pkg: featured[1])} label: {
                                    FeaturedAppSquare(pkg: featured[1])
                                }.transition(.move(edge: .trailing)).animation(.spring())
                            }
                            HStack {
                                CustomNavigationLink {TweakView(pkg: featured[2])} label: {
                                    FeaturedAppSquare(pkg: featured[2])
                                }.transition(.move(edge: .leading)).animation(.spring())
                                CustomNavigationLink {TweakView(pkg: featured[3])} label: {
                                    FeaturedAppRectangle(pkg: featured[3], flipped: true)
                                }.transition(.move(edge: .trailing)).animation(.spring()).padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 0.1 : 0)
                            }
                        }.listRowBackground(Color.clear).noListRowSeparator()
                        #endif
                        Section("Need Ideas?") {
                            ForEach(otherFeatured, id: \.id) { tweak in
                                TweakRowNavLinkWrapper(tweak: tweak).listRowBackground(Color.clear).noListRowSeparator()
                            }
                        }.animation(.spring())
                    }
                    Text("").padding(.bottom,  50).listRowBackground(Color.clear).noListRowSeparator()
                }.listStyle(.plain).clearListBG()
//                Text("Featured View")
//                NavigationLink(destination: SettingsView(), label: {Text("Settings")})
            }.BGImage(appData).navigationTitle("Featured").navigationBarItems(trailing: gearButton)
        }.navigationViewStyle(.stack).onChange(of: appData.pkgs.count, perform: { _ in if !generatedFeatured {
            featured = []
            let CleanPKGS = appData.pkgs.filter { $0.icon != nil && $0.name != "Unknown Tweak" && $0.desc != "Unknown Desc" && $0.id != "uwu.lrdsnow.unknown" }
            if CleanPKGS.count != 0 {
                if let index = CleanPKGS.firstIndex(where: { $0.id == "com.mtac.alpine" }) {
                    featured.append(CleanPKGS[index])
                } else {
                    featured.append(CleanPKGS[Int(arc4random_uniform(UInt32(CleanPKGS.count-1)))])
                }
                if let index = CleanPKGS.firstIndex(where: { $0.id == "ws.hbang.newterm2" }) {
                    featured.append(CleanPKGS[index])
                } else {
                    featured.append(CleanPKGS[Int(arc4random_uniform(UInt32(CleanPKGS.count-1)))])
                }
                if let index = CleanPKGS.firstIndex(where: { $0.id == "com.mtac.lynxtwo" }) {
                    featured.append(CleanPKGS[index])
                } else {
                    featured.append(CleanPKGS[Int(arc4random_uniform(UInt32(CleanPKGS.count-1)))])
                }
                if let index = CleanPKGS.firstIndex(where: { $0.id == "com.spark.aion" }) {
                    featured.append(CleanPKGS[index])
                } else {
                    featured.append(CleanPKGS[Int(arc4random_uniform(UInt32(CleanPKGS.count-1)))])
                }
                for _ in 1...8 {
                    otherFeatured.append(CleanPKGS[Int(arc4random_uniform(UInt32(CleanPKGS.count-1)))])
                }
                generatedFeatured = true
            }
        } })
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

struct FeaturedAppRectangle: View {
    let pkg: Package
    let flipped: Bool
    #if targetEnvironment(macCatalyst)
    @State private var scale: CGFloat = 0
    @EnvironmentObject var appData: AppData
    #else
    let scale = UIScreen.main.bounds.height/7.717
    #endif

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
        #if targetEnvironment(macCatalyst)
            .onAppear() {
                self.scale = appData.size.height/7.717
            }
        #endif
    }
}

struct FeaturedAppSquare: View {
    let pkg: Package
    #if targetEnvironment(macCatalyst)
    @State private var scale: CGFloat = 0
    @EnvironmentObject var appData: AppData
    #else
    let scale = UIScreen.main.bounds.height/7.717
    #endif
    
    var body: some View {
        KFImage(pkg.icon)
            .resizable()
            .onFailureImage(UIImage(named: "DisplayAppIcon"))
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
            .aspectRatio(contentMode: .fit)
            .frame(width: scale, height: scale)
            .cornerRadius(20)
        #if targetEnvironment(macCatalyst)
            .onAppear() {
                self.scale = appData.size.height/7.717
            }
        #endif
    }
}
