//
//  Spawn.swift
//  PurePKG
//
//  Created by Nick Chan on 2024/6/6.
//

import Foundation

@discardableResult
func spawnRoot(_ path: String,_ args: [String], _ stdout: UnsafeMutablePointer<String>?, _ stderr: UnsafeMutablePointer<String>?) -> Int32 {
    
    var argsC: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
    var path_Cstring = strdup((path as NSString).utf8String);
    argsC.insert(path_Cstring, at: 0);
    argsC.append(nil);
    defer { for arg in argsC { free(arg); } }
    
    var attr: posix_spawnattr_t?;
    defer { custom_posix_spawnattr_destroy(&attr); }
    
    custom_posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, UInt32(POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE));
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);
    
    var pipestatusfd: [Int32] = [0, 0];
    var pipestdout: [Int32] = [0, 0];
    var pipestderr: [Int32] = [0, 0];
    var pipesileo: [Int32] = [0, 0];
    
    pipe(&pipestatusfd);
    pipe(&pipestdout);
    pipe(&pipestderr);
    pipe(&pipesileo);
    
    let sileoFDStr = ProcessInfo.processInfo.environment["SILEO_FD"];
    let sileoFD = Int32(sileoFDStr ?? "0");
    
    var envC = [ "SILEO=6 1", "CYDIA=6 1", "PATH='/usr/bin:/usr/local/bin:/bin:/usr/sbin:/var/jb/usr/bin:/var/jb/usr/local/bin:/var/jb/bin:/var/jb/usr/sbin:/opt/procursus/sbin:/opt/procursus/usr/bin:/opt/procursus/usr/local/bin:/opt/procursus/bin:/opt/procursus/usr/sbin:/opt/procursus/sbin'"].map { $0.withCString(strdup) };
    envC.append(nil);
    defer { for env in envC { free(env); } }
    
    var fileActions: posix_spawn_file_actions_t?;
    defer { custom_posix_spawn_file_actions_destroy(&fileActions); }
    
    custom_posix_spawn_file_actions_init(&fileActions);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[0]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[0]);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipestatusfd[1], 5);
    custom_posix_spawn_file_actions_adddup2(&fileActions, pipesileo[1], sileoFD!);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[1]);
    custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[1]);
    
    var task_pid: pid_t = 0;
    let spawnError: Int32 = custom_posix_spawn(&task_pid, argsC, &fileActions, &attr, argsC, envC)
    if (spawnError != 0) {
        log("posix_spawn error %d\n", spawnError);
        return spawnError;
    }
    
    return 0;
}
