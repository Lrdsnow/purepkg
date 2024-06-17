//
//  Compat.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/19/24.
//

import Foundation
import SwiftUI
import Combine

#if os(macOS)
typealias UIColor = NSColor
typealias UIImage = NSImage
typealias UIApplication = NSWorkspace
extension NSColor {
    static var secondaryLabel: NSColor {
        return NSColor.secondaryLabelColor
    }
    static var label: NSColor {
        return NSColor.labelColor
    }
}
#elseif os(watchOS)
extension UIColor {
    static var secondaryLabel: UIColor {
        return.init(red: 0.56, green: 0.56, blue: 0.56, alpha: 1)
    }
}
#endif

struct NavigationViewC<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
#if os(macOS)
        NavigationStack {
            content
        }
#else
        NavigationView {
            content
        }.navigationViewStyle(.stack)
#endif
    }
}

extension Image {
    init(uiImageC: UIImage) {
        #if os(macOS)
        self = Image(nsImage: uiImageC)
        #else
        self = Image(uiImage: uiImageC)
        #endif
    }
}

extension View {
    @ViewBuilder
    func tintC(_ tint: Color) -> some View {
        if #available(iOS 15, tvOS 15.0, macOS 13.0, *) {
            self.tint(tint)
        } else {
            self
        }
    }
    @ViewBuilder
    func navigationBarTitleC(_ title: String) -> some View {
        #if os(iOS)
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.navigationBarTitle(title, displayMode: .large)
        } else {
            self.navigationBarTitle(title)
        }
        #elseif !os(macOS)
        self.navigationBarTitle(title)
        #else
        self
        #endif
    }
    @ViewBuilder
    func listRowSeparatorC(_ visible: Bool) -> some View {
        #if os(iOS)
        if #available(iOS 15, *) {
            self.listRowSeparator(visible ? .visible : .hidden)
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func borderedProminentButtonC() -> some View {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, *) {
            self.buttonStyle(.borderedProminent)
        } else {
            self
        }
    }
    @ViewBuilder
    func clearListBG() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func refreshableC(_ action: @escaping () -> Void) -> some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            self.refreshable { action() }
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func onOpenURLC(_ action: @escaping (URL) -> Void) -> some View {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            self.onOpenURL { url in action(url) }
        } else {
            self
        }
        #else
        self
        #endif
    }
    @ViewBuilder
    func onChangeC<T: Equatable>(of: T, perform: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.onChange(of: of, perform: perform)
        } else {
            self.onReceive(Just(of)) { (of) in
                perform(of)
            }
        }
    }
    @ViewBuilder
    func contextMenuC(@ViewBuilder menuItems: @escaping () -> some View) -> some View {
        if #available(tvOS 14.0, iOS 14.0, *) {
            self.contextMenu {
                menuItems()
            }
        } else {
            self
        }
    }
    @ViewBuilder
    func setAccentColor() -> some View {
        if let accent = UserDefaults.standard.string(forKey: "accentColor"),
           let accent_color = Color(hex: accent) {
            self.accentColor(accent_color)
        } else {
            self
        }
    }
}

struct SectionC<Content: View>: View {
    let text: String
    let content: Content

    init(_ text: String, @ViewBuilder content: () -> Content) {
        self.text = text
        self.content = content()
    }

    var body: some View {
        if #available(iOS 15, tvOS 15.0, macOS 12.0, *) {
            Section(text) {
                content
            }
        } else {
            Section(header: Text(text)) {
                content
            }
        }
    }
}

func openURL(_ url: URL) {
    #if os(watchOS)
    WKApplication.shared().openSystemURL(url)
    #else
    UIApplication.shared.open(url)
    #endif
}

#if os(iOS)
extension View {
    @ViewBuilder
    func sheetC<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        if #available(iOS 16.0, *), UIDevice.current.userInterfaceIdiom == .phone {
            self.sheet(isPresented: isPresented, content: content)
        } else {
           self._sheetC(isPresented: isPresented, content: content)
        }
    }
    @ViewBuilder
    func purePresentationDetents() -> some View {
        if #available(iOS 16.0, *), UIDevice.current.userInterfaceIdiom == .phone {
            self.presentationDetents([.height(UIApplication.shared.windows[0].safeAreaInsets.bottom > 0 ? UIScreen.main.bounds.height/4 : UIScreen.main.bounds.height/3)])
        } else {
            self
        }
    }
}

extension View {
    func _sheetC<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.background(FallbackSheetPresenter(isPresented: isPresented, content: content))
    }
}

private struct FallbackSheetPresenter<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, content: content)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        log("update")
        if isPresented && uiViewController.presentedViewController == nil {
            let hostingController = UIHostingController(rootView: content())
            hostingController.modalPresentationStyle = .pageSheet
            // let sheet = hostingController.sheetPresentationController {
            if let sheet = (hostingController as NSObject).value(forKey: "sheetPresentationController") as? NSObject {
                let height: CGFloat
                if UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0 {
                    height = UIScreen.main.bounds.height / 4
                } else {
                    height = UIScreen.main.bounds.height / 3
                }
                // let detent = UISheetPresentationController.Detent = ._detent(withIdentifier: "custom_detent", height)
                // sheet.detents = [detent]
                sheet.setValue([CustomDetent(constant: height)], forKey: "detents")
            }
            uiViewController.present(hostingController, animated: true)
        } else if !isPresented && uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }

    class Coordinator: NSObject {
        @Binding var isPresented: Bool
        let content: () -> Content

        init(isPresented: Binding<Bool>, content: @escaping () -> Content) {
            _isPresented = isPresented
            self.content = content
        }

        @objc func dismiss() {
            log("dismissed")
            isPresented = false
        }
    }
}

#endif
