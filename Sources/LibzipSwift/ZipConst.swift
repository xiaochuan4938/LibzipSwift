import libzip
import Foundation

// MARK: - struct

public struct CompressionMethod: RawRepresentable {
    public let rawValue: Int32
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let `default` = CompressionMethod(rawValue: ZIP_CM_DEFAULT)
    public static let store = CompressionMethod(rawValue: ZIP_CM_STORE)
    public static let deflate = CompressionMethod(rawValue: ZIP_CM_DEFLATE)
    public static let deflate64 = CompressionMethod(rawValue: ZIP_CM_DEFLATE64)
}

public struct EncryptionMethod: RawRepresentable {
    public let rawValue: UInt16
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public static let none = EncryptionMethod(rawValue: UInt16(ZIP_EM_NONE))
    public static let aes128 = EncryptionMethod(rawValue: UInt16(ZIP_EM_AES_128))
    public static let aes192 = EncryptionMethod(rawValue: UInt16(ZIP_EM_AES_192))
    public static let aes256 = EncryptionMethod(rawValue: UInt16(ZIP_EM_AES_256))
}

public struct CompressionLevel: RawRepresentable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let `default` = CompressionLevel(rawValue: 0)
    public static let fastest = CompressionLevel(rawValue: 1)
    public static let best = CompressionLevel(rawValue: 9)
}

public struct ExternalAttributes {
    public let operatingSystem: ZipOSPlatform
    public let attributes: UInt32
}

/// entry condition
public struct Condition: RawRepresentable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let original = Condition(rawValue: ZIP_FL_UNCHANGED)
    public static let last = Condition(rawValue: 0)
}

/// zip Encoding
public struct Encoding: RawRepresentable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let guess = Encoding(rawValue: ZIP_FL_ENC_GUESS)
    public static let strict = Encoding(rawValue: ZIP_FL_ENC_STRICT)
    public static let raw = Encoding(rawValue: ZIP_FL_ENC_RAW)
    public static let utf8 = Encoding(rawValue: ZIP_FL_ENC_UTF_8)
}

/// zip OS Platform
public struct ZipOSPlatform: OptionSet {
    public let rawValue: UInt8
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let Dos               = ZipOSPlatform(rawValue: 0x00)
    public static let UNIX              = ZipOSPlatform(rawValue: 0x03)
    public static let OS_2              = ZipOSPlatform(rawValue: 0x06)
    public static let MACINTOSH         = ZipOSPlatform(rawValue: 0x07)
    public static let WINDOWS_NTFS      = ZipOSPlatform(rawValue: 0x0a)
    public static let OS_X              = ZipOSPlatform(rawValue: 0x013)
}



// MARK: - Optional Unwrapping

extension Optional {
    internal func unwrapped() throws -> Wrapped {
        switch self {
        case let .some(value):
            return value
        case .none:
            assertionFailure()
            throw ZipError.internalInconsistency
        }
    }
    
    internal func unwrapped(or error: zip_error) throws -> Wrapped {
        switch self {
        case let .some(value):
            return value
        case .none:
            throw ZipError.zipError(error)
        }
    }
}

// MARK: - Int Cast

internal func zipCast<T, U>(_ value: T) throws -> U where T: BinaryInteger, U: BinaryInteger {
    if let result = U(exactly: value) {
        return result
    } else {
        throw ZipError.integerCastFailed
    }
}