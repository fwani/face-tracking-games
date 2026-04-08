import Combine
import Foundation

@MainActor
final class FaceTrackingSessionModel: ObservableObject {
    private let parser = FaceInputParser()

    @Published var snapshot: FaceInputSnapshot = .empty
    @Published var gameInput: GameInput = .neutral
    @Published private(set) var isBlinkBaselineLocked: Bool = false
    @Published private(set) var settingsBlinkJumpCount: Int = 0
    /// `기준 자세 저장`으로 잡은 요(yaw) 기준(설정 좌우 게이지 중앙).
    @Published private(set) var neutralYawBaselineRadians: Float = 0
    /// 0 = 민감(약한 깜빡임), 1 = 타이트.
    @Published var blinkStrictness: Float = BlinkSensitivityStorage.loadStrictness()

    private var pendingHeadNeutralAfterARReset = false

    var blinkCalibrationProgress: Float {
        parser.blinkCalibrationProgress
    }

    private var blinkTuningForParser: BlinkDetectionTuning {
        BlinkDetectionTuning.tuning(strictness: blinkStrictness)
    }

    func setBlinkStrictness(_ strictness: Float) {
        let c = min(max(strictness, 0), 1)
        guard c != blinkStrictness else { return }
        blinkStrictness = c
        BlinkSensitivityStorage.save(strictness: c)
    }

    func resetBlinkTuningToAppDefaults() {
        setBlinkStrictness(BlinkDetectionTuning.defaultStrictness)
    }

    /// 저장된 baseline이 있는데 파서만 아직 잠금 전인 경우(앱 실행 직후 설정만 연 경우 등) 동기화.
    func applyStoredBlinkBaselineIfNeeded() {
        guard let v = BlinkBaselineStorage.load() else { return }
        parser.applyPersistedBaselineFromDiskIfNeeded(v)
        let locked = parser.isBaselineLocked
        if locked != isBlinkBaselineLocked {
            isBlinkBaselineLocked = locked
        }
    }

    func ingest(
        _ snapshot: FaceInputSnapshot,
        blinkCalibrationAllowed: Bool,
        commitSettingsCalibrationToDisk: Bool = false,
        settingsBlinkJumpTestActive: Bool = false
    ) {
        let wasLocked = parser.isBaselineLocked
        self.snapshot = snapshot

        if pendingHeadNeutralAfterARReset, snapshot.hasFace {
            parser.captureNeutralHeadPose(yaw: snapshot.headYawRadians)
            pendingHeadNeutralAfterARReset = false
            neutralYawBaselineRadians = parser.neutralYawBaselineRadians
        }

        gameInput = parser.update(
            snapshot: snapshot,
            now: snapshot.timestamp,
            blinkCalibrationAllowed: blinkCalibrationAllowed,
            settingsBlinkJumpTestActive: settingsBlinkJumpTestActive,
            blinkTuning: blinkTuningForParser
        )
        if settingsBlinkJumpTestActive, gameInput.jumpImpulse {
            settingsBlinkJumpCount += 1
        }
        let locked = parser.isBaselineLocked
        if locked != isBlinkBaselineLocked {
            isBlinkBaselineLocked = locked
        }
        if commitSettingsCalibrationToDisk, !wasLocked, locked, let v = parser.lockedBlinkBaseline {
            BlinkBaselineStorage.save(baseline: v)
        }
    }

    /// 설정 점프 테스트 토글 시: 카운트 초기화 + 점프 이벤트 상태만 리셋(baseline 유지).
    func resetSettingsBlinkJumpTestSession() {
        settingsBlinkJumpCount = 0
        parser.resetSettingsBlinkJumpTestEventState()
    }

    /// 플레이 화면 진입: 저장된 baseline이 있으면 즉시 잠금, 없으면 인게임 캘리브.
    func notifyPlaySessionStarted() {
        parser.notifyPlaySessionStarted(persistedBaseline: BlinkBaselineStorage.load())
        isBlinkBaselineLocked = parser.isBaselineLocked
        gameInput = parser.update(
            snapshot: snapshot,
            now: snapshot.timestamp,
            blinkCalibrationAllowed: false,
            settingsBlinkJumpTestActive: false,
            blinkTuning: blinkTuningForParser
        )
    }

    /// 홈/설정 등 비플레이로 나갈 때: baseline은 유지, 플래그만 해제.
    func notifyPlaySessionEnded() {
        parser.notifyPlaySessionEnded()
        isBlinkBaselineLocked = parser.isBaselineLocked
        gameInput = parser.update(
            snapshot: snapshot,
            now: snapshot.timestamp,
            blinkCalibrationAllowed: false,
            settingsBlinkJumpTestActive: false,
            blinkTuning: blinkTuningForParser
        )
    }

    /// 설정에서 스토리지 clear 후 호출해 파서 캘리브 상태를 초기화.
    func resetBlinkCalibrationForRemeasure() {
        parser.resetBlinkCalibrationForRemeasure()
        isBlinkBaselineLocked = parser.isBaselineLocked
        gameInput = parser.update(
            snapshot: snapshot,
            now: snapshot.timestamp,
            blinkCalibrationAllowed: false,
            settingsBlinkJumpTestActive: false,
            blinkTuning: blinkTuningForParser
        )
    }

    /// AR 세션 리셋 후, 다음으로 얼굴이 잡히는 프레임에서 정면(요·피치) 기준을 저장합니다.
    func requestRecalibrateHeadNeutralAfterARReset() {
        pendingHeadNeutralAfterARReset = true
    }

    /// 설정 화면을 떠날 때 등, 대기 중인 기준 저장을 취소합니다.
    func cancelPendingHeadNeutralRecalibration() {
        pendingHeadNeutralAfterARReset = false
    }
}
