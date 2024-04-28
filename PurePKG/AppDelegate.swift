//
//  AppDelegate.swift
//  PurePKG
//
//  Created by lrdsnow on 4/26/24.
//

import UIKit

@main
struct PurePKGBinary {
    static func main() {
        if (getuid() != 0) {
            UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self));
        } else {
            exit(RootHelperMain());
        }
        
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Appearances
        let stackViewAppearance = UIStackView.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        stackViewAppearance.spacing = -10
        //
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let viewController = ViewController()
        window.rootViewController = viewController
        return true
    }
}

