//
//  Popup.swift
//  PurePKG
//
//  Created by Lrdsnow on 3/18/24.
//

import Foundation
import UIKit

func showPopup(_ title: String, _ message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}

func showTextInputPopup(_ title: String, _ placeholderText: String, _ keyboardType: UIKeyboardType, completion: @escaping (String?) -> Void) {
    let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    
    alertController.addTextField { (textField) in
        textField.placeholder = placeholderText
        textField.keyboardType = keyboardType
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        completion(nil)
    }
    alertController.addAction(cancelAction)
    
    let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
        if let text = alertController.textFields?.first?.text {
            completion(text)
        } else {
            completion(nil)
        }
    }
    alertController.addAction(okAction)
    
    if let topViewController = UIApplication.shared.windows.first?.rootViewController {
        topViewController.present(alertController, animated: true, completion: nil)
    }
}
