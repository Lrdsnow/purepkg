//
//  Decompression.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/3/24.
//

import Foundation
import SWCompression

enum ArchiveType {
    case XZ
    case BZip
    case GZip
}

extension URL {
    func archiveType() -> ArchiveType? {
        if self.lastPathComponent.contains(".xz") || self.lastPathComponent.contains(".lzma") {
            return .XZ
        } else if self.lastPathComponent.contains(".gz") {
            return .GZip
        } else if self.lastPathComponent.contains(".bz2") {
            return .BZip
        } else if self.lastPathComponent.contains(".zst") {
            log("idk how to add ZST support but if someone wants to, contribute to purepkg at https://github.com/lrdsnow/purepkg")
            return nil
        } else {
            return nil
        }
    }
}

extension Data {
    func decompress(_ type: ArchiveType) -> Data? {
        do {
            var decompressedData: Data? = nil
            switch type {
            case .XZ:
                decompressedData = try XZArchive.unarchive(archive: self)
            case .BZip:
                decompressedData = try BZip2.decompress(data: self)
            case .GZip:
                decompressedData = try GzipArchive.unarchive(archive: self)
            }
            return decompressedData
        } catch {
            log("Failed to decompress archive: \(error)")
            return nil
        }
    }
}
