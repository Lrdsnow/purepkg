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

@propertyWrapper
struct AppStorageC<Value>: DynamicProperty {
    let key: String
    let defaultValue: Value

    init(wrappedValue defaultValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = defaultValue
        self._wrappedValue = State(wrappedValue: UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue)
    }

    @State var wrappedValue: Value {
        didSet { UserDefaults.standard.set(wrappedValue, forKey: key) }
    }
    var projectedValue: Binding<Value> {
        return Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
