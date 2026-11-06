import XCTest
@testable import GalleryApp

final class AppConfigurationTests: XCTestCase {
    func testInitThrowsWhenAccessKeyIsMissing() {
        XCTAssertThrowsError(try AppConfiguration(infoDictionary: [:])) { error in
            XCTAssertEqual(error as? AppConfiguration.ConfigurationError, .missingAccessKey)
        }
    }

    func testInitThrowsWhenAccessKeyIsBlank() {
        let dictionary = ["UNSPLASH_ACCESS_KEY": "   \n"]

        XCTAssertThrowsError(try AppConfiguration(infoDictionary: dictionary)) { error in
            XCTAssertEqual(error as? AppConfiguration.ConfigurationError, .missingAccessKey)
        }
    }

    func testInitThrowsWhenAccessKeyIsAnUnresolvedBuildSetting() {
        let dictionary = ["UNSPLASH_ACCESS_KEY": "$(UNSPLASH_ACCESS_KEY)"]

        XCTAssertThrowsError(try AppConfiguration(infoDictionary: dictionary)) { error in
            XCTAssertEqual(error as? AppConfiguration.ConfigurationError, .missingAccessKey)
        }
    }

    func testInitExposesTrimmedAccessKey() throws {
        let dictionary = ["UNSPLASH_ACCESS_KEY": "  public-access-key \n"]

        let configuration = try AppConfiguration(infoDictionary: dictionary)

        XCTAssertEqual(configuration.accessKey, "public-access-key")
    }
}
