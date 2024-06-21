//
//  PaymentAPI.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/5/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AuthenticationServices
import SwiftUI

public class PaymentAPI {
    public static func postAPI(_ endpoint: String, _ repo: Repo, _ request_json_in: [String:String] = [:], addToken: Bool = false, completion: @escaping ([String: Any]?) -> Void) {
        do {
            if let api_endpoint = repo.payment_endpoint {
                var request = URLRequest(url: api_endpoint.appendingPathComponent(endpoint))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                var request_json = request_json_in
                if UserDefaults.standard.bool(forKey: "usePaymentAPI") && addToken {
                    if let token_data = Keychain.read(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)"),
                       String(decoding: token_data, as: UTF8.self) != "" {
                        request_json["token"] = String(decoding: token_data, as: UTF8.self)
                    }
                }
                let jsonData = try JSONSerialization.data(withJSONObject: request_json, options: [])
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        log("Error: \(error)")
                        return
                    }
                    if let response = response as? HTTPURLResponse {
                        log("response statusCode: \(response.statusCode)")
                    }
                    if let data = data {
                        do {
                            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                            completion(jsonResponse as? [String : Any])
                        } catch {
                            log("error parsing response: \(error)")
                            completion(nil)
                        }
                    }
                }
                task.resume()
            }
        } catch { log("invalid request") }
    }
    
    public struct PackagePaymentInfo {
        var price: String = "$0.00"
        var available: Bool = false
        var purchased: Bool = false
    }
    
    public struct UserInfoUser {
        var name: String
        var email: String
    }
    
    public struct UserInfo {
        var items: [String]
        var user: UserInfoUser
    }
    
    public static func logOut(_ repo: Repo, completion: @escaping () -> Void) {
        if UserDefaults.standard.bool(forKey: "usePaymentAPI"),
           let token = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)") ?? Data(), encoding: .utf8),
           token != "" {
            postAPI("sign_out", repo, ["token": token]) { _ in
                Keychain.delete(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)")
                completion()
            }
        } else {
            completion()
        }
    }
    
    public static func getUserInfo(_ repo: Repo, completion: @escaping (UserInfo?) -> Void) {
        if UserDefaults.standard.bool(forKey: "usePaymentAPI"),
           let token = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)") ?? Data(), encoding: .utf8),
           token != "" {
            postAPI("user_info", repo, ["token": token, "udid":Device().uniqueIdentifier, "device":Device().modelIdentifier]) { json in
                if let json = json,
                   let user_json = json["user"] as? [String:String],
                   let user_name = user_json["name"],
                   let user_email = user_json["email"],
                   let items = json["items"] as? [String] {
                    completion(UserInfo(items: items, user: UserInfoUser(name: user_name, email: user_email)))
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    public static func getPackageInfo(_ bundleid: String, _ repo: Repo, completion: @escaping (PackagePaymentInfo?) -> Void) {
        var request: [String:String] = ["udid":"PurePKGUser", "device":"PurePKGUser"]
        if UserDefaults.standard.bool(forKey: "usePaymentAPI") {
            request = ["udid":Device().uniqueIdentifier, "device":Device().modelIdentifier]
        }
        postAPI("package/\(bundleid)/info", repo, request, addToken: true) { json in
            do {
                if let json = json {
                    var info = PackagePaymentInfo()
                    if let price = json["price"] as? String {
                        info.price = price
                    }
                    if let available = json["available"] as? Bool {
                        info.available = available
                    }
                    if let purchased = json["purchased"] as? Bool {
                        info.purchased = purchased
                    }
                    completion(info)
                } else {
                    throw ""
                }
            } catch {
                log("failed to get package info")
                completion(nil)
            }
        }
    }
    
    public enum purchaseStatus {
        case success
        case actionRequired
        case failure
        case pending
        case awaitingConfirmation
    }
    
    public static func purchaseTweak(_ bundleid: String, _ repo: Repo, completion: @escaping (purchaseStatus, URL?) -> Void) {
        if UserDefaults.standard.bool(forKey: "usePaymentAPI"),
           let token = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)") ?? Data(), encoding: .utf8),
           let secret = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "secret_\(repo.name)") ?? Data(), encoding: .utf8),
           token != "",
           secret != "" {
            let request: [String:String] = ["token":token, "payment_secret":secret]
            postAPI("package/\(bundleid)/purchase", repo, request) { json in
                do {
                    if let json = json,
                       let status = json["status"] as? Int {
                        if status == 0 {
                            completion(.success, nil)
                            return
                        }
                        if status == 1,
                           let url = json["url"] as? String {
                            completion(.actionRequired, URL(string: url))
                            return
                        }
                        completion(.failure, nil)
                    } else {
                        throw ""
                    }
                } catch {
                    completion(.failure, nil)
                }
            }
        } else {
            completion(.failure, nil)
        }
    }
    
    public static func getDownloadURL(_ bundleid: String, _ version: String, _ repo: Repo, completion: @escaping (URL?) -> Void) {
        if UserDefaults.standard.bool(forKey: "usePaymentAPI"),
           let token = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)") ?? Data(), encoding: .utf8),
           let secret = String(data: Keychain.read(service: "uwu.lrdsnow.purepkg", account: "secret_\(repo.name)") ?? Data(), encoding: .utf8),
           token != "",
           secret != "" {
            let request: [String:String] = ["token":token, "udid":Device().uniqueIdentifier, "device":Device().modelIdentifier, "version":version, "repo":repo.name]
            postAPI("package/\(bundleid)/authorize_download", repo, request) { json in
                if let json = json,
                   let url = json["url"] as? String {
                    completion(URL(string: url))
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
}

#if os(tvOS) || os(watchOS)
class PaymentAPI_AuthenticationViewModel: ObservableObject {
    func auth(_ repo: Repo) {
        // not available in tvOS or watchOS
    }
}
#else
class PaymentAPI_AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authError: Error?
    
    private var authCoordinator: PaymentAPI_WebAuthenticationCoordinator
    
    init() {
        self.authCoordinator = PaymentAPI_WebAuthenticationCoordinator()
    }
    
    func auth(_ repo: Repo, appData: AppData) {
        authCoordinator.auth(repo: repo, appData: appData)
    }
}

class PaymentAPI_WebAuthenticationCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    var session: ASWebAuthenticationSession?
    
    func paymentAction(url: URL?, completion: @escaping (Bool) -> Void) {
        let callback: (URL?, Error?) -> Void = { url, error in
            if url == URL(string: "sileo://payment_completed") {
                completion(true)
            } else {
                completion(false)
            }
        }
        
        if let url = url {
            session = ASWebAuthenticationSession(url: url, callbackURLScheme: "sileo", completionHandler: callback)
            session?.presentationContextProvider = self
            session?.start()
        }
    }
    
    func authCLI(repo: Repo, udid: String, model: String, completion: @escaping (String, String) -> Void) {
        let callback: (URL?, Error?) -> Void = { url, error in
            if error != nil {
                completion("nil","nil")
                return
            }
            
            guard let url = url, url.host == "authentication_success" else {
                completion("nil","nil")
                return
            }
            
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var token: String?
            var secret: String?
            
            for item in components?.queryItems ?? [] {
                if item.name == "token" && item.value != nil {
                    token = item.value
                } else if item.name == "payment_secret" && item.value != nil {
                    secret = item.value
                }
                if token != nil && secret != nil {
                    break
                }
            }
            
            if let token = token, let secret = secret {
                completion(token, secret)
            }
        }
        
        if let authURL = URL(string: String(format: "authenticate?udid=%@&model=%@", udid, model), relativeTo: repo.payment_endpoint) {
            session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "sileo", completionHandler: callback)
            session?.presentationContextProvider = self
            session?.start()
        }
    }
    
    func auth(repo: Repo, appData: AppData) {
        let callback: (URL?, Error?) -> Void = { url, error in
            if error != nil {
                return
            }
            
            guard let url = url, url.host == "authentication_success" else {
                return
            }
            
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var token: String?
            var secret: String?
            
            for item in components?.queryItems ?? [] {
                if item.name == "token" && item.value != nil {
                    token = item.value
                } else if item.name == "payment_secret" && item.value != nil {
                    secret = item.value
                }
                if token != nil && secret != nil {
                    break
                }
            }
            
            if let token = token, let secret = secret {
                Keychain.save(token.data(using: .utf8) ?? Data(), service: "uwu.lrdsnow.purepkg", account: "token_\(repo.name)")
                Keychain.save(secret.data(using: .utf8) ?? Data(), service: "uwu.lrdsnow.purepkg", account: "secret_\(repo.name)")
                
                PaymentAPI.getUserInfo(repo) { userInfo in
                    DispatchQueue.main.async {
                        appData.userInfo[repo.name] = userInfo
                    }
                }
            }
        }
        
        if let authURL = repo.paymentAPI.authURL {
            session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "sileo", completionHandler: callback)
            session?.presentationContextProvider = self
            session?.start()
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene {
            if let window = windowScene.windows.first {
                return window
            }
        }
        return ASPresentationAnchor()
#else
        return ASPresentationAnchor()
#endif
    }
}
#endif
