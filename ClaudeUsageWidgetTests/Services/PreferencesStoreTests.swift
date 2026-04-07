import Testing
import Foundation
@testable import ClaudeUsageWidget

@Suite("PreferencesStore")
@MainActor
struct PreferencesStoreTests {

    @Test("default pollingInterval is 5.0 when no saved value")
    func defaultPollingInterval() {
        UserDefaults.standard.removeObject(forKey: PreferencesKey.pollingInterval.rawValue)
        let store = PreferencesStore()
        #expect(store.pollingInterval == 5.0)
    }

    @Test("default fiveHourThreshold is 80.0 when no saved value")
    func defaultFiveHourThreshold() {
        UserDefaults.standard.removeObject(forKey: PreferencesKey.fiveHourThreshold.rawValue)
        let store = PreferencesStore()
        #expect(store.fiveHourThreshold == 80.0)
    }

    @Test("default sevenDayThreshold is 80.0 when no saved value")
    func defaultSevenDayThreshold() {
        UserDefaults.standard.removeObject(forKey: PreferencesKey.sevenDayThreshold.rawValue)
        let store = PreferencesStore()
        #expect(store.sevenDayThreshold == 80.0)
    }

    @Test("notifications disabled by default")
    func defaultNotificationsDisabled() {
        UserDefaults.standard.removeObject(forKey: PreferencesKey.fiveHourNotificationsEnabled.rawValue)
        UserDefaults.standard.removeObject(forKey: PreferencesKey.sevenDayNotificationsEnabled.rawValue)
        let store = PreferencesStore()
        #expect(store.fiveHourNotificationsEnabled == false)
        #expect(store.sevenDayNotificationsEnabled == false)
    }

    @Test("setting fiveHourThreshold persists to UserDefaults immediately")
    func thresholdPersists() {
        defer { UserDefaults.standard.removeObject(forKey: PreferencesKey.fiveHourThreshold.rawValue) }
        let store = PreferencesStore()
        store.fiveHourThreshold = 60.0
        let saved = UserDefaults.standard.double(forKey: PreferencesKey.fiveHourThreshold.rawValue)
        #expect(saved == 60.0)
    }

    @Test("setting pollingInterval persists to UserDefaults immediately")
    func pollingIntervalPersists() {
        defer { UserDefaults.standard.removeObject(forKey: PreferencesKey.pollingInterval.rawValue) }
        let store = PreferencesStore()
        store.pollingInterval = 15.0
        let saved = UserDefaults.standard.double(forKey: PreferencesKey.pollingInterval.rawValue)
        #expect(saved == 15.0)
    }

    @Test("round-trip: set value then new instance reads same value")
    func roundTrip() {
        defer { UserDefaults.standard.removeObject(forKey: PreferencesKey.pollingInterval.rawValue) }
        let store1 = PreferencesStore()
        store1.pollingInterval = 10.0
        let store2 = PreferencesStore()
        #expect(store2.pollingInterval == 10.0)
    }

    @Test("register(defaults:) does not overwrite existing saved value")
    func registerDoesNotOverwrite() {
        defer { UserDefaults.standard.removeObject(forKey: PreferencesKey.fiveHourThreshold.rawValue) }
        UserDefaults.standard.set(50.0, forKey: PreferencesKey.fiveHourThreshold.rawValue)
        let store = PreferencesStore()
        #expect(store.fiveHourThreshold == 50.0)
    }
}
