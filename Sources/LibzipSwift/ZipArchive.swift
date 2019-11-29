//
//  ZipArchive.swift
//  
//
//  Created by MartinLau on 2019/11/22.
//

import libzip
import Foundation

public final class ZipArchive: ZipErrorContext {

    internal var archiveOpt: OpaquePointer!
    
    // MARK: - struct
    public struct LocateFlags: OptionSet {
        public let rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        public static let none = LocateFlags(rawValue: 0)
        public static let caseInsensitive = LocateFlags(rawValue: ZIP_FL_NOCASE)
        public static let ignoreDirectory = LocateFlags(rawValue: ZIP_FL_NODIR)
    }

    // MARK: - property
    
    internal var error: ZipError? {
        return .zipError(zip_get_error(archiveOpt).pointee)
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
        if let handle = archiveOpt {
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
        self.archiveOpt = try handle.unwrapped()
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
        self.archiveOpt = try handle.unwrapped()
    }
    
    func close(discardChanged: Bool = false) throws {
        if discardChanged {
            zip_discard(archiveOpt)
        } else {
            zip_close(archiveOpt)
        }
        archiveOpt = nil
    }
    
    // MARK: - password handling
    
    public func setDefaultPassword(_ password: String) throws {
        try password.withCString { password in
            _ = try checkZipError(zip_set_default_password(archiveOpt, password))
        }
    }
    
    // MARK: - comments
    
    public func getComment(encoding: Encoding = .guess, condition: Condition = .original) throws -> String {
        return try String(cString: checkZipResult(zip_get_archive_comment(archiveOpt, nil, encoding.rawValue | condition.rawValue)))
    }
    
    public func setComment(comment: String) throws {
        try comment.withCString { comment in
            _ = try checkZipResult(zip_set_archive_comment(archiveOpt, comment, zipCast(strlen(comment))))
        }
    }
    
    public func deleteComment() throws {
        try checkZipResult(zip_set_archive_comment(archiveOpt, nil, 0))
    }
    
    // MARK: - entry
    
    private func getEntryCount(condition: Condition = .original) throws -> Int {
        return try zipCast(checkZipResult(zip_get_num_entries(archiveOpt, condition.rawValue)))
    }
    
    public func getEntries() throws -> [ZipEntry] {
        let count = try getEntryCount()
        var zipentries: [ZipEntry] = Array.init()
        for idx in 0..<count {
            var stat = zip_stat()
            try checkZipResult(zip_stat_index(archiveOpt, zip_uint64_t(idx), Condition.original.rawValue, &stat))
            let entry = ZipEntry(archive: self, stat: stat)
            zipentries.append(entry)
        }
        return zipentries
    }
    
    private func lookupEntry(_ entryName: String, _ caseSensitive: Bool) -> Int64 {
        guard !entryName.isEmpty else {
            return -1
        }
        return entryName.withCString { entryName  in
            if let index = try? checkZipResult(zip_name_locate(archiveOpt, entryName, caseSensitive ? LocateFlags.none.rawValue : LocateFlags.caseInsensitive.rawValue)) {
                return index
            }
            return -1
        }
    }
    
    public func readEntry(from index: UInt64) -> ZipEntry? {
        var stat = zip_stat()
        if let index = try? checkZipResult(zip_stat_index(archiveOpt, index, Condition.original.rawValue, &stat)) {
            if index >= 0 {
                return  ZipEntry(archive: self, stat: stat)
            }
        }
        return nil
    }
    
    public func readEntry(entryName: String, caseSensitive: Bool = false) -> ZipEntry?  {
        guard !entryName.isEmpty else {
            return nil
        }
        let index = lookupEntry(entryName, caseSensitive)
        if index >= 0 {
            return readEntry(from: UInt64(index))
        }
        return nil
    }
    
    public func containsEntry(entryName: String, caseSensitive: Bool = false) -> Bool {
        return lookupEntry(entryName, caseSensitive) >= 0
    }
    
    public func containsEntry(entryName: String, caseSensitive: Bool = false, index: inout UInt64) -> Bool {
        let idx = lookupEntry(entryName, caseSensitive)
        if idx >= 0 {
            index = UInt64(idx)
            return true
        }
        return false
    }
    
    public func deleteEntry(index: UInt64) -> Bool {
        return checkIsSuccess(zip_delete(archiveOpt, index))
    }
    
    public func deleteEntry(entryName: String, caseSensitive: Bool) -> Bool {
        guard !entryName.isEmpty else {
            return false
        }
        let index = lookupEntry(entryName, caseSensitive)
        if index >= 0 {
            return deleteEntry(index: UInt64(index))
        }
        return false
    }
    
    public func add
    
    public func addDirectory() {
        
    }
    
}


