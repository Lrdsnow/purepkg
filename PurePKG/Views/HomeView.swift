//
//  Home.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Top Bar
                HStack {
                    Spacer()
                    // Apply Button
                    Button(action: {
                        
                    }, label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Apply")
                        }.padding(.horizontal).padding(.vertical, 5)
                    }).buttonStyle(.borderedProminentC).tintC(.accentColor.opacity(0.3))
                    Spacer()
                    // Respring Button
                    Button(action: {
                        
                    }, label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Respring")
                        }.padding(.horizontal).padding(.vertical, 5)
                    }).buttonStyle(.borderedProminentC).tintC(.accentColor.opacity(0.3))
                    Spacer()
                }
                // Installed List
                List {
                    
                }
            }
            .navigationBarTitleC("Installed")
        }
    }
}
