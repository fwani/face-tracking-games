import Foundation

/// Raw ARKit face frame (PRD §5.2).
struct FaceInputSnapshot: Equatable, Sendable {
    var eyeBlinkLeft: Float
    var eyeBlinkRight: Float
    var jawOpen: Float
    /// Radians, positive = user turns head to their right (camera view).
    var headYawRadians: Float
    /// Radians, head nod (see `HeadPose.pitchRadians`).
    var headPitchRadians: Float
    var hasFace: Bool
    var timestamp: TimeInterval

    static let empty = FaceInputSnapshot(
        eyeBlinkLeft: 0,
        eyeBlinkRight: 0,
        jawOpen: 0,
        headYawRadians: 0,
        headPitchRadians: 0,
        hasFace: false,
        timestamp: 0
    )
}
