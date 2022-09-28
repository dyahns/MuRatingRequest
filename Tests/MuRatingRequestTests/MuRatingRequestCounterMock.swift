import Foundation
@testable import MuRatingRequest

class MuRatingRequestCounterMock: MuRatingRequestCounter {
    var lastVersionPromptedForRating: String? = nil
    var ratingEventsCount: Int = 0
    var appSessionsCount: Int = 0
    var firstOpenDate: Date? = nil
    var currentAppVersion: String? = nil
}
