//
//  Decompression.swift
//  PurePKG
//
//  Created by Lrdsnow on 6/3/24.
//

import Foundation
import SWCompression
import libzstd

func DecompressZSTD(data: Data) throws -> Data {
    let stream = ZSTD_createDStream();
    if (stream == nil) {
        throw "ZSTD_createDStream() failed!"
    }
    ZSTD_initDStream(stream);
    var outData = Data();

    var inBuffer = ZSTD_inBuffer(src: (data as NSData).bytes, size: data.count, pos: 0);
    let tempBuf = UnsafeMutableRawPointer.allocate(byteCount: 1048576, alignment: 8)
    while (inBuffer.pos < inBuffer.size) {
        var outBuffer = ZSTD_outBuffer(dst: tempBuf, size: 1048576, pos: 0);
        let retval = ZSTD_decompressStream(stream, &outBuffer, &inBuffer);
        if ((ZSTD_isError(retval)) != 0) {
            tempBuf.deallocate();
            ZSTD_freeDStream(stream);
            throw String(cString: ZSTD_getErrorName(retval));
        }
        outData.append(tempBuf.bindMemory(to: UInt8.self, capacity: 1048576), count: outBuffer.pos);
    }
    ZSTD_freeDStream(stream)
    tempBuf.deallocate();
    return outData;
}

enum ArchiveType {
    case XZ
    case BZip
    case GZip
    case Zstd
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
            return .Zstd
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
            case .Zstd:
                decompressedData = try DecompressZSTD(data: self)
            }
            return decompressedData
        } catch {
            log("Failed to decompress archive: \(error)")
            return nil
        }
    }
}
