import Foundation

/// ARKit `ARFaceAnchor` 기반 얼굴 입력 스냅샷. **각도는 항상 라디안** (`plan.md` Phase 1).
struct ObstacleDodgeFaceSnapshot: Equatable {
    var headYawRadians: Float
    var headPitchRadians: Float
    var hasFace: Bool
    var timestamp: TimeInterval

    static let empty = ObstacleDodgeFaceSnapshot(
        headYawRadians: 0,
        headPitchRadians: 0,
        hasFace: false,
        timestamp: 0
    )
}
