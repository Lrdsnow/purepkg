//
//  TroubleshootingView.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/4/24.
//

import Foundation
import SwiftUI

struct LogEntry: Hashable {
    let text: String // log text,
    let complete: Bool? // nil = waiting, true = success, false = failed - seems pretty simple
}

struct Solution: Hashable {
    let text: String // solution name
    let function: () -> Void // solution function
    
    static func == (lhs: Solution, rhs: Solution) -> Bool {
        lhs.text == rhs.text
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}

struct TroubleshootingView: View {
    @EnvironmentObject var appData: AppData
    @State private var ran = false
    @State private var state = "Waiting..."
    @State private var logs: [LogEntry] = []
    @State private var solutions: [Solution] = []
    
    var body: some View {
        List {
            Section {
                Button(action: {
                    runTroubleshooter()
                }, label: {
                    Text(ran ? state : "Run Troubleshooter")
                }).disabled(ran)
            }
            if ran {
                Section {
                    ForEach(logs, id: \.self) { logEntry in
                        HStack {
                            Text(logEntry.text)
                            Spacer()
                            if let complete = logEntry.complete {
                                if complete {
                                    Image(systemName: "checkmark.circle").foregroundColor(.green)
                                } else {
                                    Image(systemName: "x.circle").foregroundColor(.red)
                                }
                            } else {
                                if #available(tvOS 14.0, iOS 14.0, *) {
                                    ProgressView()
                                } else {
                                    Image(systemName: "circle")
                                }
                            }
                        }
                    }
                }
                Section {
                    ForEach(solutions, id: \.self) { solution in
                        Button(action: { solution.function() }, label: {
                            Text(solution.text)
                        })
                    }
                }
            }
        }.appBG().navigationBarTitleC("Troubleshooting")
    }
    
    func runTroubleshooter() {
        ran = true
        logs = []
        // ill finish this when i get a device to test on
    }
}
