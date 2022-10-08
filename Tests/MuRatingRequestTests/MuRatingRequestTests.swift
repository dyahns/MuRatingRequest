import XCTest
@testable import MuRatingRequest

final class MuRatingRequestTests: XCTestCase {
    var prefs: MuRatingRequestCounter!

    override func setUp() async throws {
        prefs = MuRatingRequestCounterMock()
    }
    
    func testManagerInstantiated() throws {
        let manager = MuRatingRequestManager(configuration: .init(), prefs: prefs)
        XCTAssertNotNil(manager)
    }
    
    func testManagerHasCurrentAppVersion() throws {
        XCTAssertNil(prefs.currentAppVersion)

        let _ = MuRatingRequestManager(configuration: .init(), prefs: prefs)
        XCTAssertNotNil(prefs.currentAppVersion)
        XCTAssertFalse((prefs.currentAppVersion ?? "").isEmpty)
    }

    func testManagerCountsDays() throws {
        let manager = MuRatingRequestManager(configuration: .init(), prefs: prefs)

        XCTAssertNil(prefs.firstOpenDate)
        manager.countAppSession()
        XCTAssertNotNil(prefs.firstOpenDate)
        XCTAssertTrue(Calendar.current.isDate(prefs.firstOpenDate ?? Date.distantPast, inSameDayAs: Date()))
    }

    func testManagerCountsAppSessions() throws {
        let manager = MuRatingRequestManager(configuration: .init(), prefs: prefs)

        XCTAssertEqual(prefs.appSessionsCount, 0)
        manager.countAppSession()
        XCTAssertEqual(prefs.appSessionsCount, 1)
    }

    func testManagerCountsEvents() throws {
        let manager = MuRatingRequestManager(configuration: .init(), prefs: prefs)

        XCTAssertEqual(prefs.ratingEventsCount, 0)
        manager.didPerformSignificantEvent()
        XCTAssertEqual(prefs.ratingEventsCount, 1)
        manager.didPerformSignificantEvent(weight: 3)
        XCTAssertEqual(prefs.ratingEventsCount, 4)
    }
    
    func testManagerTriggersRequestByDays() throws {
        let days = 1
        
        let notYet = XCTestExpectation(description: "Not enough days to trigger request")
        notYet.isInverted = true
        
        let done = XCTestExpectation(description: "Trigger request by days")
        let manager = MuRatingRequestManager(
            configuration: .init(
                daysUntilPrompt: days,
                onRatingRequest: { state in
                    notYet.fulfill()
                    done.fulfill()
                }
            ),
            prefs: prefs
        )

        manager.requestRating(after: nil)
        wait(for: [notYet], timeout: 1)

        prefs.firstOpenDate = Date().addingTimeInterval(TimeInterval(60 * 60 * 24 * -days))
        manager.requestRating(after: nil)
        wait(for: [done], timeout: 1)
    }

    func testManagerTriggersRequestBySessions() throws {
        let notYet = XCTestExpectation(description: "Not enough sessions to trigger request")
        notYet.isInverted = true
        
        let done = XCTestExpectation(description: "Trigger request by sessions")
        let manager = MuRatingRequestManager(
            configuration: .init(
                sessionsUntilPrompt: 1,
                onRatingRequest: { state in
                    notYet.fulfill()
                    done.fulfill()
                }
            ),
            prefs: prefs
        )

        manager.requestRating(after: nil)
        wait(for: [notYet], timeout: 1)

        manager.countAppSession()
        manager.requestRating(after: nil)
        wait(for: [done], timeout: 1)
    }

    func testManagerTriggersRequestByEvents() throws {
        let notYet = XCTestExpectation(description: "Not enough events to trigger request")
        notYet.isInverted = true
        
        let done = XCTestExpectation(description: "Trigger request by events")
        let manager = MuRatingRequestManager(
            configuration: .init(
                eventsUntilPrompt: 2,
                onRatingRequest: { state in
                    notYet.fulfill()
                    done.fulfill()
                }
            ),
            prefs: prefs
        )

        manager.didPerformSignificantEvent()
        manager.requestRating(after: nil)
        wait(for: [notYet], timeout: 1)

        manager.didPerformSignificantEvent()
        manager.requestRating(after: nil)
        wait(for: [done], timeout: 1)
    }

    func testManagerTriggersRequestByAll() throws {
        let days = 1

        let done = XCTestExpectation(description: "Trigger request by all conditions")
        done.assertForOverFulfill = true
        done.expectedFulfillmentCount = 1

        let manager = MuRatingRequestManager(
            configuration: .init(
                daysUntilPrompt: days,
                sessionsUntilPrompt: 1,
                eventsUntilPrompt: 1,
                onRatingRequest: { state in
                    done.fulfill()
                }
            ),
            prefs: prefs
        )

        prefs.firstOpenDate = Date().addingTimeInterval(TimeInterval(60 * 60 * 24 * -days))
        manager.requestRating(after: nil)

        manager.countAppSession()
        manager.requestRating(after: nil)

        manager.didPerformSignificantEvent()
        manager.requestRating(after: nil)

        // next one should be ignored based on last triggered app version
        manager.requestRating(after: nil)
        wait(for: [done], timeout: 1)
    }

    func testManagerTriggersDelayedRequest() throws {
        let done = XCTestExpectation(description: "Trigger delayed request")

        let manager = MuRatingRequestManager(
            configuration: .init(
                onRatingRequest: { state in
                    done.fulfill()
                }
            ),
            prefs: prefs
        )

        manager.requestRating(after: .seconds(1))
        wait(for: [done], timeout: 2)
    }

    func testManagerCancelsPendingRequest() throws {
        let notYet = XCTestExpectation(description: "Pending request is cancelled")
        notYet.isInverted = true

        let manager = MuRatingRequestManager(
            configuration: .init(
                onRatingRequest: { state in
                    notYet.fulfill()
                }
            ),
            prefs: prefs
        )

        manager.requestRating(after: .seconds(1))
        manager.cancelPendingRequest()
        wait(for: [notYet], timeout: 2)
    }

    func testManagerResetsCountersOnNewBuild() {
        let lastPromptedVersion = "0.0.0"
        
        let prefs = MuRatingRequestCounterMock()
        prefs.lastVersionPromptedForRating = lastPromptedVersion
        prefs.ratingEventsCount = 12
        prefs.appSessionsCount = 23
        prefs.firstOpenDate = Date()

        let _ = MuRatingRequestManager(
            configuration: .init(),
            prefs: prefs
        )

        XCTAssertEqual(prefs.lastVersionPromptedForRating, lastPromptedVersion)
        XCTAssertEqual(prefs.appSessionsCount, 0)
        XCTAssertEqual(prefs.ratingEventsCount, 0)
        XCTAssertNil(prefs.firstOpenDate)
        XCTAssertNotNil(prefs.currentAppVersion)
    }
}
