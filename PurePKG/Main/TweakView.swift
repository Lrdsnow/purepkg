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
    @EnvironmentObject var appData: AppData
    let pkg: Package
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
                                    .font(.system(size: 20, design: .rounded))
                                    .opacity(0.7)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
                
                TweakDepictionView(pkg: pkg).listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            .BGImage()
            .listStyle(.plain)
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut) {
                        appData.queued = [Package()]
                    }
                    print("hai")
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: appData.queued.isEmpty ? 350 : 275, height: 75)
                            .foregroundColor(.accentColor.opacity(0.3))
                            .padding([.top, .leading, .bottom], 10)
                            .padding(.trailing, appData.queued.isEmpty ? 10 : 0)
                            .padding(.bottom, 20)
                    }
                }
                
                if !appData.queued.isEmpty {
                    Button(action: {
                        withAnimation(.easeOut) {
                            appData.queued = []
                        }
                        print("hai")
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 75, height: 75)
                                .foregroundColor(.accentColor.opacity(0.3))
                                .padding([.top, .trailing, .bottom], 10)
                                .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

