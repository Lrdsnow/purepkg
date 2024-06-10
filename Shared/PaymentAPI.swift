//
//  PaymentAPI.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/5/24.
//

import Foundation

public class PaymentAPI {
    public static func postAPI(_ endpoint: String, _ repo: Repo, _ request_json_in: [String:String] = [:], addToken: Bool = false, completion: @escaping ([String: Any]?) -> Void) {
        do {
            if let api_endpoint = repo.payment_endpoint {
                var request = URLRequest(url: api_endpoint.appendingPathComponent(endpoint))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                var request_json = request_json_in
                if UserDefaults.standard.bool(forKey: "usePaymentAPI") && addToken {
                    if let token_data = Keychain.read(service: "purepkg", account: repo.url.absoluteString),
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
                        print("response statusCode: \(response.statusCode)")
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
    
    public static func getPackageInfo(_ bundleid: String, _ repo: Repo, completion: @escaping (PackagePaymentInfo?) -> Void) {
        var request: [String:String] = ["udid":"PurePKGUser", "device":"PurePKGUser"]
        if UserDefaults.standard.bool(forKey: "usePaymentAPI") {
            let deviceInfo = getDeviceInfo()
            request = ["udid":deviceInfo.uniqueIdentifier, "device":deviceInfo.modelIdentifier]
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
