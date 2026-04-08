import Foundation

/// 사용자 조절 가능한 블링크 점프 튜닝(파서에 전달).
///
/// `strictness`는 **연속 인식 간격(쿨다운)** 만 조절합니다. 깊이·델타 임계값은 항상 `GameParameters` 고정값입니다.
struct BlinkDetectionTuning: Equatable, Sendable {
    var normalizedThreshold: Float
    var deltaThreshold: Float
    var eventCooldownSeconds: TimeInterval

    /// 민감: 짧은 텀 — 타이트: 긴 텀. 최소 0.01초.
    private static let cooldownMin: TimeInterval = 0.01
    private static let cooldownMax: TimeInterval = 0.40

    /// 0 = 민감(짧은 쿨다운), 1 = 타이트(긴 쿨다운). 임계값은 `GameParameters` 고정.
    static func tuning(strictness: Float) -> BlinkDetectionTuning {
        let t = min(max(strictness, 0), 1)
        return BlinkDetectionTuning(
            normalizedThreshold: GameParameters.blinkNormalizedThreshold,
            deltaThreshold: GameParameters.blinkDeltaThreshold,
            eventCooldownSeconds: cooldownMin + TimeInterval(t) * (cooldownMax - cooldownMin)
        )
    }

    /// 슬라이더 기본 위치 — `GameParameters.blinkEventCooldownSeconds`에 맞춘 역산.
    static var defaultStrictness: Float {
        let c = GameParameters.blinkEventCooldownSeconds
        let span = cooldownMax - cooldownMin
        guard span > 0 else { return 0.5 }
        return min(max(Float((c - cooldownMin) / span), 0), 1)
    }

    /// 앱 권장 기본(코드 상수와 동일한 수치).
    static var defaults: BlinkDetectionTuning {
        BlinkDetectionTuning(
            normalizedThreshold: GameParameters.blinkNormalizedThreshold,
            deltaThreshold: GameParameters.blinkDeltaThreshold,
            eventCooldownSeconds: GameParameters.blinkEventCooldownSeconds
        )
    }
}

enum BlinkSensitivityStorage {
    private static var ud: UserDefaults { .standard }

    /// 구버전 UI에서 저장하던 정규화 임계값 범위(마이그레이션 전용).
    private static let legacyNormMin: Float = 0.18
    private static let legacyNormMax: Float = 0.45

    static func loadStrictness() -> Float {
        if ud.object(forKey: GameParameters.blinkSensitivityStrictnessKey) != nil {
            let s = Float(ud.double(forKey: GameParameters.blinkSensitivityStrictnessKey))
            return min(max(s, 0), 1)
        }
        if ud.object(forKey: GameParameters.blinkSensitivityNormalizedKey) != nil {
            let n = Float(ud.double(forKey: GameParameters.blinkSensitivityNormalizedKey))
            let migrated = migrateLegacyNormalizedToStrictness(n)
            ud.set(Double(migrated), forKey: GameParameters.blinkSensitivityStrictnessKey)
            ud.removeObject(forKey: GameParameters.blinkSensitivityNormalizedKey)
            ud.removeObject(forKey: GameParameters.blinkSensitivityDeltaKey)
            return migrated
        }
        return BlinkDetectionTuning.defaultStrictness
    }

    private static func migrateLegacyNormalizedToStrictness(_ n: Float) -> Float {
        let span = legacyNormMax - legacyNormMin
        guard span > 0 else { return BlinkDetectionTuning.defaultStrictness }
        return min(max((n - legacyNormMin) / span, 0), 1)
    }

    static func save(strictness: Float) {
        let c = min(max(strictness, 0), 1)
        ud.set(Double(c), forKey: GameParameters.blinkSensitivityStrictnessKey)
    }
}
