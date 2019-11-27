import XCTest
@testable import LibzipSwift

final class ZipArchiveTests: XCTestCase {
    func testGetEntries() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
        let fileName = "/Users/MartinLau/Desktop/321.zip"
        
        do {
            let zipArchive = try ZipArchive(path: fileName)
            defer {
                do {
                    try zipArchive.close()
                } catch { print("关闭 zip archive 失败")}
            }
            let entries = try zipArchive.getEntries()
            for entry in entries {
                print("entry name: \(entry.fileName)\n")
                print("entry m_time: \(entry.modificationDate)")
            }
        } catch ZipError.fileNotExist {
            print("文件不存在")
        } catch {
            print("Open Zip Error: ")
            print("\(error.localizedDescription)")
        }
    }
    
    func testExtractExtry() {
        let fileName = "/Users/MartinLau/Desktop/321.zip"
        do {
            let zipArchive = try ZipArchive(path: fileName)
            defer {
                do {
                    try zipArchive.close()
                } catch { print("关闭 zip archive 失败")}
            }
            let entries = try zipArchive.getEntries()
            for entry in entries {
                
            }
            
        } catch ZipError.fileNotExist {
            print("文件不存在")
        } catch {
            print("Open Zip Error: ")
            print("\(error.localizedDescription)")
        }
    }
    
    func testOpenEntry2Data() {
        
//        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
        let fileName = "/Users/MartinLau/Desktop/321.zip"
        do {
            let zipArchive = try ZipArchive(path: fileName)
            defer {
                do {
                    try zipArchive.close()
                } catch { print("关闭 zip archive 失败")}
            }
            let entries = try zipArchive.getEntries()
            for entry in entries {
                if entry.isDirectory {
                    try FileManager.default.createDirectory(atPath: "/Users/MartinLau/Desktop/123/\(entry.fileName)", withIntermediateDirectories: true)
                } else {
                    var data: Data = Data()
                    if try entry.Extract(to: &data) {
                        let filePath = URL(fileURLWithPath: "/Users/MartinLau/Desktop/123/\(entry.fileName)")
                        if !FileManager.default.fileExists(atPath: filePath.deletingLastPathComponent().path) {
                            try FileManager.default.createDirectory(atPath: filePath.deletingLastPathComponent().path, withIntermediateDirectories: true)
                        }
                        try data.write(to: filePath)
                    }
                }
            }
        } catch ZipError.fileNotExist {
            print("文件不存在")
        } catch {
            print("Open Zip Error: ")
            print("\(error.localizedDescription)")
        }
    }
    
    static var allTests = [
//        ("testGetEntries", testGetEntries),
//        ("testOpenEntry2Data", testOpenEntry2Data),
        ("testExtractExtry", testExtractExtry),
    ]
}


