import Foundation

/// yaw / pitch **dead zone** (라디안). 축별로 dead 안쪽이면 해당 축 위치는 갱신하지 않음 (`ObstacleDodgeAnalogMapper`).
///
/// **튜닝:** 흔들림이 크면 값을 올려 dead zone을 넓힌다. 반응이 둔하면 낮춘다(약 0.08〜0.20 rad).
struct ObstacleDodgeInputThresholds: Sendable, Equatable {
    /// `|yawRel|`이 이보다 작으면 수평 위치 유지.
    var yawThresholdRadians: Float
    /// `|pitchRel|`이 이보다 작으면 수직 위치 유지.
    var pitchThresholdRadians: Float

    static let `default` = ObstacleDodgeInputThresholds(
        yawThresholdRadians: 0.14,
        pitchThresholdRadians: 0.12
    )
}
