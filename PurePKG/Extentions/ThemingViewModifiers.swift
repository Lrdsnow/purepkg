//
//  ThemingViewModifiers.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/21/24.
//

import Foundation
import SwiftUI
import UIKit

#if os(iOS)
extension View {
    @ViewBuilder
    func appBG() -> some View {
        if UserDefaults.standard.bool(forKey: "useCustomBackground"),
           let uiimage = UserDefaults.standard.imageForKey("customBackground") {
            self.background(VStack {
                Image(uiImage: uiimage)
            }.edgesIgnoringSafeArea(.top)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: UIScreen.main.bounds.width))
        } else {
            self
        }
    }
    @ViewBuilder
    func customRadius(_ radius: CGFloat) -> some View {
        if UserDefaults.standard.bool(forKey: "circleIcons") {
            self.cornerRadius(50)
        } else {
            self.cornerRadius(radius)
        }
    }
    @ViewBuilder
    func customTabbarBG() -> some View {
        if !UserDefaults.standard.bool(forKey: "blurredTabbar") {
            self.background((Color(hex: UserDefaults.standard.string(forKey: "tabbarColor") ?? "#000000") ?? .black).edgesIgnoringSafeArea(.all))
        } else {
            self.background(VisualEffectView(effect: UIBlurEffect(style: .dark)).edgesIgnoringSafeArea(.all))
        }
    }
}

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
#endif
