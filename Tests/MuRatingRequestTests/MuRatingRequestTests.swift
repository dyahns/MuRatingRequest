import XCTest
@testable import MuRatingRequest

final class MuRatingRequestTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertNotNil(
            MuRatingRequestManager(
                configuration: MuRatingRequestManager.Configuration(
                    daysUntilPrompt: 0,
                    sessionsUntilPrompt: 0,
                    eventsUntilPrompt: 0,
                    ignoreAppVersion: true,
                    onRatingRequest: nil
                ),
                prefs: MuRatingRequestCounterMock()
            )
        )
    }
}
