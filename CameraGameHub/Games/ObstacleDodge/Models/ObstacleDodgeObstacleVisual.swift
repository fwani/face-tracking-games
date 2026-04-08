import CoreGraphics
import Foundation

/// 뷰가 그리기 위한 낙하 장애물 스냅샷.
struct ObstacleDodgeObstacleVisual: Identifiable, Equatable {
    let id: UUID
    /// 0…3 색 팔레트 인덱스.
    let paletteIndex: Int
    var position: CGPoint
}
