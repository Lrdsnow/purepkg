//
//  FeaturedView.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
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
        NavigationStack {
            VStack {
                List {
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
                .navigationBarItems(trailing: HStack {
                    Button(action: {
                        generateFeatured()
                    }) {
                        Image("refresh_icon")
                            .renderingMode(.template)
                    }
                    NavigationLink(destination: SettingsView()) {
                        Image("gear_icon")
                            .renderingMode(.template)
                    }
                })
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
        
        while featured.count + otherFeatured.count < cleanPKGS.count && featured.count < 8 {
            let newpkg = cleanPKGS[Int(arc4random_uniform(UInt32(cleanPKGS.count)))]
            if !featured.contains(where: { $0.name == newpkg.name }) && !otherFeatured.contains(where: { $0.name == newpkg.name }) {
                otherFeatured.append(newpkg)
            }
        }
        
        generatedFeatured = true
    }
}
