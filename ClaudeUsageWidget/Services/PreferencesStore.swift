import Foundation
import Observation

enum PreferencesKey: String {
    case pollingInterval = "pollingInterval"
    case fiveHourThreshold = "fiveHourThreshold"
    case sevenDayThreshold = "sevenDayThreshold"
    case fiveHourNotificationsEnabled = "fiveHourNotificationsEnabled"
    case sevenDayNotificationsEnabled = "sevenDayNotificationsEnabled"
}

@Observable
@MainActor
final class PreferencesStore {

    // unit: minutes — multiply by 60 before passing to PollingScheduler
    var pollingInterval: Double = 5.0 {
        didSet { UserDefaults.standard.set(pollingInterval, forKey: PreferencesKey.pollingInterval.rawValue) }
    }
    var fiveHourThreshold: Double = 80.0 {
        didSet { UserDefaults.standard.set(fiveHourThreshold, forKey: PreferencesKey.fiveHourThreshold.rawValue) }
    }
    var sevenDayThreshold: Double = 80.0 {
        didSet { UserDefaults.standard.set(sevenDayThreshold, forKey: PreferencesKey.sevenDayThreshold.rawValue) }
    }
    var fiveHourNotificationsEnabled: Bool = false {
        didSet { UserDefaults.standard.set(fiveHourNotificationsEnabled, forKey: PreferencesKey.fiveHourNotificationsEnabled.rawValue) }
    }
    var sevenDayNotificationsEnabled: Bool = false {
        didSet { UserDefaults.standard.set(sevenDayNotificationsEnabled, forKey: PreferencesKey.sevenDayNotificationsEnabled.rawValue) }
    }

    init() {
        // Register defaults BEFORE reading; register(defaults:) never overwrites existing values.
        UserDefaults.standard.register(defaults: [
            PreferencesKey.pollingInterval.rawValue: 5.0,
            PreferencesKey.fiveHourThreshold.rawValue: 80.0,
            PreferencesKey.sevenDayThreshold.rawValue: 80.0,
            PreferencesKey.fiveHourNotificationsEnabled.rawValue: false,
            PreferencesKey.sevenDayNotificationsEnabled.rawValue: false
        ])
        pollingInterval = UserDefaults.standard.double(forKey: PreferencesKey.pollingInterval.rawValue)
        fiveHourThreshold = UserDefaults.standard.double(forKey: PreferencesKey.fiveHourThreshold.rawValue)
        sevenDayThreshold = UserDefaults.standard.double(forKey: PreferencesKey.sevenDayThreshold.rawValue)
        fiveHourNotificationsEnabled = UserDefaults.standard.bool(forKey: PreferencesKey.fiveHourNotificationsEnabled.rawValue)
        sevenDayNotificationsEnabled = UserDefaults.standard.bool(forKey: PreferencesKey.sevenDayNotificationsEnabled.rawValue)
    }
}
