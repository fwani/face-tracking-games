import CoreGraphics
import Foundation

/// yaw/pitch(라디안, 기준 자세 대비) → 화면 **하단 영역** 내 연속 위치. dead zone 축별 적용 + 스무딩.
struct ObstacleDodgeAnalogMapper: Sendable {
    var thresholds: ObstacleDodgeInputThresholds
    /// 0…1, 클수록 목표에 빨리 수렴.
    var positionSmoothing: Float

    private var smoothed: CGPoint

    /// 정규화 좌표: x,y ∈ [0,1], y는 위→아래 증가.
    static let xMin: CGFloat = 0.12
    static let xMax: CGFloat = 0.88
    static let yMin: CGFloat = 0.56
    static let yMax: CGFloat = 0.92

    init(
        thresholds: ObstacleDodgeInputThresholds = .default,
        positionSmoothing: Float = 0.28
    ) {
        self.thresholds = thresholds
        self.positionSmoothing = max(0.05, min(1, positionSmoothing))
        let start = CGPoint(x: 0.5, y: 0.74)
        self.smoothed = start
    }

    mutating func reset() {
        smoothed = CGPoint(x: 0.5, y: 0.74)
    }

    /// 한 프레임 목표 반영 후 스무딩된 위치.
    mutating func position(yawRel: Float, pitchRel: Float) -> CGPoint {
        let ty = thresholds.yawThresholdRadians
        let tp = thresholds.pitchThresholdRadians

        var x = Float(smoothed.x)
        var y = Float(smoothed.y)

        let gx: Float = 0.92
        let gy: Float = 0.78
        let baseY: Float = 0.72

        if abs(yawRel) > ty {
            let e = yawRel > 0 ? yawRel - ty : yawRel + ty
            x = 0.5 + gx * e
        }
        if abs(pitchRel) > tp {
            let e = pitchRel > 0 ? pitchRel - tp : pitchRel + tp
            y = baseY + gy * e
        }

        x = min(max(x, Float(Self.xMin)), Float(Self.xMax))
        y = min(max(y, Float(Self.yMin)), Float(Self.yMax))

        let target = CGPoint(x: CGFloat(x), y: CGFloat(y))
        let a = CGFloat(positionSmoothing)
        let nx = smoothed.x + (target.x - smoothed.x) * a
        let ny = smoothed.y + (target.y - smoothed.y) * a
        smoothed = CGPoint(x: nx, y: ny)
        return smoothed
    }
}
