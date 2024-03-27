//
//  ViewModifier.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
import TextFieldAlert

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

struct CustomNavigationLink<D: View, L: View>: View {
  @ViewBuilder var destination: () -> D
  @ViewBuilder var label: () -> L
  
  @State private var isActive = false
  
  var body: some View {
    Button {
      withAnimation {
        isActive = true
      }
    } label: {
      label()
    }
    .buttonStyle(.plain)
    .onAppear {
      isActive = false
    }
    .overlay {
      NavigationLink(isActive: $isActive) {
        destination()
      } label: {
        EmptyView()
      }
      .opacity(0)
    }
  }
}

extension View {
    @ViewBuilder
    func blurredBG() -> some View {
        if #available(iOS 16.4, tvOS 16.4, *) {
            self.presentationBackground(.ultraThinMaterial)
        } else {
            self
        }
    }
    @ViewBuilder
    func addRepoAlert(browseview: BrowseView, adding16: Binding<Bool>, adding: Binding<Bool>, newRepoURL: Binding<String>) -> some View {
        if #available(iOS 16.0, *) {
            self.alert("Add Repo", isPresented: adding16, actions: {
                TextField("URL", text: newRepoURL)
                Button("Save", action: {
                    Task {
                        await browseview.addRepo()
                    }
                })
                Button("Cancel", role: .cancel, action: {})
            })
        } else {
            self.textFieldAlert(
                title: "Add Repo",
                message: "Hit Done to add repo or cancel",
                textFields: [
                    .init(text: newRepoURL)
                ],
                actions: [
                    .init(title: "Done")
                ],
                isPresented: adding
            )
        }
    }
    @ViewBuilder
    func hide(_ bool: Bool) -> some View {
        if bool {
            self.frame(width: 0, height: 0)
        } else {
            self
        }
    }
    @ViewBuilder
    func noTabBarBG() -> some View {
        if #available(iOS 16.0, tvOS 16.0, *) {
            self.toolbar(.hidden, for: .tabBar)
        } else {
            self
        }
    }
    @ViewBuilder
    func listRowBG() -> some View {
        self.listRowBackground(Color.accentColor.opacity(0.05))
    }
    @ViewBuilder
    func clearListBG() -> some View {
        #if os(tvOS)
        self
        #else
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
        #endif
    }
    @ViewBuilder
    func listStyleInsetGrouped() -> some View {
        #if os(tvOS)
        self
        #else
        self.listStyle(.insetGrouped)
        #endif
    }
    @ViewBuilder
    func BGImage(_ appData: AppData) -> some View {
        #if targetEnvironment(macCatalyst)
        self.background(
            VStack {
                Image("macBG")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }.edgesIgnoringSafeArea(.top)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: appData.size.width)
        )
        #else
        self.background(
            VStack {
                Image("BG")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.top)
                    .edgesIgnoringSafeArea(.bottom)
            }.edgesIgnoringSafeArea(.top)
                .edgesIgnoringSafeArea(.bottom)
                .frame(width: UIScreen.main.bounds.width)
        )
        #endif
    }
    
    @ViewBuilder
    func noListRowSeparator() -> some View {
        #if os(tvOS)
        self
        #else
        self.listRowSeparator(.hidden)
        #endif
    }
    
    @ViewBuilder
    func largeNavBarTitle() -> some View {
        #if os(tvOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    @ViewBuilder
    func SystemFillRoundedBG() -> some View {
        #if os(tvOS)
        self
        #else
        self.background(Color(.systemFill).opacity(0.5).cornerRadius(20))
        #endif
    }
    
    @ViewBuilder
    func accentShadow() -> some View {
        #if os(tvOS)
        self
        #else
        self.shadow(color: .accentColor, radius: 5)
        #endif
    }
}

