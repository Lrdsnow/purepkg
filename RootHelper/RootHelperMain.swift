//
//  RootHelperMain.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/15/24.
//

import Foundation

func RootHelperMain() -> Int32 {
    var args = CommandLine.arguments
    #if os(macOS)
    args.removeAll(where: { $0 == "roothelper" })
    #endif
    
    if (args.count < 2) {
        return -1;
    }
    
    switch args[1] {
    case "addRepo":
        do {
            try RepoHandler.RootHelper_addRepo(args[2])
            return 0
        } catch {
            NSLog("error adding repo: \(error)")
            return -1
        }
    case "removeRepo":
        do {
            try RepoHandler.RootHelper_removeRepo(URL(string: args[2])!)
            return 0
        } catch {
            NSLog("error removing repo: \(error)")
            return -1
        }
    case "saveRepoFiles":
        do {
            try RepoHandler.RootHelper_saveRepoFiles(URL(fileURLWithPath: args[2]))
            return 0
        } catch {
            NSLog("error saving repo metadata file: \(error)")
            return -1
        }
    case "clearRepoFiles":
        do {
            try RepoHandler.RootHelper_clearRepoFiles(args[2])
            return 0
        } catch {
            NSLog("error clearing repo files: \(error)")
            return -1
        }
    case "removeAllRepoFiles":
        do {
            try RepoHandler.RootHelper_removeAllRepoFiles();
            return 0
        } catch {
            NSLog("error removing repo metadata file: \(error)")
            return -1
        }
#if os(macOS) || os(iOS)
    case "getToken":
        do {
            NSLog("getting token...")
            let semaphore = DispatchSemaphore(value: 0)
            PaymentAPI_WebAuthenticationCoordinator().authCLI(repo: Repo(name: "temp", url: URL(string: args[2])!, payment_endpoint: URL(string: try String(contentsOf: URL(string: args[2])!.appendingPathComponent("payment_endpoint")))), udid: args[3], model: args[4]) { token, secret in
                NSLog("token: \(token)")
                NSLog("secret: \(secret)")
                semaphore.signal()
            }
            semaphore.wait()
            return 0
        } catch {
            NSLog("error getting repo token: \(error)")
            return -1
        }
#endif
    case "info":
        NSLog("PurePKG Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0")")
        NSLog("Model: \(Device().modelIdentifier)")
        NSLog("\(Device().osString) Version: \(Device().build_number)")
        return 0
    default:
        NSLog("unknown argument passed to rootHelper")
        return -1;
    }
}
