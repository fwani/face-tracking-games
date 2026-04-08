import Combine
import CoreGraphics
import Foundation

/// Flappy-style world in normalized units: x∈[0,1] left→right, y∈[0,1] bottom→top.
@MainActor
final class FlappyGameModel: ObservableObject {
    struct Pipe: Identifiable, Equatable {
        let id: UUID
        var x: CGFloat
        var gapMidY: CGFloat
        var scored: Bool
    }

    @Published private(set) var pipes: [Pipe] = []
    @Published var birdX: CGFloat = 0.5
    @Published var birdY: CGFloat = 0.5
    @Published private(set) var birdVy: CGFloat = 0
    @Published private(set) var score: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published var worldScrollPhase: CGFloat = 0
    @Published var playerScale: CGFloat = 1
    @Published var showBoostFX: Bool = false
    @Published var runAnimationPhase: Bool = false
    @Published var hitFlashActive: Bool = false
    @Published private(set) var difficulty: Difficulty = .normal

    private var config: DifficultyConfig

    private var gravity: CGFloat { CGFloat(config.gravity) * CGFloat(GameParameters.physicsWorldScale) }
    private var jumpImpulse: CGFloat { CGFloat(config.jumpForce) * CGFloat(GameParameters.physicsWorldScale) }
    private var boostPerSec: CGFloat { CGFloat(config.boostPower) * CGFloat(GameParameters.physicsWorldScale) }
    private var scroll: CGFloat { CGFloat(config.scrollSpeed) }
    private var gh: CGFloat { CGFloat(config.pipeGapHalfHeightNorm) }
    private var span: CGFloat { CGFloat(config.birdHorizontalSpanNorm) }
    private var follow: CGFloat { CGFloat(config.horizontalSensitivity) }
    private var spawnGap: CGFloat { CGFloat(config.spawnInterval) }

    private let pw = CGFloat(GameParameters.pipeHalfWidthNorm)
    private let pipeHitHalfW = CGFloat(GameParameters.pipeCollisionHalfWidthNorm)
    /// 화면 가로/세로 — `GamePlayfieldView`에서 갱신. 말 충돌 세로는 이 비율로 계산.
    private var playfieldWidthOverHeight: CGFloat = 9 / 19.5

    private var bw: CGFloat { CGFloat(GameParameters.birdVisualWidthNorm) * 0.5 }
    private var bh: CGFloat {
        CGFloat(GameParameters.birdVisualWidthNorm) * playfieldWidthOverHeight
            * CGFloat(GameParameters.horseAssetViewHeight) / CGFloat(GameParameters.horseAssetViewWidth) * 0.5
    }

    func updatePlayfieldAspect(width: CGFloat, height: CGFloat) {
        guard width > 0, height > 0 else { return }
        playfieldWidthOverHeight = width / height
    }

    private let edgeEps = CGFloat(GameParameters.screenEdgeEpsilonNorm)
    private var runAnimAccum: CGFloat = 0
    private var hitFlashUntil: TimeInterval = 0

    /// 렌더링과 동일한 기둥 간격(정규화, 반높이).
    var pipeGapHalfHeightNorm: CGFloat { CGFloat(config.pipeGapHalfHeightNorm) }

    init(difficulty: Difficulty = .normal) {
        config = difficulty.config
        self.difficulty = difficulty
        restart()
    }

    /// 세션 시작 시 또는 홈에서 플레이 직전에 호출. 난이도는 게임 중 변경하지 않는다.
    func configure(difficulty: Difficulty) {
        self.difficulty = difficulty
        config = difficulty.config
        restart()
    }

    func restart() {
        pipes = []
        birdX = 0.5
        birdY = 0.5
        birdVy = 0
        score = 0
        isGameOver = false
        worldScrollPhase = 0
        playerScale = 1
        showBoostFX = false
        runAnimationPhase = false
        runAnimAccum = 0
        hitFlashActive = false
        hitFlashUntil = 0
        seedPipes()
    }

    private func seedPipes() {
        pipes = [
            Pipe(id: UUID(), x: 1.08, gapMidY: 0.52, scored: false),
            Pipe(id: UUID(), x: 1.08 + spawnGap, gapMidY: 0.45, scored: false),
        ]
    }

    func tick(dt: CGFloat, input: GameInput, pauseForTracking: Bool) {
        let now = Date().timeIntervalSinceReferenceDate
        if isGameOver {
            updateHitFlash(now: now)
            return
        }
        if pauseForTracking { return }

        let targetX = 0.5 + CGFloat(input.horizontalNormalized) * span
        birdX += (targetX - birdX) * min(1, follow * dt)

        if input.jumpImpulse {
            let rising = birdVy > 0
            let factor = rising ? CGFloat(GameParameters.jumpImpulseWhileRisingMultiplier) : 1
            birdVy += jumpImpulse * factor
            playerScale = 1.14
        }

        if input.boostActive {
            birdVy += boostPerSec * dt
            showBoostFX = true
        } else {
            showBoostFX = false
        }

        birdVy += gravity * dt
        birdY += birdVy * dt

        worldScrollPhase += scroll * dt

        runAnimAccum += dt
        if runAnimAccum >= 0.125 {
            runAnimAccum = 0
            runAnimationPhase.toggle()
        }

        if playerScale > 1.001 {
            playerScale += (1 - playerScale) * min(1, 12 * dt)
        }

        advancePipes(dt: dt)
        checkBounds()
        checkCollisions()
        updateHitFlash(now: now)
    }

    private func updateHitFlash(now: TimeInterval) {
        if hitFlashActive, now >= hitFlashUntil {
            hitFlashActive = false
        }
    }

    private func advancePipes(dt: CGFloat) {
        for i in pipes.indices {
            pipes[i].x -= scroll * dt
        }
        pipes.removeAll { $0.x < -0.18 }

        let rightmost = pipes.map(\.x).max() ?? 0
        if rightmost < 1.0 - spawnGap * 0.35 {
            let nx = rightmost + spawnGap
            let refMid = pipes.max(by: { $0.x < $1.x })?.gapMidY ?? 0.5
            let d = CGFloat(config.gapMidYMaxDelta)
            let globalLo: CGFloat = 0.34
            let globalHi: CGFloat = 0.66
            let lo = max(globalLo, refMid - d)
            let hi = min(globalHi, refMid + d)
            let mid = lo < hi ? CGFloat.random(in: lo ... hi) : refMid
            pipes.append(Pipe(id: UUID(), x: nx, gapMidY: mid, scored: false))
        }

        let birdLeft = birdX - bw
        for i in pipes.indices {
            guard !pipes[i].scored else { continue }
            let pipeRight = pipes[i].x + pw
            if pipeRight < birdLeft {
                pipes[i].scored = true
                score += 1
            }
        }
    }

    private func checkBounds() {
        let birdL = birdX - bw
        let birdR = birdX + bw
        let birdBot = birdY - bh
        let birdTop = birdY + bh
        if birdBot <= edgeEps
            || birdTop >= 1 - edgeEps
            || birdL <= edgeEps
            || birdR >= 1 - edgeEps
        {
            triggerGameOverFlash()
            isGameOver = true
        }
    }

    private func checkCollisions() {
        for pipe in pipes {
            let pipeL = pipe.x - pipeHitHalfW
            let pipeR = pipe.x + pipeHitHalfW
            let birdL = birdX - bw
            let birdR = birdX + bw
            if birdR < pipeL || birdL > pipeR { continue }

            let gapTop = pipe.gapMidY + gh
            let gapBot = pipe.gapMidY - gh
            let birdTop = birdY + bh
            let birdBot = birdY - bh
            if birdTop > gapTop || birdBot < gapBot {
                triggerGameOverFlash()
                isGameOver = true
                return
            }
        }
    }

    private func triggerGameOverFlash() {
        guard !hitFlashActive else { return }
        hitFlashActive = true
        hitFlashUntil = Date().timeIntervalSinceReferenceDate + 0.2
    }
}
