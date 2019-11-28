import XCTest
@testable import LibzipSwift

final class ZipArchiveTests: XCTestCase {
    func testGetEntries() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
        //        let fileName = "/Users/MartinLau/Desktop/321.zip"
        
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
    
    func testExtractEntry() {
        let fileName = "/Users/martin/Desktop/CodeSign/123test.ipa"   //"/Users/martin/Desktop/CodeSign/123.zip"
        //        let fileName = "/Users/MartinLau/Desktop/321.zip"
        do {
            let zipArchive = try ZipArchive(path: fileName)
            defer {
                do {
                    try zipArchive.close()
                } catch { print("关闭 zip archive 失败")}
            }
            let entries = try zipArchive.getEntries()
            for entry in entries {
//                if try entry.Extract(to: "/Users/martin/Desktop/CodeSign/123/\(entry.fileName)") { (item, progress) -> Bool in
//                    print("extracting item:\(item)\n\(progress)")
//                    return true
//                    } {
//                    print("success")
//                } else {
//                    print("fail")
//                }
                let result = try entry.extract(to: "/Users/martin/Desktop/CodeSign/123/\(entry.fileName)", nil)
                assert(result, "解压缩发生错误")
            }
            print("222")
        } catch ZipError.fileNotExist {
            print("文件不存在")
        } catch {
            print("Error : \(error.localizedDescription)")
        }
    }
    
    func testOpenEntry2Data() {
        
        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
        //        let fileName = "/Users/MartinLau/Desktop/321.zip"
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
                    if try entry.extract(to: &data) {
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
        ("testExtractEntry", testExtractEntry),
    ]
}


