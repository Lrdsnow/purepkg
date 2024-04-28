//
//  BrowseRows.swift
//  PurePKG
//
//  Created by lrdsnow on 4/27/24.
//

import Foundation
import UIKit
import SDWebImage

class PlaceHolderRowCell: UITableViewCell {
    var allTweaks: Int
    var category: String
    var categoryTweaks: Int
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, allTweaks: Int, category: String, categoryTweaks: Int) {
        self.allTweaks = allTweaks
        self.category = category
        self.categoryTweaks = categoryTweaks
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.allTweaks = 0
        self.category = ""
        self.categoryTweaks = 0
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    func configure(with allTweaks: Int, category: String, categoryTweaks: Int) {
        self.allTweaks = allTweaks
        self.category = category
        self.categoryTweaks = categoryTweaks
        hStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        vStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        iconImageView.image = nil
        setupUI()
    }
    
    private let hStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init(allTweaks: Int, category: String, categoryTweaks: Int) {
        self.allTweaks = allTweaks
        self.category = category
        self.categoryTweaks = categoryTweaks
        super.init(style: .default, reuseIdentifier: nil)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
//        if !UserDefaults.standard.bool(forKey: "hideIcons") {
//            let iconContainer = UIView()
//            iconContainer.addSubview(iconImageView)
//            iconImageView.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
//                iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
//                iconImageView.widthAnchor.constraint(equalToConstant: 50),
//                iconImageView.heightAnchor.constraint(equalToConstant: 50)
//            ])
//            
//            hStack.addArrangedSubview(iconContainer)
//        }
        
        hStack.addArrangedSubview(vStack)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.text = allTweaks != -1 ? "All Tweaks" : category
        if #available(iOS 13.0, *) {} else { titleLabel.textColor = .white }
        vStack.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.5
        subtitleLabel.text = allTweaks != -1 ? "\(allTweaks) Tweaks Total" : "\(categoryTweaks) Tweaks"
        if #available(iOS 13.0, *) {} else { subtitleLabel.textColor = .white }
        vStack.addArrangedSubview(subtitleLabel)
    }
}

class RepoRowCell: UITableViewCell {
    var repo: Repo
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.repo = Repo()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, repo: Repo) {
        self.repo = repo
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    func configure(with repo: Repo) {
        self.repo = repo
        hStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        vStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        iconImageView.image = nil
        setupUI()
    }
    
    private let hStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init(repo: Repo) {
        self.repo = repo
        super.init(style: .default, reuseIdentifier: nil)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
//
//        if !UserDefaults.standard.bool(forKey: "hideIcons") {
//            let iconContainer = UIView()
//            iconContainer.addSubview(iconImageView)
//            iconImageView.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
//                iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
//                iconImageView.widthAnchor.constraint(equalToConstant: 50),
//                iconImageView.heightAnchor.constraint(equalToConstant: 50)
//            ])
//
//            hStack.addArrangedSubview(iconContainer)
//        }
        
        hStack.addArrangedSubview(vStack)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.text = repo.name
        if #available(iOS 13.0, *) {} else { titleLabel.textColor = .white }
        vStack.addArrangedSubview(titleLabel)
        
        let urlString = repo.url.absoluteString.replacingOccurrences(of: "/./", with: "").replacingOccurrences(of: "refreshing/", with: "").removeSubstringIfExists("/dists/")
        let detailText = "\(urlString)\(repo.component != "main" ? " (\(repo.component))" : "")"
        let detailLabel = UILabel()
        detailLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        detailLabel.numberOfLines = 1
        detailLabel.adjustsFontSizeToFitWidth = true
        detailLabel.minimumScaleFactor = 0.5
        detailLabel.text = detailText
        if #available(iOS 13.0, *) {} else { detailLabel.textColor = .white }
        vStack.addArrangedSubview(detailLabel)
        
        if repo.error != nil {
            let errorLabel = UILabel()
            errorLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
            errorLabel.numberOfLines = 1
            errorLabel.adjustsFontSizeToFitWidth = true
            errorLabel.minimumScaleFactor = 0.5
            errorLabel.text = repo.error ?? ""
            if #available(iOS 13.0, *) {} else { errorLabel.textColor = .white }
            vStack.addArrangedSubview(errorLabel)
        }
    }
    
    func presentContextMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let copyAction = UIAlertAction(title: "Copy Repo URL", style: .default) { _ in
            #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(repo.url.absoluteString, forType: .string)
            #else
            let pasteboard = UIPasteboard.general
            pasteboard.string = self.repo.url.absoluteString
            #endif
        }
        
        let deleteAction = UIAlertAction(title: "Delete Repo", style: .destructive) { _ in
            RepoHandler.removeRepo(self.repo.url)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(copyAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = topViewController.view
                popoverController.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
