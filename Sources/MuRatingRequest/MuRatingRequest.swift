import StoreKit

public struct MuRatingRequestManager {
    private let configuration: Configuration
    private let prefs: MuRatingRequestCounter
    private let pendingRequest = PendingRequest()
    
    public init(configuration: Configuration,
                prefs: MuRatingRequestCounter = UserDefaults.standard) {
        self.configuration = configuration
        self.prefs = prefs

        // check if we need to reset counters on app update
        checkVersion()
    }
    
    public func requestRating(after time: DispatchTimeInterval = .seconds(2)) {
        guard shouldAskForRating else { return }

        let requestWorkItem = DispatchWorkItem {
            sendRequest()
        }

        pendingRequest.workItem = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: requestWorkItem)
    }
    
    public func didPerformSignificantEvent(weight: Int = 1) {
        cancelPendingRequest()
        prefs.ratingEventsCount += weight
    }
    
    public func countAppSession() {
        cancelPendingRequest()
        prefs.appSessionsCount += 1

        if prefs.firstOpenDate == nil {
            prefs.firstOpenDate = Date()
        }
    }
    
    public func cancelPendingRequest() {
        if pendingRequest.workItem?.isCancelled == false {
            print("Cancelling pending rating request...")
        }
        
        pendingRequest.workItem?.cancel()
    }

    // MARK: - private methods
    
    private func sendRequest() {
        configuration.onRatingRequest?(prefs.configurationState)
        prefs.lastVersionPromptedForRating = applicationVersion

        #if os(macOS)
        SKStoreReviewController.requestReview()
        #else
        if #available(iOS 14.0, *) {
            guard let scene = UIApplication.shared.foregroundActiveScene else { return }
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
        #endif
    }
    
    private var shouldAskForRating: Bool {
        guard let firstLaunchDate = prefs.firstOpenDate else { return false }
        let timeSinceFirstLaunch = Date().timeIntervalSince(firstLaunchDate)
        let timeUntilRate: TimeInterval = 60 * 60 * 24 * TimeInterval(configuration.daysUntilPrompt)
        
        return prefs.appSessionsCount >= configuration.sessionsUntilPrompt &&
        prefs.ratingEventsCount >= configuration.eventsUntilPrompt &&
        timeSinceFirstLaunch >= timeUntilRate &&
        (configuration.ignoreAppVersion || prefs.lastVersionPromptedForRating != applicationVersion)
    }
    
    private var applicationVersion: String? {
        // Get the current bundle version for the app
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let versionInfo = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String else {
            assertionFailure("Expected to find a bundle version in the info dictionary")
            return nil
        }

        return versionInfo
    }
    
    private func checkVersion() {
        guard applicationVersion != prefs.currentAppVersion else { return }

        prefs.currentAppVersion = applicationVersion
        prefs.resetRatingCounters()
    }
    
    // MARK: - configuration
    
    public struct Configuration {
        public typealias RatingRequestedHandler = ((ConfigurationState) -> Void)

        /// The minimum amounts of days until the first prompt should be shown.
        let daysUntilPrompt: Int

        /// The number of app sessions required until the first prompt should be shown.
        let sessionsUntilPrompt: Int

        /// The number of events required until the first prompt should be shown.
        let eventsUntilPrompt: Int

        /// Set to false to limit rating request to one per build
        let ignoreAppVersion: Bool

        /// Will be called after the user is requested for rating.
        let onRatingRequest: RatingRequestedHandler?

        public init(daysUntilPrompt: Int, sessionsUntilPrompt: Int, eventsUntilPrompt: Int, ignoreAppVersion: Bool, onRatingRequest: RatingRequestedHandler?) {
            self.daysUntilPrompt = daysUntilPrompt
            self.sessionsUntilPrompt = sessionsUntilPrompt
            self.eventsUntilPrompt = eventsUntilPrompt
            self.ignoreAppVersion = ignoreAppVersion
            self.onRatingRequest = onRatingRequest
        }
    }
    
    public struct ConfigurationState {
        let lastVersionPromptedForRating: String?
        let ratingEventsCount: Int
        let appSessionsCount: Int
        let firstOpenDate: Date?
    }
    
    class PendingRequest {
        var workItem: DispatchWorkItem?
    }
}
