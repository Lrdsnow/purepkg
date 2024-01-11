//
//  TweakView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/11/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct TweakView: View {
    let pkg: Package
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            WebImage(url: pkg.icon)
                                .resizable()
                                .placeholder(Image("DisplayAppIcon").resizable())
                                .indicator(.progress)
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .cornerRadius(20)
                                .padding(.trailing, 5)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 1, y: 2)
                            
                            VStack(alignment: .leading) {
                                Text(pkg.name)
                                    .font(.system(size: 35, weight: .bold, design: .rounded))
                                Text(pkg.desc)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .opacity(0.7)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowBackground(Color.clear)
                Section("Description") {
                    Text(pkg.desc)
                }.listRowBackground(Color.clear)
            }
            .BGImage()
            .listStyle(.plain)
            
            Button(action: {
                print("hai")
            }) {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 75, height: 75)
                    .foregroundColor(.accentColor.opacity(0.3))
                    .padding(10)
                    .padding(.bottom, 20)
                    .padding(.trailing, 20)
            }
        }
    }
}

