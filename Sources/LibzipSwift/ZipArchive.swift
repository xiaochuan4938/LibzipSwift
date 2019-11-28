//
//  ZipArchive.swift
//  
//
//  Created by MartinLau on 2019/11/22.
//

import libzip
import Foundation

public final class ZipArchive: ZipErrorContext {

    internal var handle: OpaquePointer!
    
    // MARK: - struct
    
    // MARK: - property
    
    internal var error: ZipError? {
        return .zipError(zip_get_error(handle).pointee)
    }
    
    // MARK: - static
    
    /// check the file is zip archive
    /// - Parameter path: file path
    public static func isZipArchive(path: URL) -> Bool{
    
        // TODO: -
        return false
    }
    
    public static func createZip(path: String) throws -> ZipArchive {
        return try ZipArchive(path: path, mode: [.create])
    }
    
    public static func createZip(url: URL) throws -> ZipArchive {
        return try ZipArchive(url: url, mode: [.create])
    }
    
    // MARK: - init / open
    
    deinit {
        if let handle = handle {
            zip_discard(handle)
        }
    }
    
    public init(path: String, mode: [OpenMode] = [.none]) throws {
        if !FileManager.default.fileExists(atPath: path) {
            throw ZipError.fileNotExist;
        }
        var falgs: OpenMode = OpenMode(rawValue: Int32(ZIP_FL_COMPRESSED))
        mode.forEach {
            falgs = OpenMode(rawValue: falgs.rawValue | $0.rawValue)
        }
        var status: Int32 = ZIP_ER_OK
        let handle = path.withCString { path in
            return zip_open(path, falgs.rawValue, &status)
        }
        
        try checkZipError(status)
        self.handle = try handle.unwrapped()
    }
    
    public init(url: URL, mode: [OpenMode] = [.none]) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            throw ZipError.fileNotExist;
        }
        
        var falgs: OpenMode = OpenMode(rawValue: Int32(ZIP_FL_COMPRESSED))
        mode.forEach { item in
            falgs = OpenMode(rawValue: falgs.rawValue | item.rawValue)
        }
        var status: Int32 = ZIP_ER_OK
        let handle: OpaquePointer? = try url.withUnsafeFileSystemRepresentation { path in
            if let path = path {
                return zip_open(path, falgs.rawValue, &status)
            } else {
                throw ZipError.unsupportedURL
            }
        }
        
        try checkZipError(status)
        self.handle = try handle.unwrapped()
    }
    
    func close(discardChanged: Bool = false) throws {
        if discardChanged {
            zip_discard(handle)
        } else {
            zip_close(handle)
        }
        handle = nil
    }
    
    // MARK: - password handling
    
    public func setDefaultPassword(_ password: String) throws {
        try password.withCString { password in
            _ = try checkZipError(zip_set_default_password(handle, password))
        }
    }
    
    // MARK: - comments
    
    public func getComment(encoding: Encoding = .guess, condition: Condition = .original) throws -> String {
        return try String(cString: checkZipResult(zip_get_archive_comment(handle, nil, encoding.rawValue | condition.rawValue)))
    }
    
    public func setComment(comment: String) throws {
        try comment.withCString { comment in
            _ = try checkZipResult(zip_set_archive_comment(handle, comment, zipCast(strlen(comment))))
        }
    }
    
    public func deleteComment() throws {
        try checkZipResult(zip_set_archive_comment(handle, nil, 0))
    }
    
    // MARK: - entry
    
    func getEntryCount(condition: Condition = .original) throws -> Int {
        return try zipCast(checkZipResult(zip_get_num_entries(handle, condition.rawValue)))
    }
    
    public func getEntries() throws -> [ZipEntry] {
        let count = try getEntryCount()
        var zipentries: [ZipEntry] = Array.init()
        for idx in 0..<count {
            var stat = zip_stat()
            try checkZipResult(zip_stat_index(handle, zip_uint64_t(idx), Condition.original.rawValue, &stat))
            let entry = try ZipEntry(archive: self, stat: stat)
            zipentries.append(entry)
        }
        return zipentries
    }
    
    public containsEntry(name: String, caseSensitive: Bool, index: inout UInt64) -> {
        
    }
    
    public func deleteEntry(index: UInt64) -> Bool {
        return checkIsSuccess(zip_delete(handle, index))
    }
    
    public func deleteEntry(entryName: String, caseSensitive: Bool) -> {
        var idx: Int64 = 0
        
    }
    
    public func addFile() {
        
    }
    
}


