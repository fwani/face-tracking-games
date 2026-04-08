import Foundation

/// Parsed game-facing input (PRD §5.1).
struct GameInput: Equatable, Sendable {
    /// True only on frames where a blink crosses into jump.
    var jumpImpulse: Bool
    var boostActive: Bool
    /// -1…1 after dead zone and scaling (PRD §4.3).
    var horizontalNormalized: Float
    /// Face anchor missing / tracking unusable — pause hook (PRD §8 문제3).
    var trackingLost: Bool

    static let neutral = GameInput(
        jumpImpulse: false,
        boostActive: false,
        horizontalNormalized: 0,
        trackingLost: true
    )
}
