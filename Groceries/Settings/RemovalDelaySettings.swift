import Foundation

enum RemovalDelaySettings {
    static let storageKey = "removalDelaySeconds"
    static let defaultSeconds = 15

    static var currentSeconds: Int {
        let storedDelay = UserDefaults.standard.integer(forKey: storageKey)
        return storedDelay == 0 ? defaultSeconds : storedDelay
    }

    static func setLocalSeconds(_ seconds: Int, syncsToICloud: Bool = true) {
        UserDefaults.standard.set(seconds, forKey: storageKey)

        if syncsToICloud {
            ICloudSettingsSync.shared.saveRemovalDelay(seconds)
        }
    }
}
