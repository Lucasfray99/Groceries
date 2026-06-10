import Foundation

enum WatchRemovalDelaySettings {
    static let storageKey = "removalDelaySeconds"
    static let defaultSeconds = 15

    static var currentSeconds: Int {
        let storedDelay = UserDefaults.standard.integer(forKey: storageKey)
        return storedDelay == 0 ? defaultSeconds : storedDelay
    }
}
