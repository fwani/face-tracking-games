import Foundation

enum BlinkBaselineStorage {
    private static var defaults: UserDefaults { .standard }

    static var hasStoredCalibration: Bool {
        defaults.bool(forKey: GameParameters.blinkBaselineCalibratedKey)
    }

    static func load() -> Float? {
        guard defaults.bool(forKey: GameParameters.blinkBaselineCalibratedKey) else { return nil }
        return Float(defaults.double(forKey: GameParameters.blinkBaselineStoredKey))
    }

    static func save(baseline: Float) {
        defaults.set(true, forKey: GameParameters.blinkBaselineCalibratedKey)
        defaults.set(Double(baseline), forKey: GameParameters.blinkBaselineStoredKey)
    }

    static func clear() {
        defaults.removeObject(forKey: GameParameters.blinkBaselineCalibratedKey)
        defaults.removeObject(forKey: GameParameters.blinkBaselineStoredKey)
    }
}
