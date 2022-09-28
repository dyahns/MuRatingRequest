import Foundation

public protocol MuRatingRequestCounter: AnyObject {
    /// Updated with the current app version on rating request
    var lastVersionPromptedForRating: String? { get set }
    
    // Event counter for the current version
    var ratingEventsCount: Int { get set }
    
    // Session counter for the current version
    var appSessionsCount: Int { get set }
    
    /// First use date of the current app version
    var firstOpenDate: Date? { get set }
    
    /// Updated with the current app version on first use
    var currentAppVersion: String? { get set }
}

extension MuRatingRequestCounter {
    var configurationState: MuRatingRequestManager.ConfigurationState {
        MuRatingRequestManager.ConfigurationState(lastVersionPromptedForRating: lastVersionPromptedForRating, ratingEventsCount: ratingEventsCount, appSessionsCount: appSessionsCount, firstOpenDate: firstOpenDate)
    }

    func resetRatingCounters() {
        firstOpenDate = nil
        appSessionsCount = 0
        ratingEventsCount = 0
    }
}
