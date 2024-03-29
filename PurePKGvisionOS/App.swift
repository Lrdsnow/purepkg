//
//  App.swift
//  PurePKGvisionOS
//
//  Created by Lrdsnow on 3/28/24.
//

import Foundation
import SwiftUI

@main
struct PurePKGBinary {
    static func main() {
        if (getuid() != 0) {
            PurePKGvisionOSApp.main();
        } else {
             exit(RootHelperMain());
        }
    }
}

struct PurePKGvisionOSApp: App {
    @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appData)
        }
    }
}
