//
//  BrowseView.swift
//  PurePKG
//
//  Created by lrdsnow on 4/27/24.
//

import Foundation
import UIKit

class BrowseViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        title = "Browse"
        
        // NavigationBar
        let addRepoButton = UIBarButtonItem(image: UIImage(named: "plus_icon")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(addRepo))
        let settingsButton = UIBarButtonItem(image: UIImage(named: "gear_icon")?.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(settingsAction))

        navigationItem.rightBarButtonItems = [settingsButton, addRepoButton]
        //
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(RepoRowCell.self, forCellReuseIdentifier: "RepoRowCell")
        tableView.register(PlaceHolderRowCell.self, forCellReuseIdentifier: "PlaceHolderRowCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc func addRepo() {
        // Add Repo action
    }
    
    @objc func refresh() {
        refreshRepos() { _ in
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func settingsAction() {
        // Settings action
    }
}

extension BrowseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return appData.repos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceHolderRowCell", for: indexPath) as! PlaceHolderRowCell
            cell.configure(with: appData.pkgs.count, category: "", categoryTweaks: 0)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RepoRowCell", for: indexPath) as! RepoRowCell
            let repo = appData.repos[indexPath.row]
            cell.configure(with: repo)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            //let tweaksListView = TweaksListView(pageLabel: "All Tweaks", tweaksLabel: "All Tweaks", tweaks: appData.pkgs)
            //navigationController?.pushViewController(tweaksListView, animated: true)
        } else {
            //let repoView = RepoView(repo: appData.repos[indexPath.row])
            //navigationController?.pushViewController(repoView, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
