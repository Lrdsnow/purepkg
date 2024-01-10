//
//  Misc.swift
//  PurePKG
//
//  Created by Lrdsnow on 1/10/24.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
