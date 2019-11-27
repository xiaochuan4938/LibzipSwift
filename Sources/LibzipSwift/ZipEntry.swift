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
    
    public let encryptionMethod: EncryptionMethod
    
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
        self.encryptionMethod = EncryptionMethod(rawValue: stat.encryption_method)
        self.compressionLevel = ZipEntry.getCompressionlevel(stat: stat)
        
        var opsys: UInt8 = 0
        var attributes: UInt32 = 0
        if zip_file_get_external_attributes(archive.handle, stat.index, Condition.original.rawValue, &opsys, &attributes) == ZIP_ER_OK {
            self.externalAttributes = ExternalAttributes(operatingSystem: ZipOSPlatform(rawValue: opsys), attributes: attributes)
        } else {
            self.externalAttributes = ExternalAttributes(operatingSystem: .Dos, attributes: 0)
        }
        
        var fn = String(cString: stat.name!, encoding: .utf8)
        let zipOS = self.externalAttributes.operatingSystem
        if zipOS == .Dos || zipOS == .WINDOWS_NTFS {
            if let zipFN = zip_get_name(archive.handle, index, Encoding.raw.rawValue) {
                // 自动转换档案名编码
                let nameLen = zipFN.withMemoryRebound(to: Int8.self, capacity: 8, {
                    return strlen($0)
                })
                let buff = UnsafeBufferPointer(start: zipFN, count: nameLen)
                let sourceData = Data(buffer: buff)
                var convertedString: NSString?
                _ = NSString.stringEncoding(for: sourceData, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)
                if let cs = convertedString {
                    fn =  cs as String
                }
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
    
    public func setExternalAttributes(operatingSystem: UInt8, attributes: UInt32) throws {
        try checkZipResult(zip_file_set_external_attributes(archive.handle, index, 0, operatingSystem, attributes))
    }
    
    // MARK: - compression
    
    public func setCompression(method: CompressionMethod = .deflate, flags: CompressionLevel = .default) throws {
        try checkZipResult(zip_set_file_compression(archive.handle, index, method.rawValue, flags.rawValue))
    }
    
    // MARK: - encryption
    
    public func setEncryption(method: EncryptionMethod) -> Bool {
        return checkIsSuccess(zip_file_set_encryption(archive.handle, index, method.rawValue, nil))
    }
    
    public func setEncryption(method: EncryptionMethod, password: String) throws {
        try password.withCString { password in
            _ = try checkZipResult(zip_file_set_encryption(archive.handle, index, method.rawValue, password))
        }
    }
    
    // MARK: - modify/remove Entries
    
    public func rename(name: String) -> Bool {
        return name.withCString { name in
            return checkIsSuccess(zip_file_rename(archive.handle, index, name, ZIP_FL_ENC_UTF_8))
        }
    }
    
    public func setModified(date: Date) throws {
        let time = time_t(date.timeIntervalSinceNow)
        try checkZipResult(zip_file_set_mtime(archive.handle, index, time, 0))
    }
    
    // MARK: - discard change
    
    public func discardChange() -> Bool {
        return checkIsSuccess(zip_unchange(archive.handle, index))
    }
    
    // MARK: - uncompress & compress
    
    private func openEntry(password: String = "", mode: OpenMode = .none) throws -> OpaquePointer {
        var zipFileHandler: OpaquePointer
        if password.isEmpty {
            zipFileHandler = try checkZipResult(zip_fopen_index(archive.handle, index, zip_flags_t(mode.rawValue)))
        } else {
            zipFileHandler = try checkZipResult(zip_fopen_index_encrypted(archive.handle, index, zip_flags_t(mode.rawValue), password))
        }
        return zipFileHandler
    }
    
    public func Extract(password: String = "", to data: inout Data) throws -> Bool {
        let handle = try openEntry(password: password, mode: .none)
        
        var readNum: Int64
        var readSize: UInt64
        let count: Int = 1024*100
        let buff = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 8)
        
//        while true {
//            readNum = try zipCast(checkZipResult(zip_fread(handle,buff, zipCast(count))))
//            if readNum <= 0 {
//                break
//            }
//            let buffer = UnsafeBufferPointer(start: buff, count: )
//            let data = Data(buffer: buff)
//            
//            readSize += readNum
//        }
        return false
    }
    
}
