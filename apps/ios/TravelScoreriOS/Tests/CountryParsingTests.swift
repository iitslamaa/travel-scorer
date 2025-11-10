import XCTest
@testable import TravelScoreriOS

final class CountryParsingTests: XCTestCase {
    func testCountriesParse() throws {
        let url = Bundle.main.url(forResource: "countries", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([Country].self, from: data)
        XCTAssertFalse(decoded.isEmpty)
    }
}