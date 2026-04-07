import Foundation

/// PRD §9 + blink 이벤트 감지·물리 튜닝.
enum GameParameters {
    // MARK: - Blink (baseline + normalized + delta, per-eye average scale 0…1)

    /// 초기 눈 뜸 구간에서 baseline을 잡는 시간(초).
    static let blinkBaselineWindowSeconds: TimeInterval = 1.5
    /// `normalizedBlink = rawAvg - baseline` 이 이 값을 넘을 때만 후보.
    static let blinkNormalizedThreshold: Float = 0.35
    /// 프레임당 `rawAvg - prevRawAvg` 최소 증가량 (급격한 상승).
    static let blinkDeltaThreshold: Float = 0.22
    /// 이벤트 간 최소 간격(초). 연속 중복 방지·짧은 flap 허용 균형.
    static let blinkEventCooldownSeconds: TimeInterval = 0.2
    /// `releaseThreshold = blinkNormalizedThreshold * 이 비율` 아래로 내려와야 다음 입력 허용.
    static let blinkReleaseThresholdFactor: Float = 0.5
    /// `normalizedBlink > threshold`가 이 시간(초) 이상 유지되면 눈 감은 상태로 보고 추가 이벤트 억제.
    static let blinkMaxSustainedHighSeconds: TimeInterval = 0.35
    /// 한쪽만 유의미하게 감긴 경우(윙크) 점프 무시: 한쪽은 매우 작고 다른 쪽은 큼.
    static let blinkWinkIgnoreLowEye: Float = 0.08
    static let blinkWinkIgnoreHighEye: Float = 0.38

    // MARK: - Other input

    static let jawOpenThreshold: Float = 0.5
    static let yawDeadZoneRadians: Float = 0.1
    /// Outside dead zone, this yaw magnitude maps to |horizontal| = 1 (radians).
    static let yawMaxDeflectionRadians: Float = 0.5
    /// 설정 화면 좌우(요) 회전 게이지 정규화용 ±범위(라디안).
    static let settingsYawGaugeMaxRadians: Float = 0.55

    /// PRD §9 — 점프 impulse (고정; blink 강도와 무관).
    static let jumpForce: Float = 8.0
    /// `birdVy > 0`(상승 중)일 때 점프에 곱함. 1이면 동일, 낮출수록 연타 시 급상승 완화.
    static let jumpImpulseWhileRisingMultiplier: Float = 0.42
    static let boostForce: Float = 3.0
    static let gravity: Float = -9.8

    /// Maps PRD-style values into normalized playfield units per second².
    static let physicsWorldScale: Float = 0.055
    static let worldScrollPerSec: Float = 0.32
    static let birdHalfWidthNorm: Float = 0.045
    static let birdHalfHeightNorm: Float = 0.038
    static let pipeHalfWidthNorm: Float = 0.055
    static let pipeGapHalfHeightNorm: Float = 0.22
    static let birdHorizontalSpanNorm: Float = 0.32
    static let horizontalFollowRate: Float = 5.5
    static let pipeSpawnMinDistanceNorm: Float = 0.42
    static let tutorialDefaultsKey = "facefly.tutorial.v1.done"

    /// UserDefaults: 저장된 눈 뜸 baseline(양쪽 평균, 0…1 스케일).
    static let blinkBaselineStoredKey = "facefly.blinkBaseline.value"
    static let blinkBaselineCalibratedKey = "facefly.blinkBaseline.calibrated"

    /// UserDefaults: 점프 블링크 감도 0…1 (0 민감, 1 타이트). 미저장 시 `BlinkDetectionTuning.defaultStrictness`.
    static let blinkSensitivityStrictnessKey = "facefly.blinkSensitivity.strictness"
    /// 구버전(정규화·델타 별도 저장) — 최초 로드 시 strictness로 이전 후 제거.
    static let blinkSensitivityNormalizedKey = "facefly.blinkSensitivity.normalized"
    static let blinkSensitivityDeltaKey = "facefly.blinkSensitivity.delta"
}
