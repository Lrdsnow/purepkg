//
//  TweakDepictionView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/12/24.
//

#if !os(watchOS)
import SwiftUI
import Down
#if canImport(SafariServices) && canImport(WebKit)
import SafariServices
import WebKit
#endif
import NukeUI

// MARK: - Main View

@available(iOS 14.0, tvOS 14.0, *)
struct TweakDepictionView: View {
    let url: URL
    @Binding var banner: URL?
    @State private var view = AnyView(ProgressView())
    @State private var fetched = false
    
    var body: some View {
        view.onAppear() {
            fetch()
        }
    }
    
    private func fetch() {
        if !fetched {
            fetched = true
            
            if url.pathExtension.contains("json") {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else {
                        log("Error fetching JSON data: \(error?.localizedDescription ?? "Unknown error")")
                        view = AnyView(EmptyView())
                        return
                    }
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            if let dict = dict {
                                if let bannerImage = dict["headerImage"] as? String {
                                    self.banner = URL(string: bannerImage)
                                }
                                view = parse(dict)
                            } else {
                                view = AnyView(EmptyView())
                                return
                            }
                        }
                    }
                }
                .resume()
            } else {
#if canImport(SafariServices) && canImport(WebKit)
                view = AnyView(WebView(url: url))
#else
                view = AnyView(EmptyView())
#endif
            }
        }
    }
    
    private func parse(_ json: [String:Any]) -> AnyView {
        var ret = AnyView(EmptyView())
        if let Class = json["class"] as? String {
            switch Class {
            // Tab View
            case "DepictionTabView":
                var tabs: [(String,AnyView)] = []
                if let tabs_json = json["tabs"] as? [[String:Any]] {
                    for tab_json in tabs_json {
                        let tab = parse(tab_json)
                        if let tab_name = tab_json["tabname"] as? String {
                            tabs.append((tab_name, tab))
                        }
                    }
                    if !tabs.isEmpty {
                        ret = AnyView(CustomTabView(tabs: tabs))
                    }
                }
            // VStack
            case "DepictionStackView":
                var views: [AnyView] = []
                if let views_json = json["views"] as? [[String:Any]] {
                    log(views_json)
                    for view_json in views_json {
                        views.append(parse(view_json))
                    }
                    if !views.isEmpty {
                        ret = AnyView(VStack{ForEach(0..<views.count,id: \.self){index in views[index]}})
                    }
                }
            // ZStack
            case "DepictionLayerView":
                var views: [AnyView] = []
                if let views_json = json["views"] as? [[String:Any]] {
                    log(views_json)
                    for view_json in views_json {
                        views.append(parse(view_json))
                    }
                    if !views.isEmpty {
                        ret = AnyView(ZStack{ForEach(0..<views.count,id: \.self){index in views[index]}})
                    }
                }
            // Screenshots
            case "DepictionScreenshotsView":
                if let itemCornerRadius = json["itemCornerRadius"] as? CGFloat,
                   let itemSize_str = json["itemSize"] as? String,
                   let screenshots = json["screenshots"] as? [[String:String]] {
                    let itemSize = NSCoder.cgSize(for: itemSize_str)
                    ret = AnyView(ScrollView(.horizontal) {
                        HStack {
                            ForEach(0..<screenshots.count,id: \.self) {index in
                                let screenshot = screenshots[index]
                                LazyImage(url: URL(string:screenshot["url"] ?? "")) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ProgressView()
                                            .scaledToFit()
                                    }
                                }.cornerRadius(itemCornerRadius).frame(width: itemSize.width, height: itemSize.height)
                            }
                        }
                    }.frame(height: itemSize.height))
                }
            // Image
            case "DepictionImageView":
                if let url = URL(string: json["URL"] as? String ?? ""),
                   let width = json["width"] as? CGFloat,
                   let height = json["height"] as? CGFloat,
                   let cornerRadius = json["cornerRadius"] as? CGFloat {
                    ret = AnyView(LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            ProgressView()
                                .scaledToFit()
                        }
                    }.cornerRadius(cornerRadius).frame(width: width, height: height))
                }
            // Divider
            case "DepictionSeparatorView":
                ret = AnyView(Divider())
            // Spacer
            case "DepictionSpacerView":
                if let spacing = json["spacing"] as? CGFloat {
                    ret = AnyView(Spacer(minLength: spacing))
                } else {
                    ret = AnyView(Spacer())
                }
            // Table Text
            case "DepictionTableTextView":
                if let title = json["title"] as? String,
                   let text = json["text"] as? String{
                    ret = AnyView(HStack{Text(title);Spacer();Text(text)})
                }
            // Sub Headline
            case "DepictionSubheaderView":
                if let title = json["title"] as? String {
                    ret = AnyView(Text(title).font(.subheadline).fontWeight((json["useBoldText"] as? Bool ?? true) ? .bold : .regular))
                }
            // Headline
            case "DepictionHeaderView":
                if let title = json["title"] as? String {
                    ret = AnyView(Text(title).font(.headline).fontWeight((json["useBoldText"] as? Bool ?? true) ? .bold : .regular))
                }
            // Label
            case "DepictionLabelView":
                if let text = json["text"] as? String {
                    let alignment = json["alignment"] as? Int ?? 0
                    ret = AnyView(
                        HStack {
                            if alignment == 2 || alignment == 1 {
                                Spacer()
                            }
                            Text(text)
                                .font(.system(size: json["fontSize"] as? CGFloat ?? 16))
                                .foregroundColor(Color(hex: json["textColor"] as? String ?? "") ?? Color(UIColor.label))
                            if alignment == 0 || alignment == 1 {
                                Spacer()
                            }
                        }
                    )
                }
            // Markdown
            case "DepictionMarkdownView":
                if let markdown = json["markdown"] as? String {
                    ret = AnyView(DepictionMarkdownView(markdown: markdown))
                }
            default:
                break
            }
        }
        return ret
    }
}

// MARK: - Markdown Stuff

struct DepictionMarkdownView: View {
    @ObservedObject var viewModel: DepictionMarkdownViewModel

    init(markdown: String) {
        viewModel = DepictionMarkdownViewModel(markdown: markdown)
    }

    var body: some View {
        ScrollView {
            if let attributedString = viewModel.attributedString {
                Text(attributedString.string)
                    .padding(16)
            } else {
                if #available(iOS 14.0, tvOS 14.0, *) {
                    ProgressView()
                        .padding(16)
                } else {
                    Text("...")
                }
            }
        }
        .background(Color.clear)
        .onAppear {
            viewModel.reloadMarkdown()
        }
    }
}

public struct DepictionFontCollection: FontCollection {
    public var heading1 = DownFont.boldSystemFont(ofSize: 28)
    public var heading2 = DownFont.boldSystemFont(ofSize: 24)
    public var heading3 = DownFont.boldSystemFont(ofSize: 18)
    public var heading4 = DownFont.boldSystemFont(ofSize: 16)
    public var heading5 = DownFont.boldSystemFont(ofSize: 14)
    public var heading6 = DownFont.boldSystemFont(ofSize: 12)
    public var body = DownFont.systemFont(ofSize: 16)
    public var code = DownFont(name: "menlo", size: 16) ?? .systemFont(ofSize: 16)
    public var listItemPrefix = DownFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
}

public struct DepictionColorCollection: ColorCollection {
    public var heading1 = DownColor.label
    public var heading2 = DownColor.label
    public var heading3 = DownColor.label
    public var heading4 = DownColor.label
    public var heading5 = DownColor.label
    public var heading6 = DownColor.label
    public var body = DownColor.label
    public var code = DownColor.label
    public var link = DownColor.systemBlue
    public var quote = DownColor.darkGray
    public var quoteStripe = DownColor.darkGray
    public var thematicBreak = DownColor(white: 0.9, alpha: 1)
    public var listItemPrefix = DownColor.lightGray
    public var codeBlockBackground = DownColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
}

class DepictionMarkdownViewModel: ObservableObject {
    @Published var attributedString: NSAttributedString?
    var htmlString: String = ""
    
    init(markdown: String) {
        self.htmlString = markdown
        reloadMarkdown()
    }

    func reloadMarkdown() {
        var red = CGFloat(0)
        var green = CGFloat(0)
        var blue = CGFloat(0)
        var alpha = CGFloat(0)
        UIColor.accent.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        red *= 255
        green *= 255
        blue *= 255

        let down = Down(markdownString: htmlString)
        var config = DownStylerConfiguration()
        var colors = DepictionColorCollection()
        colors.link = .accent
        config.colors = colors
        config.fonts = DepictionFontCollection()
        let styler = DownStyler(configuration: config)
        if let attributedString = try? down.toAttributedString(.default, styler: styler) {
            self.attributedString = attributedString
        }
    }

    func depictionHeight(width: CGFloat) -> CGFloat {
        guard let attributedString = attributedString else {
            return 0
        }

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let targetSize = CGSize(width: width - 32, height: CGFloat.greatestFiniteMagnitude)
        let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attributedString.length), nil, targetSize, nil)
        return fitSize.height + 33
    }
}

// MARK: - Extra Views

@available(iOS 14.0, tvOS 14.0, *)
struct CustomTabView: View {
    let tabs: [(String, AnyView)]
    @State private var page = 0
    @State private var rect: CGRect = .zero
    
    var body: some View {
        VStack {
            #if !os(macOS)
            Picker("Tab", selection: $page) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Text(tabs[index].0).tag(index)
                }
            }.pickerStyle(.segmented)
            #endif
            ForEach(0..<tabs.count, id: \.self) { index in
                if page == index {
#if os(macOS)
                    tabs[index].1.tabItem { Text(tabs[index].0) }
#else
                    tabs[index].1.tag(index)
#endif
                }
            }
        }
    }
}

// MARK: - WebView stuff

#if os(macOS)
struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.black.cgColor
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}
#elseif !os(tvOS)
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.black
        webView.scrollView.backgroundColor = UIColor.black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
     let request = URLRequest(url: url)
     uiView.load(request)
    }

}
#endif

//

#endif
