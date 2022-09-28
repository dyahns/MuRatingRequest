import Foundation

public protocol MuRatingRequestCounter: AnyObject {
    var lastVersionPromptedForRating: String? { get set }
    var ratingEventsCount: Int { get set }
    var appSessionsCount: Int { get set }
    var firstOpenDate: Date? { get set }
    var currentAppVersion: String? { get set }
}

extension MuRatingRequestCounter {
    var configurationState: MuRatingRequestManager.ConfigurationState {
        MuRatingRequestManager.ConfigurationState(lastVersionPromptedForRating: lastVersionPromptedForRating, ratingEventsCount: ratingEventsCount, appSessionsCount: appSessionsCount, firstOpenDate: firstOpenDate)
    }

    func resetRatingCounters() {
        firstOpenDate = Date()
        appSessionsCount = 0
        ratingEventsCount = 0
    }
}
