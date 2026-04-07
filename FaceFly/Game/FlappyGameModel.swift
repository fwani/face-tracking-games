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

    private let gravity = CGFloat(GameParameters.gravity) * CGFloat(GameParameters.physicsWorldScale)
    private let jumpImpulse = CGFloat(GameParameters.jumpForce) * CGFloat(GameParameters.physicsWorldScale)
    private let boostPerSec = CGFloat(GameParameters.boostForce) * CGFloat(GameParameters.physicsWorldScale)
    private let scroll = CGFloat(GameParameters.worldScrollPerSec)
    private let bw = CGFloat(GameParameters.birdHalfWidthNorm)
    private let bh = CGFloat(GameParameters.birdHalfHeightNorm)
    private let pw = CGFloat(GameParameters.pipeHalfWidthNorm)
    private let gh = CGFloat(GameParameters.pipeGapHalfHeightNorm)
    private let span = CGFloat(GameParameters.birdHorizontalSpanNorm)
    private let follow = CGFloat(GameParameters.horizontalFollowRate)
    private let spawnGap = CGFloat(GameParameters.pipeSpawnMinDistanceNorm)

    init() {
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
        seedPipes()
    }

    private func seedPipes() {
        pipes = [
            Pipe(id: UUID(), x: 1.08, gapMidY: 0.52, scored: false),
            Pipe(id: UUID(), x: 1.08 + spawnGap, gapMidY: 0.45, scored: false),
        ]
    }

    func tick(dt: CGFloat, input: GameInput, pauseForTracking: Bool) {
        if pauseForTracking || isGameOver { return }

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

        if playerScale > 1.001 {
            playerScale += (1 - playerScale) * min(1, 12 * dt)
        }

        advancePipes(dt: dt)
        checkBounds()
        checkCollisions()
    }

    private func advancePipes(dt: CGFloat) {
        for i in pipes.indices {
            pipes[i].x -= scroll * dt
        }
        pipes.removeAll { $0.x < -0.18 }

        let rightmost = pipes.map(\.x).max() ?? 0
        if rightmost < 1.0 - spawnGap * 0.35 {
            let nx = rightmost + spawnGap
            let mid = CGFloat.random(in: 0.34 ... 0.66)
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
        if birdY - bh <= 0.02 || birdY + bh >= 0.98 {
            isGameOver = true
        }
    }

    private func checkCollisions() {
        for pipe in pipes {
            let pipeL = pipe.x - pw
            let pipeR = pipe.x + pw
            let birdL = birdX - bw
            let birdR = birdX + bw
            if birdR < pipeL || birdL > pipeR { continue }

            let gapTop = pipe.gapMidY + gh
            let gapBot = pipe.gapMidY - gh
            let birdTop = birdY + bh
            let birdBot = birdY - bh
            if birdTop > gapTop || birdBot < gapBot {
                isGameOver = true
                return
            }
        }
    }
}
