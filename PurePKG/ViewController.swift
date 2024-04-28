//
//  ViewController.swift
//  PurePKG
//
//  Created by lrdsnow on 4/26/24.
//

import UIKit

var appData = AppData()

class ViewController: UIViewController {
    var browseViewController: UIViewController!
    var installedViewController: UIViewController!
    var searchViewController: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appData.jbdata.jbtype = Jailbreak.type(appData)
        appData.jbdata.jbarch = Jailbreak.arch(appData)
        appData.jbdata.jbroot = Jailbreak.path(appData)
        appData.deviceInfo = getDeviceInfo()
        appData.installed_pkgs = RepoHandler.getInstalledTweaks(Jailbreak.path(appData)+"/Library/dpkg")
        appData.repos = RepoHandler.getCachedRepos()
        appData.pkgs = appData.repos.flatMap { $0.tweaks }
        if !UserDefaults.standard.bool(forKey: "ignoreInitRefresh") {
            refreshRepos() { _ in }
        }
        
        browseViewController = UINavigationController(rootViewController: SettingsViewController())
        browseViewController.title = "Browse"
        browseViewController.tabBarItem = UITabBarItem(title: "Browse", image: UIImage(named: "browse_icon"), tag: 0)
        
        installedViewController = UINavigationController(rootViewController: InstalledViewController())
        installedViewController.title = "Installed"
        installedViewController.tabBarItem = UITabBarItem(title: "Installed", image: UIImage(named: "home_icon"), tag: 1)
        
        searchViewController = UINavigationController(rootViewController: SearchViewController())
        searchViewController.title = "Search"
        searchViewController.tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "search_icon"), tag: 2)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [browseViewController, installedViewController, searchViewController]
        
        // Theming
        if #available(iOS 13.0, *) {} else {
            tabBarController.tabBar.barStyle = .black
            tabBarController.tabBar.tintColor = UIColor(hex: "#EBC2FF")
            UINavigationBar.appearance().barStyle = .black
            UINavigationBar.appearance().tintColor = UIColor(hex: "#EBC2FF")
            UIView.appearance().backgroundColor = .black
            UILabel.appearance().textColor = .white
        }
        UITableView.appearance().separatorColor = .clear
        //
        
        addChild(tabBarController)
        view.addSubview(tabBarController.view)
        tabBarController.didMove(toParent: self)
    }
}
