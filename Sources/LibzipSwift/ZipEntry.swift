import libzip
import Foundation

public final class ZipEntry: ZipErrorContext {
    
    let archive: ZipArchive
    let stat: zip_stat
    
//    private let vaild: zip_uint64_t
//    private let localExtraFieldsCount: CShort
//    private let centralExtraFieldsCount: CShort
    
    // MARK: - property
    
    public let CRC: UInt
    
    public let index: zip_uint64_t
    
    public let fileName: String
    
    public let isDirectory: Bool
    
    public let modificationDate: Date
    
    public let isSymbolicLink: Bool
    
    public let posixPermission: UInt16
    
    public let compressedSize: UInt64
    
    public let uncompressedSize: UInt64
    
    public let compressionMethod: CompressionMethod
    
    public let compressionLevel: CompressionLevel
    
//    public let encryptionMethod: EncryptionMethod
    
    public let externalAttributes: ExternalAttributes
    
    public var error: ZipError? {
        return archive.error
    }
    
    // MARK: - static function
    
    fileprivate struct FileType: RawRepresentable {
        
        public let rawValue: mode_t
        public init(rawValue: mode_t) {
            self.rawValue = rawValue
        }
        
        fileprivate static let IFO = FileType(rawValue: S_IFIFO)
        fileprivate static let CHR = FileType(rawValue: S_IFCHR)
        fileprivate static let DIR = FileType(rawValue: S_IFDIR)
        fileprivate static let BLK = FileType(rawValue: S_IFBLK)
        fileprivate static let REG = FileType(rawValue: S_IFREG)
        fileprivate static let LNK = FileType(rawValue: S_IFLNK)
        fileprivate static let SOCK = FileType(rawValue: S_IFSOCK)
    }
    
    private static func getCompressionlevel(stat: zip_stat) -> CompressionLevel {
        var level:CompressionLevel = .default
        if stat.comp_method != 0 {
            switch (((stat.flags & 0x6) / 2)) {
            case 0:
                level = .default
            case 1:
                level = .best
            default:
                level = .fastest
            }
        }
        return level
    }
    
    private static func itemFileType(_ attributes: UInt32) -> FileType {
        return FileType(rawValue: (S_IFMT & UInt16((attributes >> 16))))
    }
    
    private static func itemIsDOSDirectory(_ attributes: UInt32) -> Bool {
        return 0x01 & (attributes >> 4) != 0;
    }
    
    private static func itemIsDirectory(_ externalAttributes: ExternalAttributes) -> Bool {
        if externalAttributes.operatingSystem == .Dos || externalAttributes.operatingSystem == .WINDOWS_NTFS {
            return ZipEntry.itemIsDOSDirectory(externalAttributes.attributes)
        }
        return itemFileType(externalAttributes.attributes) == .DIR
    }
    
    private static func itemPermissions(_ attributes: UInt32) -> UInt16 {
        let permissionsMask = S_IRWXU | S_IRWXG | S_IRWXO;
        return permissionsMask & UInt16(attributes >> 16)
    }
    
    private static func itemIsSymbolicLink(_ attributes: UInt32) -> Bool {
        return itemFileType(attributes) == .LNK
    }
    
    // MARK: - init
    
    public init(archive: ZipArchive, stat: zip_stat) throws {
        self.archive = archive
        self.stat = stat
//        self.vaild = stat.valid
        
        self.compressedSize = stat.comp_size
        self.uncompressedSize = stat.size
        self.index = stat.index
        self.CRC = UInt(stat.crc)
        
        self.modificationDate = Date(timeIntervalSince1970: TimeInterval(stat.mtime))
        self.compressionMethod = CompressionMethod(rawValue: Int32(stat.comp_method))
        self.compressionLevel = ZipEntry.getCompressionlevel(stat: stat)
        
        var opsys: UInt8 = 0
        var attributes: UInt32 = 0
        if zip_file_get_external_attributes(archive.handle, stat.index, Condition.original.rawValue, &opsys, &attributes) == ZIP_ER_OK {
            self.externalAttributes = ExternalAttributes(operatingSystem: ZipOSPlatform(rawValue: opsys), attributes: attributes)
        } else {
            self.externalAttributes = ExternalAttributes(operatingSystem: .Dos, attributes: 0)
        }
        
        var fn = String(cString: stat.name!, encoding: .utf8)
        if self.externalAttributes.operatingSystem == .Dos {
            let cChar = zip_get_name(archive.handle, index, Encoding.raw.rawValue)
            if let cChar = cChar {
                fn = String(cString: cChar, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0930)))!
            }
        }
        if let fn = fn {
            self.fileName = fn
        } else {
            self.fileName = ""
        }
        self.isDirectory = ZipEntry.itemIsDirectory(self.externalAttributes)
        self.posixPermission = UInt16(ZipEntry.itemPermissions(self.externalAttributes.attributes))
        self.isSymbolicLink = ZipEntry.itemIsSymbolicLink(self.externalAttributes.attributes)
    }
    
    // MARK: - Attributes
    
//    public func getExternalAttributes(version: ZipArchive.Version = .current) throws -> ExternalAttributes {
//        var operatingSystem: UInt8 = 0
//        var attributes: UInt32 = 0
//        try zipCheckResult(zip_file_get_external_attributes(archive.handle, index, version.rawValue, &operatingSystem, &attributes))
//        return ExternalAttributes(operatingSystem: operatingSystem, attributes: attributes)
//    }
//
//    public func setExternalAttributes(operatingSystem: UInt8, attributes: UInt32) throws {
//        try zipCheckResult(zip_file_set_external_attributes(archive.handle, index, 0, operatingSystem, attributes))
//    }
    
    // MARK: - compression
    
    
//    public func setCompression(method: CompressionMethod = .default, flags: CompressionFlags = .default) throws {
//        try zipCheckResult(zip_set_file_compression(archive.handle, index, method.rawValue, flags.rawValue))
//    }
    
    // MARK: - encryption
    
//    public func setEncryption(method: EncryptionMethod) throws {
//        try zipCheckResult(zip_file_set_encryption(archive.handle, index, method.rawValue, nil))
//    }
    
//    public func setEncryption(method: EncryptionMethod, password: String) throws {
//        try password.withCString { password in
//            _ = try zipCheckResult(zip_file_set_encryption(archive.handle, index, method.rawValue, password))
//        }
//    }
    
    // MARK: - modify/remove Entries
    
    public func rename(name: String) {
        
    }
    
//    public func rename(name: String) throws {
//        try name.withCString { name in
//            _ = try zipCheckResult(zip_file_rename(archive.handle, index, name, ZIP_FL_ENC_UTF_8))
//        }
//    }
    
//    public func setModified(time: time_t) throws {
//        try zipCheckResult(zip_file_set_mtime(archive.handle, index, time, 0))
//    }
    
    // MARK: - discard change
    
    public func discardChange() -> Bool {
        return checkIsSuccess(zip_unchange(archive.handle, index))
    }
}
