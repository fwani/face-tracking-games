import Foundation

/// PRD §10 — Easy / Normal / Hard / Hell.
enum ObstacleDodgeDifficulty: String, CaseIterable, Identifiable, Sendable {
    case easy
    case normal
    case hard
    case hell

    var id: String { rawValue }

    /// 장애물 이동 속도 배율.
    var speedMultiplier: Float {
        switch self {
        case .easy: return 0.65
        case .normal: return 1.0
        case .hard: return 1.35
        case .hell: return 1.75
        }
    }

    /// 등장 간격(초). 낮을수록 빽빽.
    var spawnIntervalSeconds: TimeInterval {
        switch self {
        case .easy: return 2.1
        case .normal: return 1.55
        case .hard: return 1.15
        case .hell: return 0.85
        }
    }

    /// 패턴 복잡도: `true`이면 연속·혼합 시퀀스를 더 길게 사용.
    var prefersComplexPatterns: Bool {
        switch self {
        case .easy, .normal: return false
        case .hard, .hell: return true
        }
    }

    var displayTitle: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        case .hell: return "Hell"
        }
    }
}
