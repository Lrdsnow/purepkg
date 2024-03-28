//
//  RootHelperMain.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/15/24.
//

import Foundation

func RootHelperMain() -> Int32 {
    if (CommandLine.argc < 2) {
        return -1;
    }
    
    switch CommandLine.arguments[1] {
    case "addRepo":
        do {
            try RepoHandler.RootHelper_addRepo(CommandLine.arguments[2])
            return 0
        } catch {
            fputs("error adding repo\n", stderr)
            return -1
        }
    case "removeRepo":
        do {
            try RepoHandler.RootHelper_removeRepo(URL(string: CommandLine.arguments[2])!)
            return 0
        } catch {
            fputs("error adding repo\n", stderr)
            return -1
        }
    case "saveRepoFiles":
        do {
            try RepoHandler.RootHelper_saveRepoFiles(URL(fileURLWithPath: CommandLine.arguments[2]))
            return 0
        } catch {
            fputs("error saving repo packages\n", stderr)
            return -1
        }
        
    default:
        fputs("unknown argument passed to rootHelper\n", stderr)
        return -1;
    }
}
