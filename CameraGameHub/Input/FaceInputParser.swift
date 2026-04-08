import Foundation

/// Maps `FaceInputSnapshot` → `GameInput` (PRD §4.3, §5.1).
///
/// Blink: `blinkCalibrationAllowed`이고 얼굴이 보일 때만 누적 시간으로 baseline(눈 뜸)을 잡고, 플레이 중(또는 `settingsBlinkJumpTestActive`)에는 `(L+R)/2` 정규화 + delta + 쿨다운으로 점프 이벤트.
final class FaceInputParser: @unchecked Sendable {
    private let lock = NSLock()

    private var playSessionActive = false
    private var baselineLocked = false
    private var baselineFaceTimeAccumulated: TimeInterval = 0
    private var calibrationLastNow: TimeInterval?
    private var baselineSum: Float = 0
    private var baselineCount: Int = 0
    private var blinkBaseline: Float = 0.12

    private var prevRawBlink: Float = 0
    private var prevHadFaceForBlink = false

    private var lastBlinkEventTime: TimeInterval = -1_000
    private var blinkArmed = true
    private var aboveNormThresholdSince: TimeInterval?

    private var emaHorizontal: Float = 0
    private var yawBaselineRadians: Float = 0

    var isBaselineLocked: Bool {
        lock.lock()
        defer { lock.unlock() }
        return baselineLocked
    }

    /// 설정 UI 진행률 0…1 (잠금 시 1).
    var blinkCalibrationProgress: Float {
        lock.lock()
        defer { lock.unlock() }
        if baselineLocked { return 1 }
        let w = Float(GameParameters.blinkBaselineWindowSeconds)
        guard w > 0 else { return 0 }
        return min(1, Float(baselineFaceTimeAccumulated) / w)
    }

    /// 잠금 상태에서 저장용 baseline 값.
    var lockedBlinkBaseline: Float? {
        lock.lock()
        defer { lock.unlock() }
        guard baselineLocked else { return nil }
        return blinkBaseline
    }

    /// 파서가 아직 미잠금일 때만 디스크에서 복원한 baseline으로 잠금(설정만 연 세션 등).
    func applyPersistedBaselineFromDiskIfNeeded(_ value: Float) {
        lock.lock()
        defer { lock.unlock() }
        guard !baselineLocked else { return }
        blinkBaseline = value
        baselineLocked = true
        resetBlinkEventStateOnlyLocked()
    }

    /// `persistedBaseline`이 있으면 즉시 잠금(디스크에서 복원). 없으면 라운드용 초기화 후 인게임 캘리브 가능.
    func notifyPlaySessionStarted(persistedBaseline: Float?) {
        lock.lock()
        defer { lock.unlock() }
        playSessionActive = true
        if let v = persistedBaseline {
            blinkBaseline = v
            baselineLocked = true
            resetBlinkEventStateOnlyLocked()
        } else {
            resetBlinkBaselineStateLocked()
        }
    }

    func notifyPlaySessionEnded() {
        lock.lock()
        defer { lock.unlock() }
        playSessionActive = false
    }

    /// 설정에서 다시 측정 전 파서 상태만 초기화(스토리지는 호출부에서 clear).
    func resetBlinkCalibrationForRemeasure() {
        lock.lock()
        defer { lock.unlock() }
        resetBlinkBaselineStateLocked()
    }

    /// 설정 UI 좌우(요) 게이지용 — `headYawRadians`와 동일 기준.
    var neutralYawBaselineRadians: Float {
        lock.lock()
        defer { lock.unlock() }
        return yawBaselineRadians
    }

    func captureNeutralHeadPose(yaw: Float) {
        lock.lock()
        defer { lock.unlock() }
        yawBaselineRadians = yaw
        emaHorizontal = 0
    }

    /// 설정 점프 테스트 시작/종료 시 호출: baseline·잠금 유지, 점프 이벤트 상태만 초기화.
    func resetSettingsBlinkJumpTestEventState() {
        lock.lock()
        defer { lock.unlock() }
        guard baselineLocked else { return }
        prevRawBlink = 0
        prevHadFaceForBlink = false
        lastBlinkEventTime = -1_000
        blinkArmed = true
        aboveNormThresholdSince = nil
    }

    func update(
        snapshot: FaceInputSnapshot,
        now: TimeInterval,
        blinkCalibrationAllowed: Bool,
        settingsBlinkJumpTestActive: Bool,
        blinkTuning: BlinkDetectionTuning
    ) -> GameInput {
        lock.lock()
        defer { lock.unlock() }

        guard snapshot.hasFace else {
            prevHadFaceForBlink = false
            prevRawBlink = 0
            aboveNormThresholdSince = nil
            calibrationLastNow = nil
            emaHorizontal = 0
            return GameInput(
                jumpImpulse: false,
                boostActive: false,
                horizontalNormalized: 0,
                trackingLost: true
            )
        }

        let left = snapshot.eyeBlinkLeft
        let right = snapshot.eyeBlinkRight
        let rawBlink = (left + right) * 0.5

        let boostActive = snapshot.jawOpen > GameParameters.jawOpenThreshold
        let relativeYaw = snapshot.headYawRadians - yawBaselineRadians
        let rawH = mapYaw(relativeYaw)
        let a: Float = 0.28
        emaHorizontal = a * rawH + (1 - a) * emaHorizontal

        if !blinkCalibrationAllowed {
            calibrationLastNow = nil
        }

        // --- Baseline learning (플레이/설정 공통, 캘리브 허용 시에만) ---
        if !baselineLocked {
            if blinkCalibrationAllowed {
                if let last = calibrationLastNow {
                    let dt = min(now - last, 0.1)
                    baselineFaceTimeAccumulated += dt
                }
                calibrationLastNow = now
                baselineSum += rawBlink
                baselineCount += 1
                if baselineFaceTimeAccumulated >= GameParameters.blinkBaselineWindowSeconds {
                    if baselineCount > 0 {
                        blinkBaseline = baselineSum / Float(baselineCount)
                    }
                    baselineLocked = true
                    prevRawBlink = rawBlink
                    aboveNormThresholdSince = nil
                    calibrationLastNow = nil
                }
            }
            prevRawBlink = rawBlink
            prevHadFaceForBlink = true
            return GameInput(
                jumpImpulse: false,
                boostActive: boostActive,
                horizontalNormalized: emaHorizontal,
                trackingLost: false
            )
        }

        if !playSessionActive, !settingsBlinkJumpTestActive {
            prevRawBlink = rawBlink
            prevHadFaceForBlink = true
            return GameInput(
                jumpImpulse: false,
                boostActive: boostActive,
                horizontalNormalized: emaHorizontal,
                trackingLost: false
            )
        }

        if prevHadFaceForBlink == false {
            prevRawBlink = rawBlink
        }
        prevHadFaceForBlink = true

        // --- Event-based blink ---
        let normalized = rawBlink - blinkBaseline
        let delta = rawBlink - prevRawBlink
        prevRawBlink = rawBlink

        let normThr = blinkTuning.normalizedThreshold
        let releaseLevel = normThr * GameParameters.blinkReleaseThresholdFactor

        if normalized < releaseLevel {
            blinkArmed = true
        }

        if normalized > normThr {
            if aboveNormThresholdSince == nil {
                aboveNormThresholdSince = now
            }
        } else {
            aboveNormThresholdSince = nil
        }

        let sustainedTooLong: Bool = {
            guard let t0 = aboveNormThresholdSince else { return false }
            return (now - t0) >= GameParameters.blinkMaxSustainedHighSeconds
        }()

        if sustainedTooLong {
            blinkArmed = false
        }

        var jumpImpulse = false
        let cooldownOK = (now - lastBlinkEventTime) >= blinkTuning.eventCooldownSeconds
        let wink = min(left, right) < GameParameters.blinkWinkIgnoreLowEye
            && max(left, right) > GameParameters.blinkWinkIgnoreHighEye

        if baselineLocked,
           !sustainedTooLong,
           blinkArmed,
           cooldownOK,
           normalized > normThr,
           delta > blinkTuning.deltaThreshold,
           !wink
        {
            jumpImpulse = true
            lastBlinkEventTime = now
            blinkArmed = false
        }

        return GameInput(
            jumpImpulse: jumpImpulse,
            boostActive: boostActive,
            horizontalNormalized: emaHorizontal,
            trackingLost: false
        )
    }

    private func resetBlinkEventStateOnlyLocked() {
        prevRawBlink = 0
        prevHadFaceForBlink = false
        lastBlinkEventTime = -1_000
        blinkArmed = true
        aboveNormThresholdSince = nil
        calibrationLastNow = nil
        baselineFaceTimeAccumulated = 0
        baselineSum = 0
        baselineCount = 0
    }

    private func resetBlinkBaselineStateLocked() {
        baselineLocked = false
        baselineFaceTimeAccumulated = 0
        calibrationLastNow = nil
        baselineSum = 0
        baselineCount = 0
        blinkBaseline = 0.12
        prevRawBlink = 0
        prevHadFaceForBlink = false
        lastBlinkEventTime = -1_000
        blinkArmed = true
        aboveNormThresholdSince = nil
    }

    private func mapYaw(_ yaw: Float) -> Float {
        let dz = GameParameters.yawDeadZoneRadians
        let mag = abs(yaw)
        if mag <= dz { return 0 }

        let sign: Float = yaw >= 0 ? 1 : -1
        let span = max(GameParameters.yawMaxDeflectionRadians - dz, 0.001)
        let t = min((mag - dz) / span, 1)
        return sign * t
    }
}
