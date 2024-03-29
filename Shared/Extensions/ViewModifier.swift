//
//  ViewModifier.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif !os(watchOS) && !os(visionOS)
import TextFieldAlert
#endif

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

struct VisualEffectView2: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundColor = NSColor.clear
        if let esv = enclosingScrollView {
            esv.drawsBackground = false
        }
        
        headerView?.tableView?.backgroundColor = NSColor.clear
    }
}
#elseif !os(watchOS)
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
        if #available(iOS 16.4, tvOS 16.4, macOS 13.3, watchOS 10.0, *) {
            self.presentationBackground(.ultraThinMaterial)
        } else {
            self
        }
    }
    #if !os(watchOS) && !os(visionOS)
    @ViewBuilder
    func addRepoAlert(browseview: BrowseView, adding16: Binding<Bool>, adding: Binding<Bool>, newRepoURL: Binding<String>) -> some View {
        if #available(iOS 16.0, tvOS 16.0, *) {
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
            #if os(macOS)
            self
            #else
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
            #endif
        }
    }
    #endif
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
        #if os(macOS) || os(watchOS)
        self
        #else
        if #available(iOS 16.0, tvOS 16.0, *) {
            self.toolbar(.hidden, for: .tabBar)
        } else {
            self
        }
        #endif
    }
    @ViewBuilder
    func listRowBG() -> some View {
        #if os(macOS) || os(visionOS)
        self
        #elseif os(watchOS)
        self.listRowBackground(Color.accentColor.opacity(0.05).cornerRadius(8))
        #else
        self.listRowBackground(Color.accentColor.opacity(0.05))
        #endif
    }
    @ViewBuilder
    func clearListBG() -> some View {
        #if os(tvOS)
        self
        #else
        if #available(iOS 16.0, watchOS 9.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
        #endif
    }
    @ViewBuilder
    func listStyleInsetGrouped() -> some View {
        #if os(tvOS) || os(macOS) || os(watchOS)
        self
        #else
        self.listStyle(.insetGrouped)
        #endif
    }
    
    #if os(macOS)
    @ViewBuilder
    func BGBlur() -> some View {
        self.background(VisualEffectView2().ignoresSafeArea(.all))
    }
    #endif
    
    @ViewBuilder
    func BGImage(_ appData: AppData) -> some View {
        #if os(macOS) || os(visionOS)
        self
        #elseif os(tvOS)
        self.background(Color(hex:"#2d003d").frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height).edgesIgnoringSafeArea(.all))
        #elseif os(watchOS)
        self.background(
            VStack {
                Image("BG")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }.edgesIgnoringSafeArea(.all)
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
        #if os(tvOS) || os (watchOS)
        self
        #else
        self.listRowSeparator(.hidden)
        #endif
    }
    
    @ViewBuilder
    func largeNavBarTitle() -> some View {
        #if os(tvOS) || os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    @ViewBuilder
    func SystemFillRoundedBG() -> some View {
        #if os(tvOS) || os(watchOS)
        self
        #else
        if #available(macOS 14.0, *) {
            self.background(Color(.systemFill).opacity(0.5).cornerRadius(20))
        } else {
            self
        }
        #endif
    }
    
    @ViewBuilder
    func accentShadow() -> some View {
        #if os(tvOS) || os(visionOS)
        self
        #else
        self.shadow(color: .accentColor, radius: 5)
        #endif
    }
    
    @ViewBuilder
    func springAnim() -> some View {
        #if os(tvOS)
        self
        #else
        self.animation(.spring())
        #endif
    }
    
    @ViewBuilder
    func foregroundColorCustom(_ color: Color) -> some View {
        #if os(macOS)
        self
        #else
        self.foregroundColor(color)
        #endif
    }
}

