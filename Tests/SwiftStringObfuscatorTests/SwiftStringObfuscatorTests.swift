@testable import SwiftStringObfuscatorCore
import SwiftSyntax
import XCTest

final class SwiftStringObfuscatorTests: XCTestCase {
    let sampleFileURL = urlTempString("""
    let apiKey = "something-secret"

    let apiKey2 = "something-secret-without-spaces"

    //useless line, only for test purposes

    let nonObfuscated: String = "non-obfuscated-string\\(1)"

    struct XStruct {
        let x: Int

        let apiKey3 =  "key-in-struct"

        var param: String {
            return "key-in-computed-property"
        }

        var dynamic2: String {
            "key-in-computed-property-2"
        }
    }

    class Y {
        static let keyInClass: String = "api-key-in-class"

        func apiFuncParam(_ key: String) { return }
    }

    func test() {
        let testClass = Y()
        testClass.apiFuncParam("api_key_func_param")
    }
    """)

    let sampleObfuscatedOutput = """
    let apiKey = String(data: Data(base64Encoded: String(bytes: [99, 50, 57, 116, 90, 88, 82, 111, 97, 87, 53, 110, 76, 88, 78, 108, 89, 51, 74, 108, 100, 65, 61, 61], encoding: .utf8)!)!, encoding: .utf8)!

    let apiKey2 = String(data: Data(base64Encoded: String(bytes: [99, 50, 57, 116, 90, 88, 82, 111, 97, 87, 53, 110, 76, 88, 78, 108, 89, 51, 74, 108, 100, 67, 49, 51, 97, 88, 82, 111, 98, 51, 86, 48, 76, 88, 78, 119, 89, 87, 78, 108, 99, 119, 61, 61], encoding: .utf8)!)!, encoding: .utf8)!

    //useless line, only for test purposes

    let nonObfuscated: String = "non-obfuscated-string\\(1)"

    struct XStruct {
        let x: Int

        let apiKey3 =  String(data: Data(base64Encoded: String(bytes: [97, 50, 86, 53, 76, 87, 108, 117, 76, 88, 78, 48, 99, 110, 86, 106, 100, 65, 61, 61], encoding: .utf8)!)!, encoding: .utf8)!

        var param: String {
            return String(data: Data(base64Encoded: String(bytes: [97, 50, 86, 53, 76, 87, 108, 117, 76, 87, 78, 118, 98, 88, 66, 49, 100, 71, 86, 107, 76, 88, 66, 121, 98, 51, 66, 108, 99, 110, 82, 53], encoding: .utf8)!)!, encoding: .utf8)!
        }

        var dynamic2: String {
            String(data: Data(base64Encoded: String(bytes: [97, 50, 86, 53, 76, 87, 108, 117, 76, 87, 78, 118, 98, 88, 66, 49, 100, 71, 86, 107, 76, 88, 66, 121, 98, 51, 66, 108, 99, 110, 82, 53, 76, 84, 73, 61], encoding: .utf8)!)!, encoding: .utf8)!
        }
    }

    class Y {
        static let keyInClass: String = String(data: Data(base64Encoded: String(bytes: [89, 88, 66, 112, 76, 87, 116, 108, 101, 83, 49, 112, 98, 105, 49, 106, 98, 71, 70, 122, 99, 119, 61, 61], encoding: .utf8)!)!, encoding: .utf8)!

        func apiFuncParam(_ key: String) { return }
    }

    func test() {
        let testClass = Y()
        testClass.apiFuncParam(String(data: Data(base64Encoded: String(bytes: [89, 88, 66, 112, 88, 50, 116, 108, 101, 86, 57, 109, 100, 87, 53, 106, 88, 51, 66, 104, 99, 109, 70, 116], encoding: .utf8)!)!, encoding: .utf8)!)
    }
    """

    func testObfuscator() throws {
        let obfuscated = try? StringObfuscator.getObfuscatedContent(for: sampleFileURL)

        XCTAssertEqual(obfuscated, sampleObfuscatedOutput)
    }

    static var allTests = [("testObfuscator", testObfuscator)]

    static func urlTempString(_ str: String) -> URL {
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().uuidString
        let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])!

        try! str.write(to: fullURL, atomically: true, encoding: .utf8)

        return fullURL
    }
}
