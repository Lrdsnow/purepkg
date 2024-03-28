//
//  APTWrapper.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/18/24.
//  This file contains software developed by the Sileo Team

import Foundation

class APTWrapper {
    static let sileoFD = 6
    static let cydiaCompatFd = 6
    static let debugFD = 11

    public enum FINISH: Int {
        case back = 0
        case uicache = 1
        case reopen = 2
        case restart = 3
        case reload = 4
        case reboot = 5
        case usreboot = 6
    }

    static let GNUPGPREFIX = "[GNUPG:]"
    static let GNUPGBADSIG = "[GNUPG:] BADSIG"
    static let GNUPGERRSIG = "[GNUPG:] ERRSIG"
    static let GNUPGNOPUBKEY = "[GNUPG:] NO_PUBKEY"
    static let GNUPGVALIDSIG = "[GNUPG:] VALIDSIG"
    static let GNUPGGOODSIG = "[GNUPG:] GOODSIG"
    static let GNUPGEXPKEYSIG = "[GNUPG:] EXPKEYSIG"
    static let GNUPGEXPSIG = "[GNUPG:] EXPSIG"
    static let GNUPGREVKEYSIG = "[GNUPG:] REVKEYSIG"
    static let GNUPGNODATA = "[GNUPG:] NODATA"
    static let APTKEYWARNING = "[APTKEY:] WARNING"
    static let APTKEYERROR = "[APTKEY:] ERROR"

    enum DigestState {
        case untrusted,
        weak,
        trusted
    }

    struct Digest {
        let state: DigestState
        let name: String
    }

    static let digests: [Digest] = [
        Digest(state: .untrusted, name: "Invalid Digest"),
        Digest(state: .untrusted, name: "MD5"),
        Digest(state: .untrusted, name: "SHA1"),
        Digest(state: .untrusted, name: "RIPE-MD/160"),
        Digest(state: .untrusted, name: "Reserved digest"),
        Digest(state: .untrusted, name: "Reserved digest"),
        Digest(state: .untrusted, name: "Reserved digest"),
        Digest(state: .untrusted, name: "Reserved digest"),
        Digest(state: .trusted, name: "SHA256"),
        Digest(state: .trusted, name: "SHA384"),
        Digest(state: .trusted, name: "SHA512"),
        Digest(state: .trusted, name: "SHA224")
    ]

    class func dictionaryOfScannedApps() -> [String: Int64] {
        var dictionary: [String: Int64] = [:]
        let fileManager = FileManager.default

        guard let apps = try? fileManager.contentsOfDirectory(atPath: "\(Jailbreak.path())/Applications") else {
            return dictionary
        }

        for app in apps {
            let infoPlist = String(format: "\(Jailbreak.path())/Applications/%@/Info.plist", app)

            guard let attr = try? fileManager.attributesOfItem(atPath: infoPlist) else {
                continue
            }

            let fileNumber = attr[FileAttributeKey.systemFileNumber] as? Int64
            dictionary[app] = fileNumber
        }
        return dictionary
    }

    public class func installProgress(aptStatus: String) -> (Bool, Double, String, String) {
        let statusParts = aptStatus.components(separatedBy: ":")
        if statusParts.count < 4 {
            return (false, 0, "", "")
        }
        if statusParts[0] != "pmstatus" {
            return (false, 0, "", "")
        }

        let packageName = statusParts[1]
        guard let rawProgress = Double(statusParts[2]) else {
            return (false, 0, "", "")
        }
        let statusReadable = statusParts[3]
        return (true, rawProgress, statusReadable, packageName)
    }
    
    @discardableResult private static func spawn(command: String, args: [String], root: Bool = false) -> (Int, String, String) {
        var pipestdout: [Int32] = [0, 0]
        var pipestderr: [Int32] = [0, 0]

        let bufsiz = Int(BUFSIZ)

        pipe(&pipestdout)
        pipe(&pipestderr)

        guard fcntl(pipestdout[0], F_SETFL, O_NONBLOCK) != -1 else {
            return (-1, "", "")
        }
        guard fcntl(pipestderr[0], F_SETFL, O_NONBLOCK) != -1 else {
            return (-1, "", "")
        }

        var fileActions: posix_spawn_file_actions_t?
        custom_posix_spawn_file_actions_init(&fileActions)
        custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[0])
        custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[0])
        custom_posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO)
        custom_posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO)
        custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[1])
        custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[1])

        let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
        defer { for case let arg? in argv { free(arg) } }

        var pid: pid_t = 0

        #if targetEnvironment(macCatalyst)
        let env = [ "PATH=/opt/procursus/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin" ]
        let proenv: [UnsafeMutablePointer<CChar>?] = env.map { $0.withCString(strdup) }
        defer { for case let pro? in proenv { free(pro) } }
        let spawnStatus = custom_posix_spawn(&pid, command, &fileActions, nil, argv + [nil], proenv + [nil])
        #else
        // Weird problem with a weird workaround
        let env = [ "PATH=\(Jailbreak.path())/usr/bin:\(Jailbreak.path())/usr/local/bin:\(Jailbreak.path())/bin:\(Jailbreak.path())/usr/sbin" ]
        let envp: [UnsafeMutablePointer<CChar>?] = env.map { $0.withCString(strdup) }
        defer { for case let env? in envp { free(env) } }
        
        let spawnStatus: Int32
        if #available(iOS 13, *) {
            if root {
                var attr: posix_spawnattr_t?
                custom_posix_spawnattr_init(&attr)
                posix_spawnattr_set_persona_np(&attr, 99, UInt32(POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE))
                posix_spawnattr_set_persona_uid_np(&attr, 0)
                posix_spawnattr_set_persona_gid_np(&attr, 0)
                spawnStatus = custom_posix_spawn(&pid, command, &fileActions, &attr, argv + [nil], envp + [nil])
            } else {
                spawnStatus = custom_posix_spawn(&pid, command, &fileActions, nil, argv + [nil], envp + [nil])
            }
        } else {
            spawnStatus = custom_posix_spawn(&pid, command, &fileActions, nil, argv + [nil], envp + [nil])
        }
        #endif
        if spawnStatus != 0 {
            return (Int(spawnStatus), "ITS FAILING HERE", "Error = \(errno)  \(String(cString: strerror(spawnStatus))) \(String(cString: strerror(errno)))\n\(command)")
        }

        close(pipestdout[1])
        close(pipestderr[1])

        var stdoutStr = ""
        var stderrStr = ""

        let mutex = DispatchSemaphore(value: 0)

        let readQueue = DispatchQueue(label: "org.coolstar.sileo.command",
                                      qos: .userInitiated,
                                      attributes: .concurrent,
                                      autoreleaseFrequency: .inherit,
                                      target: nil)

        let stdoutSource = DispatchSource.makeReadSource(fileDescriptor: pipestdout[0], queue: readQueue)
        let stderrSource = DispatchSource.makeReadSource(fileDescriptor: pipestderr[0], queue: readQueue)

        stdoutSource.setCancelHandler {
            close(pipestdout[0])
            mutex.signal()
        }
        stderrSource.setCancelHandler {
            close(pipestderr[0])
            mutex.signal()
        }

        stdoutSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }

            let bytesRead = read(pipestdout[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }

                stdoutSource.cancel()
                return
            }

            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                stdoutStr += str
            }
        }
        stderrSource.setEventHandler {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
            defer { buffer.deallocate() }

            let bytesRead = read(pipestderr[0], buffer, bufsiz)
            guard bytesRead > 0 else {
                if bytesRead == -1 && errno == EAGAIN {
                    return
                }

                stderrSource.cancel()
                return
            }

            let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
            array.withUnsafeBufferPointer { ptr in
                let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                stderrStr += str
            }
        }

        stdoutSource.resume()
        stderrSource.resume()

        mutex.wait()
        mutex.wait()
        var status: Int32 = 0
        waitpid(pid, &status, 0)

        return (Int(status), stdoutStr, stderrStr)
    }

    public static func verifySignature(key: String, data: String, error: inout String) -> Bool {
        #if targetEnvironment(simulator) || TARGET_SANDBOX

        //error = "GnuPG not available in sandboxed environment"
        return true

        #else
        
        let (_, output, _) = spawn(command: "\(Jailbreak.path())/bin/sh", args: ["sh", "\(Jailbreak.path())/usr/bin/apt-key", "verify", "-q", "--status-fd", "1", key, data])
        
        log("apt-key output: \(output)");

        let outputLines = output.components(separatedBy: "\n")

        var keyIsGood = false
        var keyIsTrusted = false

        let substrCount = GNUPGPREFIX.count + 1

        for outputLine in outputLines {
            for prefix in [GNUPGBADSIG, GNUPGERRSIG, GNUPGEXPSIG, GNUPGREVKEYSIG, GNUPGNOPUBKEY, GNUPGNODATA] {
                if outputLine.hasPrefix(prefix) {
                    let index = outputLine.index(outputLine.startIndex, offsetBy: substrCount)
                    error = String(outputLine[index...])
                    keyIsGood = false
                }
            }
            if outputLine.hasPrefix(GNUPGGOODSIG) {
                keyIsGood = true
            }
            if outputLine.hasPrefix(GNUPGVALIDSIG) {
                let sigComponents = outputLine.components(separatedBy: " ")
                if sigComponents.count < 10 {
                    continue
                }

                // let sig = sigComponents[2]
                let digestType = sigComponents[9]

                guard let digestIdx = Int(digestType),
                    digestIdx <= digests.count else {
                        continue
                }

                let digest = digests[digestIdx]
                if digest.state == .trusted {
                    keyIsTrusted = true
                }
            }
        }
        return keyIsGood && keyIsTrusted

        #endif
    }
    
    public class func performOperations(installs: [Package],
                                        removals: [Package],
                                        installDeps: [Package],
                                        progressCallback: @escaping (Double, Bool, String, String) -> Void,
                                        outputCallback: @escaping (String, Int) -> Void,
                                        completionCallback: @escaping (Int, FINISH, Bool) -> Void) {
        #if targetEnvironment(simulator) || TARGET_SANDBOX
        return completionCallback(0, .back, true)
        #else
        var arguments = ["\(Jailbreak.path())/usr/bin/apt-get",
                         "install", "--reinstall",
                         "--allow-unauthenticated",
                         "--allow-downgrades",
                         "--allow-remove-essential",
                         "--allow-change-held-packages",
                         "-y", "-f",
                         "-oAPT::Status-Fd=5",
                         "-oAPT::Keep-Fds::=6",
                         "-oAcquire::AllowUnsizedPackages=true",
                         "-oDir::State::lists=purepkglists/",
                         "-oAPT::Sandbox::User=root",
                         "-oDpkg::Options::=--force-confdef",
                         "-oDpkg::Options::=--force-confnew"]
        for package in installs {
            var packagesStr = package.id + "=" + package.version
            if package.id.contains("/") {
                packagesStr = package.debPath ?? package.id
            }
            arguments.append(packagesStr)
        }
        for package in removals {
            let packageStr = package.id + "-"
            arguments.append(packageStr)
        }
        var finish = FINISH.back
        DispatchQueue.global(qos: .default).async {
            let oldApps = APTWrapper.dictionaryOfScannedApps()

            var pipestatusfd: [Int32] = [0, 0]
            var pipestdout: [Int32] = [0, 0]
            var pipestderr: [Int32] = [0, 0]
            var pipesileo: [Int32] = [0, 0]

            let bufsiz = Int(BUFSIZ)

            pipe(&pipestdout)
            pipe(&pipestderr)
            pipe(&pipestatusfd)
            pipe(&pipesileo)

            guard fcntl(pipestdout[0], F_SETFL, O_NONBLOCK) != -1,
                  fcntl(pipestderr[0], F_SETFL, O_NONBLOCK) != -1,
                  fcntl(pipestatusfd[0], F_SETFL, O_NONBLOCK) != -1,
                  fcntl(pipesileo[0], F_SETFL, O_NONBLOCK) != -1
            else {
                fatalError("Unable to set attributes on pipe")
            }

            var fileActions: posix_spawn_file_actions_t?
            custom_posix_spawn_file_actions_init(&fileActions)
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[0])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[0])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[0])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[0])
            custom_posix_spawn_file_actions_adddup2(&fileActions, pipestdout[1], STDOUT_FILENO)
            custom_posix_spawn_file_actions_adddup2(&fileActions, pipestderr[1], STDERR_FILENO)
            custom_posix_spawn_file_actions_adddup2(&fileActions, pipestatusfd[1], 5)
            custom_posix_spawn_file_actions_adddup2(&fileActions, pipesileo[1], Int32(sileoFD))
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestdout[1])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestderr[1])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipestatusfd[1])
            custom_posix_spawn_file_actions_addclose(&fileActions, pipesileo[1])
        
            let command = arguments.first!
            arguments[0] = String(command.split(separator: "/").last!)
            
            let argv: [UnsafeMutablePointer<CChar>?] = arguments.map { $0.withCString(strdup) }
            defer {
                for case let arg? in argv {
                    free(arg)
                }
            }

            let environment = ["SILEO=6 1", "CYDIA=6 1", "PATH=\(Jailbreak.path())/usr/bin:\(Jailbreak.path())/usr/local/bin:\(Jailbreak.path())/bin:\(Jailbreak.path())/usr/sbin"]
            let env: [UnsafeMutablePointer<CChar>?] = environment.map { $0.withCString(strdup) }
            defer {
                for case let key? in env {
                    free(key)
                }
            }

            var pid: pid_t = 0
            
            let spawnStatus: Int32
            
            var attr: posix_spawnattr_t?
            custom_posix_spawnattr_init(&attr)
            posix_spawnattr_set_persona_np(&attr, 99, UInt32(POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE));
            posix_spawnattr_set_persona_uid_np(&attr, 0);
            posix_spawnattr_set_persona_gid_np(&attr, 0);
            spawnStatus = custom_posix_spawn(&pid, command, &fileActions, &attr, argv + [nil], env + [nil])
            
            if spawnStatus != 0 {
                return
            }

            close(pipestdout[1])
            close(pipestderr[1])
            close(pipestatusfd[1])
            close(pipesileo[1])

            let mutex = DispatchSemaphore(value: 0)

            let readQueue = DispatchQueue(label: "uwu.lrdsnow.purepkg.command",
                                          qos: .userInitiated,
                                          attributes: .concurrent,
                                          autoreleaseFrequency: .inherit,
                                          target: nil)

            let stdoutSource = DispatchSource.makeReadSource(fileDescriptor: pipestdout[0], queue: readQueue)
            let stderrSource = DispatchSource.makeReadSource(fileDescriptor: pipestderr[0], queue: readQueue)
            let statusFdSource = DispatchSource.makeReadSource(fileDescriptor: pipestatusfd[0], queue: readQueue)
            let sileoFdSource = DispatchSource.makeReadSource(fileDescriptor: pipesileo[0], queue: readQueue)

            stdoutSource.setCancelHandler {
                close(pipestdout[0])
                mutex.signal()
            }
            stderrSource.setCancelHandler {
                close(pipestderr[0])
                mutex.signal()
            }
            statusFdSource.setCancelHandler {
                close(pipestatusfd[0])
                mutex.signal()
            }
            sileoFdSource.setCancelHandler {
                close(pipesileo[0])
            }

            stdoutSource.setEventHandler {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
                defer { buffer.deallocate() }

                let bytesRead = read(pipestdout[0], buffer, bufsiz)
                guard bytesRead > 0 else {
                    if bytesRead == -1 && errno == EAGAIN {
                        return
                    }

                    stdoutSource.cancel()
                    return
                }

                let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
                array.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    outputCallback(str, Int(STDOUT_FILENO))
                }
            }
            stderrSource.setEventHandler {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
                defer { buffer.deallocate() }

                let bytesRead = read(pipestderr[0], buffer, bufsiz)
                guard bytesRead > 0 else {
                    if bytesRead == -1 && errno == EAGAIN {
                        return
                    }

                    stderrSource.cancel()
                    return
                }

                let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
                array.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    outputCallback(str, Int(STDERR_FILENO))
                }
            }
            statusFdSource.setEventHandler {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
                defer { buffer.deallocate() }

                let bytesRead = read(pipestatusfd[0], buffer, bufsiz)
                guard bytesRead > 0 else {
                    if bytesRead == -1 && errno == EAGAIN {
                        return
                    }

                    statusFdSource.cancel()
                    return
                }

                let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
                array.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))

                    let statusLines = str.components(separatedBy: "\n")
                    for status in statusLines {
                        let (statusValid, statusProgress, statusReadable, package) = self.installProgress(aptStatus: status)
                        progressCallback(statusProgress, statusValid, statusReadable, package)
                    }
                }
            }
            sileoFdSource.setEventHandler {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufsiz)
                defer { buffer.deallocate() }

                let bytesRead = read(pipesileo[0], buffer, bufsiz)
                guard bytesRead > 0 else {
                    if bytesRead == -1 && errno == EAGAIN {
                        return
                    }

                    statusFdSource.cancel()
                    return
                }

                let array = Array(UnsafeBufferPointer(start: buffer, count: bytesRead)) + [UInt8(0)]
                array.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))

                    let sileoLines = str.components(separatedBy: "\n")
                    for sileoLine in sileoLines {
                        if sileoLine.hasPrefix("finish:") {
                            var newFinish = FINISH.back
                            if sileoLine.hasPrefix("finish:return") {
                                newFinish = .back
                            }
                            if sileoLine.hasPrefix("finish:reopen") {
                                newFinish = .reopen
                            }
                            if sileoLine.hasPrefix("finish:restart") {
                                newFinish = .restart
                            }
                            if sileoLine.hasPrefix("finish:reload") {
                                newFinish = .reload
                            }
                            if sileoLine.hasPrefix("finish:reboot") {
                                newFinish = .reboot
                            }
                            if sileoLine.hasPrefix("finish:usreboot") {
                                newFinish = .usreboot
                            }

                            if newFinish.rawValue > finish.rawValue {
                                finish = newFinish
                            }
                        }
                    }
                }
            }

            stdoutSource.resume()
            stderrSource.resume()
            statusFdSource.resume()
            sileoFdSource.resume()

            mutex.wait()
            mutex.wait()
            mutex.wait()

            if !sileoFdSource.isCancelled {
                sileoFdSource.cancel()
            }

            var status: Int32 = 0
            waitpid(pid, &status, 0)
            var refreshSileo = false
            
            let newApps = dictionaryOfScannedApps()
            var difference = Set<String>()
            for (key, _) in oldApps where newApps[key] == nil {
                difference.insert(key)
            }
            for (key, _) in newApps where oldApps[key] == nil {
                difference.insert(key)
            }
            for (key, value) in newApps where oldApps[key] != nil {
                guard let oldValue = oldApps[key] else { continue }
                if oldValue != value {
                    difference.insert(key)
                }
            }
            if !difference.isEmpty {
                outputCallback("Updating Icon Cache\n", debugFD)
                for appName in difference {
                    let appPath = URL(fileURLWithPath: "\(Jailbreak.path())/Applications/").appendingPathComponent(appName)
                    if appPath.path == Bundle.main.bundlePath {
                        refreshSileo = true
                    } else {
                        spawnRoot("\(Jailbreak.path())/usr/bin/uicache", ["uicache", "-p", "\(appPath.path)"], nil, nil)
                    }
                }
            }

            spawnRoot("\(Jailbreak.path())/usr/bin/apt-get", ["clean"], nil, nil)
            
            completionCallback(Int(status), finish, refreshSileo)
        }
        #endif
    }
}
