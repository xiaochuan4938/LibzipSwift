import XCTest
@testable import LibzipSwift

final class LibzipSwiftTests: XCTestCase {
    
    let baseDirectory: String = "TestData"
    var docArchive: String {
        get {
            return Bundle(for: self.classForCoder).url(forResource: "doc_archive", withExtension: nil, subdirectory: baseDirectory)!.path
        }
    }
    
    var winArchive: String {
        get {
            return URL(fileURLWithPath: baseDirectory).appendingPathComponent("win_archive.zip").path
        }
    }
    
    var unixArchive: String {
        get {
            return URL(fileURLWithPath: baseDirectory).appendingPathComponent("unix_archive.zip").path
        }
    }
    
    var encryptArchive: String {
        get {
            return URL(fileURLWithPath: baseDirectory).appendingPathComponent("encrypt_Archive.zip").path
        }
    }
    
    func testNewArchive() {
        
    }
    
    func testIsZipArchive() {
        XCTAssertEqual(ZipArchive.isZipArchive(path: URL(fileURLWithPath: docArchive)), true, "this is not a zip archive file")
        XCTAssertEqual(ZipArchive.isZipArchive(path: URL(fileURLWithPath: winArchive)), true, "this is not a zip archive file")
//        XCTAssertEqual(ZipArchive.isZipArchive(path: URL(fileURLWithPath: unixArchive)), true, "this is not a zip archive file")
//        XCTAssertEqual(ZipArchive.isZipArchive(path: URL(fileURLWithPath: encryptArchive)), true, "this is not a zip archive file")
    }
    
    func testListEntries() {
        do {
            let zipArchive = try ZipArchive(path: docArchive)
            defer {
                try? zipArchive.close()
            }
            if let entries = try? zipArchive.getEntries() {
                let expected = ["programmer.png", "繁體中文/時間", "繁體中文/文本檔案.txt", "简体中文/新建文本档案.txt"]
                let actual = entries.map { $0.fileName }
                XCTAssertEqual(actual, expected)
            }
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }
    
    func testArchiveExtract() {
        
    }
    
    func testUpdateEntry() {
        
    }
    
    func testRemoveEntry() {
        
    }
    
    func testReameEntry() {
        
    }
    
    static var allTests = [
        ("testIsZipArchive",   testIsZipArchive),
        ("testNewArchive",     testNewArchive),
        ("testListEntries",    testListEntries),
        ("testArchiveExtract", testArchiveExtract),
        ("testUpdateEntry",    testUpdateEntry),
        ("testRemoveEntry",    testRemoveEntry),
        ("testReameEntry",     testReameEntry),
    ]
}
