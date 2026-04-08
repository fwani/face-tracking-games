import Foundation

/// PRD §9 + blink 이벤트 감지·물리 튜닝.
enum GameParameters {
    // MARK: - Blink (baseline + normalized + delta, per-eye average scale 0…1)

    /// 초기 눈 뜸 구간에서 baseline을 잡는 시간(초).
    static let blinkBaselineWindowSeconds: TimeInterval = 1.5
    /// `normalizedBlink = rawAvg - baseline` 이 이 값을 넘을 때만 후보.
    static let blinkNormalizedThreshold: Float = 0.45
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

    /// `birdVy > 0`(상승 중)일 때 점프에 곱함. 1이면 동일, 낮출수록 연타 시 급상승 완화.
    static let jumpImpulseWhileRisingMultiplier: Float = 0.22

    /// Maps PRD-style values into normalized playfield units per second².
    static let physicsWorldScale: Float = 0.055
    /// 말 스프라이트·충돌 가로 (정규화). `horseAssetView*`와 `GamePlayfieldView`와 동일해야 함.
    static let birdVisualWidthNorm: Float = 0.18
    /// 말 SVG 공통 viewBox (양 에셋 동일). 세로 충돌은 화면 `width/height`로 스케일.
    static let horseAssetViewWidth: Float = 80
    static let horseAssetViewHeight: Float = 60
    /// 기둥 이미지 가로 반폭(정규화). `GamePlayfieldView` 배치·통과 점수에 사용.
    static let pipeHalfWidthNorm: Float = 0.11
    /// 기둥 좌우 충돌만 — 시각보다 좁게(몸통에 가깝게). SVG와 무관하게 튜닝.
    static let pipeCollisionHalfWidthNorm: Float = 0.072

    /// 화면 하단 지면 밴드 높이(정규화). [flappy-horse-design-guide]와 `FlappyHorseTheme`·충돌 판정과 일치.
    static let groundBandHeightNorm: Float = 0.175
    /// 화면 가장자리(0/1 정규 좌표) 판정 시 부동소수 여유.
    static let screenEdgeEpsilonNorm: Float = 0.002

    static let tutorialDefaultsKey = "cameragamehub.tutorial.v1.done"

    /// UserDefaults: 저장된 눈 뜸 baseline(양쪽 평균, 0…1 스케일).
    static let blinkBaselineStoredKey = "cameragamehub.blinkBaseline.value"
    static let blinkBaselineCalibratedKey = "cameragamehub.blinkBaseline.calibrated"

    /// UserDefaults: 점프 블링크 감도 0…1 (0 민감, 1 타이트). 미저장 시 `BlinkDetectionTuning.defaultStrictness`.
    static let blinkSensitivityStrictnessKey = "cameragamehub.blinkSensitivity.strictness"
    /// 구버전(정규화·델타 별도 저장) — 최초 로드 시 strictness로 이전 후 제거.
    static let blinkSensitivityNormalizedKey = "cameragamehub.blinkSensitivity.normalized"
    static let blinkSensitivityDeltaKey = "cameragamehub.blinkSensitivity.delta"
}
