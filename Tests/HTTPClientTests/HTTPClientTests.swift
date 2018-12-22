import XCTest
@testable import HTTPClient

final class HTTPClientTests: XCTestCase {

    let client:HTTPClient = HTTPClient(context: AuthContext.default)

    func test_001_storage_save() {
        let storage:Storage = Storage.shared
        do{
            try storage.load(for: client)
            XCTFail("Storage.load should fail")
        }catch{
            // OK
        }
        storage.credentials?.account = "alfred@apple.com"
        storage.credentials?.password = "pschittt1984"

        do{
            try storage.save(for: client)
            XCTFail("Storage.load should fail")
        }catch{
            // OK
        }
    }

    static var allTests = [
        ("test_001_storage_save", test_001_storage_save),
    ]
}
