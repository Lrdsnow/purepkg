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
            // DepictionTabView
            case "DepictionTabView":
                // minVersion - String - The version of native depictions to use. Currently set to 0.4. - Required
                if let minVer = json["minVersion"] as? String {
                    let result = minVer.compare("0.4", options: .numeric)
                    if result == .orderedAscending {
                        log("Encountered Incompatible Depiction Version!!!")
                        break
                    }
                } else {
                    break
                }
                // headerImage - String (URL) - A URL to the image that should be displayed in the header of the package page. - Optional
                // headerImage is handled higher up
                // tintColor - String (Color) - A CSS-compatible color code to act as the package’s main accent. - Optional
                // Not Planned
                // tabs - Array of Page objects - An array of pages that the depiction should display. - Required
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
                // backgroundColor - String (Color) - A CSS-compatible color code to be the tab’s background color. - Optional
                // Not Planned
            // DepictionStackView
            case "DepictionStackView":
                // tabname - String - The name of the tab. - Required
                // tabname is handled in DepictionTabView instead
                // views - Array of View objects - The views (layout) of the tab. - Required
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
                // orientation - String (landscape/portrait) - Whether the view is portrait or landscape. - Optional
                // xPadding - Double - Padding to put above and below the element - Optional
            // DepictionAutoStackView
            case "DepictionAutoStackView":
                // horizontalSpacing - Double - How wide the view should be. - Required
                if let width = json["horizontalSpacing"] as? CGFloat {
                // views - Array of View objects - The views (layout) to change the width of. - Required
                    var views: [AnyView] = []
                    if let views_json = json["views"] as? [[String:Any]] {
                        log(views_json)
                        for view_json in views_json {
                            views.append(parse(view_json))
                        }
                        if !views.isEmpty {
                            ret = AnyView(VStack{ForEach(0..<views.count,id: \.self){index in views[index]}}.frame(width: width))
                        }
                    }
                }
            // DepictionLayerView
            case "DepictionLayerView":
                // views - Array of View objects - The views to layer on top f - Required
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
                // tintColor - String (Color) - An accent color used for links. Accepts CSS-compatible color strings. - Optional
                // Not Planned
            // DepictionHeaderView/DepictionSubheaderView/DepictionLabelView
            case "DepictionHeaderView", "DepictionSubheaderView", "DepictionLabelView":
                // fontSize - Double - The size of the label text. - Optional
                let font: Font = (Class == "DepictionSubheaderView") ? .subheadline : (Class == "DepictionSubheaderView") ? .headline : .system(size: json["fontSize"] as? CGFloat ?? 16)
                // margins - UIEdgeInsets - Adds margins around the element. Formatted {top, left, bottom, right}. - Optional
                // no.
                // useMargins - Boolean - If false, remove all margins. - Optional
                // no.
                // usePadding - Boolean - If false, remove vertical spacing. - Optional
                // no.
                // fontWeight - String - The “weight” of the text. - Optional
                let fontWeight: String? = json["fontWeight"] as? String
                // useBoldText - Boolean - Make the text bold. - Optional
                let useBoldText = json["useBoldText"] as? Bool ?? false
                // alignment - AlignEnum (Int) - Change the alignment to the left (0), center (1), or the right (2). - Optional
                let alignment = json["alignment"] as? Int ?? 0
                // useBottomMargin - Boolean - Add spacing below the header. - Optional
                let useBottomMargin = json["useBottomMargin"] as? Bool ?? false
                // title - String - The title of the header. - Required
                if let title = json["title"] as? String {
                    ret = AnyView(
                        HStack {
                            if alignment == 2 || alignment == 1 {
                                Spacer()
                            }
                            Text(title).font(font).fontWeight(fontWeight != nil ? Font.Weight(fromString: fontWeight) : useBoldText ? .bold : .regular).foregroundColor(Color(hex: json["textColor"] as? String ?? "") ?? Color(UIColor.label))
                            if alignment == 0 || alignment == 1 {
                                Spacer()
                            }
                        }
                    )
                }
            // DepictionVideoView
            // no.
            // Image
            case "DepictionImageView":
                // URL - String (URL) - The URL to the image to show. - Required
                if let url = URL(string: json["URL"] as? String ?? ""),
                // width - Double - The width of the image. - Required
                   let width = json["width"] as? CGFloat,
                // height - Double - The height of the image. - Required
                   let height = json["height"] as? CGFloat,
                // cornerRadius - Double - The roundness of the view’s corners. - Required
                   let cornerRadius = json["cornerRadius"] as? CGFloat {
                // alignment - AlignEnum (Int) - Change the alignment to the left (0), center (1), or the right (2). - Optional
                    let alignment = json["alignment"] as? Int ?? 0
                // xPadding - Double - Padding to put above and below the element - Optional
                    ret = AnyView(
                        HStack {
                            if alignment == 2 || alignment == 1 {
                                Spacer()
                            }
                            LazyImage(url: url) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ProgressView()
                                        .scaledToFit()
                                }
                            }.cornerRadius(cornerRadius).frame(width: width, height: height)
                            if alignment == 0 || alignment == 1 {
                                Spacer()
                            }
                        }
                    )
                }
            // DepictionScreenshotsView
            case "DepictionScreenshotsView":
                #if os(iOS)
                // iphone - DepictionScreenshotsView - Override class with this property if on an iPhone. - Optional
                if let iphone = json["iphone"] as? [String:Any],
                   UIDevice.current.userInterfaceIdiom == .phone {
                    ret = parse(iphone)
                    break
                }
                // ipad - DepictionScreenshotsView - Override class with this property if on an iPad. - Optional
                if let ipad = json["ipad"] as? [String:Any],
                   UIDevice.current.userInterfaceIdiom == .pad {
                    ret = parse(ipad)
                    break
                }
                #endif
                // itemCornerRadius - Double - The roundness of the view’s corners. - Required
                if let itemCornerRadius = json["itemCornerRadius"] as? CGFloat,
                // itemSize - Dimensions ({x,y}) - Change the size of the view. - Required
                   let itemSize_str = json["itemSize"] as? String,
                // screenshots - Array of Screenshot objects - The screenshots to be used. - Required
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
            // DepictionMarkdownView
            case "DepictionMarkdownView":
                // markdown - String (Markdown) - The text to be rendered as Markdown (or HTML) - Required
                if let markdown = json["markdown"] as? String {
                    ret = AnyView(DepictionMarkdownView(markdown: markdown))
                }
                // more stuff i probably wont add:
                // useSpacing - Boolean - If false, remove vertical spacing. - Optional
                // useMargins - Boolean - If false, remove all margins. - Optional
                // useRawFormat - Boolean - If true, markdown will accept basic HTML instead of Markdown. - Optional
                // tintColor - String (Color) - An accent color used for links. Accepts CSS-compatible color strings. - Optional
                //
            // DepictionTableTextView
            case "DepictionTableTextView":
                // title - String - The title of the row. - Required
                if let title = json["title"] as? String,
                // text - String - The text to be displayed next to the title. - Required
                   let text = json["text"] as? String{
                    ret = AnyView(HStack{Text(title);Spacer();Text(text)})
                }
            // DepictionTableButtonView/DepictionButtonView
            case "DepictionTableButtonView", "DepictionButtonView":
                // title - String - The button’s label. - Required
                if let title = json["title"] as? String,
                // action - String (URL) - The URL to open when the button is pressed. - Required
                   let action = json["action"] as? String {
                    if action.hasPrefix("depiction-") {
                        if let url = URL(string: action.replacingOccurrences(of: "depiction-", with: "")) {
                            ret = AnyView(NavigationLink(destination: TweakDepictionView(url: url, banner: .constant(nil)), label: {
                                Text(title)
                            }))
                        } else {
                            ret = AnyView(Button(action: {
                                openURL(url)
                            }, label: {
                                Text(title)
                            }))
                        }
                    }
                }
                // im probably not gonna add these:
                // backupAction - String (URL) - An alternate action to try if the action is not supported. - Optional
                // openExternal - Double - Set whether to open the URL in an external app. - Optional
                // yPadding - Double - Padding to put above and below the button. - Optional
                // tintColor - String (Color) - The color of the button text. Accepts CSS-compatible color strings. - Optional
                // view - View object - A View to replace the button text with. Left-top-aligned. - Optional
                //
            // DepictionSeparatorView
            case "DepictionSeparatorView":
                ret = AnyView(Divider())
            // DepictionSpacerView
            case "DepictionSpacerView":
                // spacing - Double - How high the spacer should be. - Required
                if let spacing = json["spacing"] as? CGFloat {
                    ret = AnyView(Spacer(minLength: spacing))
                }
            // DepictionReviewView
            // Why does this exist? whos out there creating REAL rating for Tweaks 💀
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

// MARK: - Extra Stuff

@available(iOS 14.0, tvOS 14.0, *)
struct CustomTabView: View {
    let tabs: [(String, AnyView)]
    @State private var page = 0
    @State private var rect: CGRect = .zero
    
    var body: some View {
        VStack {
            #if os(macOS)
            TabView(selection: $page) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    tabs[index].1.tabItem { Text(tabs[index].0) }
                }
            }
            #else
            if tabs.count >= 2 {
                Picker("Tab", selection: $page) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Text(tabs[index].0).tag(index)
                    }
                }.pickerStyle(.segmented)
            }
            ForEach(0..<tabs.count, id: \.self) { index in
                if page == index {
                    tabs[index].1.tag(index)
                }
            }
            #endif
        }
    }
}

extension Font.Weight {
    init?(fromString: String?) {
        switch fromString {
        case "black":
            self = .black
        case "bold":
            self = .bold
        case "heavy":
            self = .heavy
        case "light":
            self = .light
        case "medium":
            self = .medium
        case "semibold":
            self = .semibold
        case "regular":
            self = .regular
        case "normal":
            self = .regular
        case "thin":
            self = .thin
        case "ultralight":
            self = .ultraLight
        default:
            self = .regular
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
