import Foundation

extension GameInput {
    /// AR 미지원(시뮬레이터)일 때 탭·토글 부스터를 합성한다.
    func mergingSimulator(jumpPulse: Bool, boostHeld: Bool, arSupported: Bool) -> GameInput {
        guard !arSupported else { return self }
        return GameInput(
            jumpImpulse: jumpImpulse || jumpPulse,
            boostActive: boostActive || boostHeld,
            horizontalNormalized: horizontalNormalized,
            trackingLost: false
        )
    }
}
