//
//  TweakDepictionView.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/12/24.
//

import Foundation
import SwiftUI

// Models
struct DepictionTabView {
    let classType: String
    let tintColor: String
    let headerImage: String
    let tabs: [DepictionTab]
}

struct DepictionTab: Identifiable {
    var id: String { tabname }
    let tabname: String
    let classType: String
    let tintColor: String?
    let views: [DepictionView]
}

protocol DepictionView {
    var id: String { get }
}

struct DepictionSubheaderView: DepictionView {
    let useBoldText: Bool
    let useBottomMargin: Bool
    let title: String
    var id: String { title }
}

struct DepictionMarkdownView: DepictionView {
    let markdown: String
    var id: String { UUID().uuidString }
}

struct DepictionSeparatorView: DepictionView {
    var id: String { UUID().uuidString }
}

struct DepictionTableTextView: DepictionView {
    let title: String
    let text: String
    var id: String { title }
}

struct DepictionTableButtonView: DepictionView {
    let title: String
    let action: String
    let openExternal: Bool
    var id: String { title }
}

struct DepictionStackView: Identifiable {
    var id: String { tabname }
    let tabname: String
    let views: [DepictionView]
}

struct DepictionButtonView: DepictionView {
    let text: String
    let action: String
    let openExternal: Bool
    let tintColor: String?
    var id: String { text }
}

struct DepictionScreenshotsView: DepictionView {
    let itemCornerRadius: CGFloat
    let itemSize: CGSize
    let screenshots: [Screenshot]
    var id: String { UUID().uuidString }
}

struct Screenshot: Identifiable {
    var id: String { accessibilityText }
    let accessibilityText: String
    let url: String
}

struct DepictionHeaderView: DepictionView {
    let title: String
    var id: String { title }
}

struct DepictionSpacerView: DepictionView {
    let spacing: CGFloat
    var id: String { UUID().uuidString }
}

struct TweakDepictionView: View {
    let pkg: Package
    @State private var json: String?

    var body: some View {
        Group {
            if let json = json,
               let data = json.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let depictions = parseDepictionTabView(from: jsonObject) {
                    ForEach(depictions.tabs) { tab in
                        Section(tab.tabname.trimmingCharacters(in: .whitespaces)) {
                            ForEach(tab.views, id: \.id) { view in
                                getView(for: view)
                            }
                        }.listRowSeparator(.hidden)
                    }
            } else {
                Text("Error parsing depiction JSON")
                    .onAppear() {
                        print(json ?? "No JSON data")
                    }
            }
        }
        .onAppear() {
            fetchJSONData(from: pkg.depiction?.absoluteString ?? "")
        }
        .padding(.bottom, 100)
        .listRowSeparator(.hidden)
    }

    private func fetchJSONData(from url: String) {
        if let url = URL(string: url) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error fetching JSON data: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.json = jsonString
                    }
                }
            }
            .resume()
        }
    }

    private func parseDepictionTabView(from dict: [String: Any]) -> DepictionTabView? {
        guard
            let classType = dict["class"] as? String,
            let headerImage = dict["headerImage"] as? String,
            let tabsData = dict["tabs"] as? [[String: Any]]
        else {
            return nil
        }

        var tabs: [DepictionTab] = []

        for tabData in tabsData {
            guard
                let tabname = tabData["tabname"] as? String,
                let tabClassType = tabData["class"] as? String,
                let viewsData = tabData["views"] as? [[String: Any]]
            else {
                continue
            }

            var views: [DepictionView] = []

            for viewData in viewsData {
                if let subheader = parseSubheaderView(from: viewData) {
                    views.append(subheader)
                } else if let markdown = parseMarkdownView(from: viewData) {
                    views.append(markdown)
                } else if viewData["class"] as? String == "DepictionSeparatorView" {
                    views.append(DepictionSeparatorView())
                } else if let tableText = parseTableTextView(from: viewData) {
                    views.append(tableText)
                } else if let tableButton = parseTableButtonView(from: viewData) {
                    views.append(tableButton)
                } else if let button = parseButtonView(from: viewData) {
                    views.append(button)
                } else if let screenshots = parseScreenshotsView(from: viewData) {
                    views.append(screenshots)
                }
                // Add more conditions for other view types as needed
            }

            let depictionTab = DepictionTab(tabname: tabname, classType: tabClassType, tintColor: nil, views: views)
            tabs.append(depictionTab)
        }

        return DepictionTabView(classType: classType, tintColor: dict["tintColor"] as? String ?? "", headerImage: headerImage, tabs: tabs)
    }
    
    private func parseButtonView(from dict: [String: Any]) -> DepictionButtonView? {
        guard
            let text = dict["text"] as? String,
            let action = dict["action"] as? String,
            let openExternal = dict["openExternal"] as? Bool
        else {
            return nil
        }

        let tintColor = dict["tintColor"] as? String

        return DepictionButtonView(text: text.trimmingCharacters(in: .whitespaces), action: action, openExternal: openExternal, tintColor: tintColor)
    }

    private func parseScreenshotsView(from dict: [String: Any]) -> DepictionScreenshotsView? {
        guard
            let itemCornerRadius = dict["itemCornerRadius"] as? CGFloat,
            let itemSizeArray = dict["itemSize"] as? [CGFloat],
            let screenshotsData = dict["screenshots"] as? [[String: Any]]
        else {
            return nil
        }

        let itemSize = CGSize(width: itemSizeArray[0], height: itemSizeArray[1])

        var screenshots: [Screenshot] = []

        for screenshotData in screenshotsData {
            guard
                let accessibilityText = screenshotData["accessibilityText"] as? String,
                let url = screenshotData["url"] as? String
            else {
                continue
            }

            let screenshot = Screenshot(accessibilityText: accessibilityText, url: url)
            screenshots.append(screenshot)
        }

        return DepictionScreenshotsView(itemCornerRadius: itemCornerRadius, itemSize: itemSize, screenshots: screenshots)
    }

    private func parseSubheaderView(from dict: [String: Any]) -> DepictionSubheaderView? {
        guard
            let useBoldText = dict["useBoldText"] as? Bool,
            let useBottomMargin = dict["useBottomMargin"] as? Bool,
            let title = dict["title"] as? String
        else {
            return nil
        }

        return DepictionSubheaderView(useBoldText: useBoldText, useBottomMargin: useBottomMargin, title: title.trimmingCharacters(in: .whitespaces))
    }

    private func parseMarkdownView(from dict: [String: Any]) -> DepictionMarkdownView? {
        guard let markdown = dict["markdown"] as? String else {
            return nil
        }

        return DepictionMarkdownView(markdown: markdown)
    }

    private func parseTableTextView(from dict: [String: Any]) -> DepictionTableTextView? {
        guard
            let title = dict["title"] as? String,
            let text = dict["text"] as? String
        else {
            return nil
        }

        return DepictionTableTextView(title: title.trimmingCharacters(in: .whitespaces), text: text.trimmingCharacters(in: .whitespaces))
    }

    private func parseTableButtonView(from dict: [String: Any]) -> DepictionTableButtonView? {
        guard
            let title = dict["title"] as? String,
            let action = dict["action"] as? String,
            let openExternal = dict["openExternal"] as? Bool
        else {
            return nil
        }

        return DepictionTableButtonView(title: title.trimmingCharacters(in: .whitespaces), action: action, openExternal: openExternal)
    }


    private func getView(for view: DepictionView) -> some View {
        switch view {
        case let subheader as DepictionSubheaderView:
            return AnyView(Text(subheader.title)
                .font(.headline)
                .padding(.top, subheader.useBottomMargin ? 0 : 8)
                .padding(.bottom, subheader.useBottomMargin ? 8 : 0))

        case let markdown as DepictionMarkdownView:
            return AnyView(Text(markdown.markdown)
                .padding(.horizontal))

        case let separator as DepictionSeparatorView:
            return AnyView(Divider())

        case let tableText as DepictionTableTextView:
            return AnyView(HStack {
                Text(tableText.title)
                    .font(.headline)
                    .padding(.trailing)
                Text(tableText.text)
                Spacer()
            }
                .padding(.horizontal))

        case let tableButton as DepictionTableButtonView:
            return AnyView(Button(action: {
                // Handle button action
            }) {
                Text(tableButton.title)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal))

        default:
            return AnyView(EmptyView())
        }
    }
}
