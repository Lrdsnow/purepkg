//
//  UserDefaultsExtensions.swift
//  PurePKG
//
//  Created by Lrdsnow on 4/21/24.
//

import Foundation
import SwiftUI
#if os(iOS)
import UIKit

extension UserDefaults {
    func setImage(_ image: UIImage?, forKey key: String) {
        guard let image = image else {
            removeObject(forKey: key)
            return
        }
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            set(imageData, forKey: key)
        }
    }
    
    func imageForKey(_ key: String) -> UIImage? {
        if let imageData = data(forKey: key) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
#endif
