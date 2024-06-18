//
//  PaymentAPI.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/5/24.
//

import Foundation
import UIKit
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
}

#if os(tvOS)
class PaymentAPI_AuthenticationViewModel: ObservableObject {
    func auth(_ repo: Repo) {
        // not available in tvOS
    }
}

struct WebAuthView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    let url: URL
    let completionHandler: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let coordinator = PaymentAPI_WebAuthenticationCoordinator_objc()
        coordinator.auth(with: url) { authenticatedURL in
            self.completionHandler(authenticatedURL)
        }
        
        let viewController = UIViewController()
        viewController.view = coordinator.webView as? UIView
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
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
    
    func auth(repo: Repo, appData: AppData) {
        let callback: (URL?, Error?) -> Void = { url, error in
            if let error = error {
                if let error = error as? ASWebAuthenticationSessionError, error.code == ASWebAuthenticationSessionError.canceledLogin {
                    return
                }
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
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
#endif
