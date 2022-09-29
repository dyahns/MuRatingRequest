import StoreKit

/// Rating request manager tracks days since first launch, number of app sessions and number of custom events before the rating request will be triggered by a ``requestRating(after:)`` call.
///
/// Pass conditions in the initialiser:
/// ``` swift
/// let manager = MuRatingRequestManager(
///     configuration: .init(
///         daysUntilPrompt: 10,
///         sessionsUntilPrompt: 10,
///         eventsUntilPrompt: 20
///     )
/// )
/// ```
///
/// Condition tracking is controlled by calling ``countAppSession()`` for first launch and sessions and by calling ``didPerformSignificantEvent(weight:)`` for custom events. After update, all the condition counters will get reset on the first launch of the app
///
/// Method ``requestRating(after:)`` allows triggering the request after delay, giving the opportunity for the app to cancel pending request in the event of user interactions and such.
public struct MuRatingRequestManager {
    private let configuration: Configuration
    private let prefs: MuRatingRequestCounter
    private let pendingRequest = PendingRequest()
    
    /// Creates an instance of ``MuRatingRequestManager`` with a given condition for showing rating request
    /// 
    /// - Parameters:
    ///   - configuration: ``Configuration`` defines conditions for showing rating request.
    ///   - prefs: Optional parameter. `UserDefaults.standard` is used by default with ``MuRatingRequestCounter`` implementation provided by the package.
    public init(configuration: Configuration,
                prefs: MuRatingRequestCounter = UserDefaults.standard) {
        self.configuration = configuration
        self.prefs = prefs

        // check if we need to reset counters on app update
        checkVersion()
    }
    
    /// Checks if all conditions are met first and then triggers the rating request
    /// - Parameters:
    ///   - after: If request conditions are met, this parameter defines the interval the request will be delay by. Default delay is `.seconds(2)`. Pending request can be canceled using ``cancelPendingRequest()``. If `nil` is passed, the request will be executed immediately, given conditions are met.
    public func requestRating(after delay: DispatchTimeInterval? = .seconds(2)) {
        // cancel pending request
        pendingRequest.workItem?.cancel()
        
        // check is request condition is met
        guard shouldAskForRating else { return }

        // execute request immediately if delay not set
        guard let delay = delay else {
            sendRequest()
            return
        }

        // ignore request if delay is never
        guard delay != .never else { return }
            
        // dispatch request after delay
        let requestWorkItem = DispatchWorkItem { sendRequest() }
        pendingRequest.workItem = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: requestWorkItem)
    }
    
    /// Tracks custom events before rating request
    /// - Parameters:
    ///   - weight: Increment for particular tracked event. Default value is 1.
    public func didPerformSignificantEvent(weight: Int = 1) {
        cancelPendingRequest()
        prefs.ratingEventsCount += weight
    }
    
    /// Tracks both days and sessions before rating request
    public func countAppSession() {
        cancelPendingRequest()
        prefs.appSessionsCount += 1

        if prefs.firstOpenDate == nil {
            prefs.firstOpenDate = Date()
        }
    }
    
    /// Cancels pending rating request, if it was triggered with a delay
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

        // reset counters for the scenario where Configuration.ignoreAppVersion is set to true
        prefs.resetRatingCounters()

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
        var passedDaysUntilPrompt: Bool {
            guard let firstLaunchDate = prefs.firstOpenDate else {
                // allow nil open date if threshold is 0
                return configuration.daysUntilPrompt == 0
            }
            
            let timeSinceFirstLaunch = Date().timeIntervalSince(firstLaunchDate)
            let timeUntilRate: TimeInterval = 60 * 60 * 24 * TimeInterval(configuration.daysUntilPrompt)
            return timeSinceFirstLaunch >= timeUntilRate
        }
        
        return prefs.appSessionsCount >= configuration.sessionsUntilPrompt &&
        prefs.ratingEventsCount >= configuration.eventsUntilPrompt &&
        passedDaysUntilPrompt &&
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
        guard let applicationVersion = applicationVersion,
              applicationVersion != prefs.currentAppVersion else { return }

        prefs.currentAppVersion = applicationVersion
        prefs.resetRatingCounters()
    }
    
    private class PendingRequest {
        var workItem: DispatchWorkItem?
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

        /// Handler called after the rating has been requested. Passes the current ``ConfigurationState`` of the ``MuRatingRequestCounter`` instance used by the manager.
        let onRatingRequest: RatingRequestedHandler?

        public init(daysUntilPrompt: Int = 0, sessionsUntilPrompt: Int = 0, eventsUntilPrompt: Int = 0, ignoreAppVersion: Bool = false, onRatingRequest: RatingRequestedHandler? = nil) {
            self.daysUntilPrompt = daysUntilPrompt
            self.sessionsUntilPrompt = sessionsUntilPrompt
            self.eventsUntilPrompt = eventsUntilPrompt
            self.ignoreAppVersion = ignoreAppVersion
            self.onRatingRequest = onRatingRequest
        }
    }
    
    /// Current state of the ``MuRatingRequestCounter`` instance used by the manager
    public struct ConfigurationState {
        let lastVersionPromptedForRating: String?
        let ratingEventsCount: Int
        let appSessionsCount: Int
        let firstOpenDate: Date?
    }
}
