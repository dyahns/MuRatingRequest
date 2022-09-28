import Foundation

extension UserDefaults: MuRatingRequestCounter {
    public var lastVersionPromptedForRating: String? {
        get {
            return self.string(forKey: Constant.Key.lastVersionPromptedForRating)
        }
        set(newValue) {
            self.set(newValue, forKey: Constant.Key.lastVersionPromptedForRating)
            print("Last version prompted for rating set to \(newValue ?? "n/a") and saved!")
        }
    }
    
    public var ratingEventsCount: Int {
        get {
            return self.integer(forKey: Constant.Key.ratingEventsCount)
        }
        set(newValue) {
            self.set(newValue, forKey: Constant.Key.ratingEventsCount)
            print("Rating event count set to \(newValue) and saved!")
        }
    }
    
    public var appSessionsCount: Int {
        get {
            return self.integer(forKey: Constant.Key.appSessionsCount)
        }
        set(newValue) {
            self.set(newValue, forKey: Constant.Key.appSessionsCount)
            print("App session count set to \(newValue) and saved!")
        }
    }

    public var firstOpenDate: Date? {
        get {
            return self.object(forKey: Constant.Key.firstOpenDate) as? Date
        }
        set(newValue) {
            self.set(newValue, forKey: Constant.Key.firstOpenDate)
            print("First open date set to \(newValue?.description ?? "") and saved!")
        }
    }
    
    public var currentAppVersion: String? {
        get {
            return self.string(forKey: Constant.Key.versionForRatingRequestCounters)
        }
        set(newValue) {
            self.set(newValue, forKey: Constant.Key.versionForRatingRequestCounters)
            print("Version used for rating counters set to \(newValue ?? "n/a") and saved!")
        }
    }
}
