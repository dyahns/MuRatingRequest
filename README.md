# Apple App Store Rating Request Manager

### SPM package for managing conditional in-app rating requests for iOS and macOS apps using `SKStoreReviewController.requestReview`.
 
Rating request manager tracks 
- days since first launch, 
- number of app sessions,
- number of custom events,
- app version.

A call to `StoreKit`'s `SKStoreReviewController.requestReview(in:)` will fire only when all conditions are met. 

Successful rating requests can be optionally delayed and cancelled while pending in order to avoid interrupting the user if the user continues to interact with the app.

## How to use

1. In XCode menu select File | Add Packages...; provide the URL to this github repo and add the package to the project.
2. Add `Import MuRatingRequest` in the files you intend to use MuRatingRequest's APIs.
3. Initialise the manager passing in conditions to be met before rating request will be triggered.

``` swift
let manager = MuRatingRequestManager(
    configuration: .init(
        daysUntilPrompt: 10,
        sessionsUntilPrompt: 10,
        eventsUntilPrompt: 20,
        ignoreAppVersion: false // default
    )
)
```

4. Add tracking calls where necessary. 

- `MuRatingRequestManager.countAppSession()` records both the first launch date and number of sessions. You may want to put this call in `AppDelegate.application(_:,didFinishLaunchingWithOptions:)`.
- `MuRatingRequestManager.didPerformSignificantEvent(weight: Int = 1)` records your custom events, optionally with weights higher than 1, that will contribute towards `eventsUntilPrompt` condition.

5. Add a call to `MuRatingRequestManager.requestRating(after:)` somewhere where it would make sense from UX perspective. This call will only translate to `SKStoreReviewController.requestReview(in:)` when all conditions are met.

    By default, rating request is triggered once per app build/version. You can change that by passing `ignoreAppVersion` set to true when configuring conditions. In the latter case, all the counters are reset and will need to be met again for the request to be re-triggered.
    
    Counters also get reset on first launch after updating the app to a new version. Events tracked after triggering rating request for the previous app version are discarded and won't count towards the new version.

6. Given that conditions are met, `MuRatingRequestManager.requestRating(after:)` schedules the rating request to fire after delay (2 seconds by default). You can specify your own value or pass `nil` for the request to fire immediately. Pending request can be cancelled using `MuRatingRequestManager.cancelPendingRequest()`, for example in case the user continues to interact with the app. 
