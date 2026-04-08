import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard
    case hell

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .normal: "Normal"
        case .hard: "Hard"
        case .hell: "Hell"
        }
    }
}

struct DifficultyConfig: Equatable {
    /// 장애물·월드 스크롤 속도 (정규화 좌표/초).
    let scrollSpeed: Float
    /// 기둥 사이 세로 통로 높이 (정규화 0…1, 전체 간격).
    let pipeGap: Float
    /// 중력 가속도 (음수, `GameParameters.physicsWorldScale` 적용 전 물리 단위).
    let gravity: Float
    /// blink 1회 점프 impulse (`physicsWorldScale` 적용 전).
    let jumpForce: Float
    /// 고개 좌우 → 말 추적 속도 계수 (값이 클수록 민감).
    let horizontalSensitivity: Float
    /// 연속 장애물 최소 간격 (정규화, `pipeSpawnMinDistanceNorm`와 동일 의미).
    let spawnInterval: Float
    /// 입 벌리기 부스터 가속 (`physicsWorldScale` 적용 전, 초당 가속 스타일).
    let boostPower: Float
    /// 해당 난이도에서 부스터를 사실상 요구하는지 (UI·설계 표시용).
    let boostRequired: Bool
    /// 직전 파이프와 비교해 `gapMidY`가 바뀔 수 있는 최대 폭(정규화). 스폰이 짧을수록 작게 두면 연속 구멍 높이 차가 줄어듦.
    let gapMidYMaxDelta: Float

    /// `pipeGap`의 절반 — 충돌·렌더링에 사용.
    var pipeGapHalfHeightNorm: Float { pipeGap * 0.5 }

    /// `horizontalSensitivity` 대비 Normal(5.5)일 때의 가로 이동 폭 배율.
    var birdHorizontalSpanNorm: Float {
        let base: Float = 0.32
        let ref: Float = 5.5
        return base * (horizontalSensitivity / ref)
    }
}

extension Difficulty {
    /// 난이도별 프리셋 매핑.
    static let configByDifficulty: [Difficulty: DifficultyConfig] = [
        .easy: DifficultyConfig(
            scrollSpeed: 0.18,
            pipeGap: 0.62,
            gravity: -7.8,
            jumpForce: 7.2,
            horizontalSensitivity: 3.8,
            spawnInterval: 0.9,
            boostPower: 1.9,
            boostRequired: false,
            gapMidYMaxDelta: 0.22
        ),
        .normal: DifficultyConfig(
            scrollSpeed: 0.4,
            pipeGap: 0.35,
            gravity: -9.8,
            jumpForce: 7.0,
            horizontalSensitivity: 5.5,
            spawnInterval: 0.8,
            boostPower: 3.0,
            boostRequired: false,
            gapMidYMaxDelta: 0.18
        ),
        .hard: DifficultyConfig(
            scrollSpeed: 0.5,
            pipeGap: 0.27,
            gravity: -10.8,
            jumpForce: 6.0,
            horizontalSensitivity: 7.2,
            spawnInterval: 0.55,
            boostPower: 4.3,
            boostRequired: true,
            gapMidYMaxDelta: 0.11
        ),
        .hell: DifficultyConfig(
            scrollSpeed: 0.57,
            pipeGap: 0.22,
            gravity: -11.5,
            jumpForce: 6.0,
            horizontalSensitivity: 9.0,
            spawnInterval: 0.45,
            boostPower: 5.8,
            boostRequired: true,
            gapMidYMaxDelta: 0.095
        ),
    ]

    var config: DifficultyConfig {
        Self.configByDifficulty[self]!
    }
}
