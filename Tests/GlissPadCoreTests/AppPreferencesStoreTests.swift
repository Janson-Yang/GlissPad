@testable import GlissPadCore
import Foundation
import XCTest

final class AppPreferencesStoreTests: XCTestCase {
    func testDefaultsToShowingStatusItem() {
        let defaults = temporaryDefaults()
        let store = UserDefaultsAppPreferencesStore(defaults: defaults)

        XCTAssertTrue(store.preferences.showsStatusItem)
    }

    func testPersistsStatusItemPreference() {
        let defaults = temporaryDefaults()
        let store = UserDefaultsAppPreferencesStore(defaults: defaults)

        store.preferences = AppPreferences(showsStatusItem: false)

        XCTAssertFalse(UserDefaultsAppPreferencesStore(defaults: defaults).preferences.showsStatusItem)
    }

    private func temporaryDefaults() -> UserDefaults {
        let suiteName = "local.glisspad.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test defaults.")
            return .standard
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
