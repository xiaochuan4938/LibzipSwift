import XCTest
@testable import LibzipSwift

final class ZipArchiveTests: XCTestCase {
    func testGetEntries() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
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
    
    func testOpenEntry() {
        
        let fileName = "/Users/martin/Desktop/CodeSign/321.zip"
        do {
            let zipArchive = try ZipArchive(path: fileName)
            defer {
                do {
                    try zipArchive.close()
                } catch { print("关闭 zip archive 失败")}
            }
            let entries = try zipArchive.getEntries()
            for entry in entries {
                entry.Extract(password: <#T##String#>, to: &<#T##Data#>)
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
        ("testOpenEntry", testOpenEntry),
    ]
}


