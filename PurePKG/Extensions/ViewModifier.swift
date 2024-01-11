//
//  ViewModifier.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import FluidGradient

struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: effect)
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

extension View {
    @ViewBuilder
    func listRowBG() -> some View {
//        self.listRowBackground(
//            VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial)).opacity(0.6).ignoresSafeArea().tint(Color(uiColor: .systemFill))
//        )
        self.listRowBackground(Color.accentColor.opacity(0.05))
    }
    @ViewBuilder
    func clearListBG() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
    @ViewBuilder
    func BGImage(_ lowPower: Bool = true) -> some View {
        self.background(
            VStack {
                if !lowPower {
                    FluidGradient(blobs: [.black, .purple, .black],
                                  highlights: [.black, .purple, .black],
                                  speed: 1.0,
                                  blur: 0.75)
                    .background(.quaternary)
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.top)
                    .edgesIgnoringSafeArea(.bottom)
                    .overlay(
                        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial)).ignoresSafeArea()
                    )
                } else {
                    Image("BG")
                        .resizable()
                        .background(.quaternary)
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.top)
                        .edgesIgnoringSafeArea(.bottom)
                }
            }.edgesIgnoringSafeArea(.top)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: UIScreen.main.bounds.width)
        )
    }
}
