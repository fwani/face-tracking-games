import Combine
import CoreGraphics
import Foundation
import QuartzCore
import SwiftUI

@MainActor
final class ObstacleDodgeGameModel: NSObject, ObservableObject {
    enum Phase: Equatable {
        case title
        case playing
        case paused
        case gameOver
    }

    @Published private(set) var phase: Phase = .title
    @Published private(set) var score: Int = 0
    @Published private(set) var combo: Int = 0
    /// 정규화 좌표 (연속 이동).
    @Published private(set) var playerPosition: CGPoint = CGPoint(x: 0.5, y: 0.74)
    @Published private(set) var obstacleVisuals: [ObstacleDodgeObstacleVisual] = []
    @Published var difficulty: ObstacleDodgeDifficulty = .normal
    @Published var showTutorialOverlay: Bool = false
    @Published private(set) var trackingLost: Bool = false
    @Published private(set) var lastGameOverReason: String?

    @Published private(set) var lastYawRelRadians: Float = 0
    @Published private(set) var lastPitchRelRadians: Float = 0

    private var analog = ObstacleDodgeAnalogMapper()

    private var yawBaseline: Float = 0
    private var pitchBaseline: Float = 0
    private var baselineSamples: Int = 0
    private let baselineSampleTarget: Int = 12
    private var baselineReady: Bool = false

    private var displayLink: CADisplayLink?
    private var lastTick: TimeInterval?
    private var spawnCooldown: TimeInterval = 0
    private var patternQueue: [CGFloat] = []
    private var patternIndex: Int = 0
    private var patternMode: PatternMode = .singleColumn

    private enum PatternMode {
        case singleColumn
        case waveSequence
        case rhythmColumns
    }

    override init() {
        super.init()
    }

    /// 낙하 기본 속도(정규화 y/초).
    private let baseFallSpeed: CGFloat = 0.55
    private let obstacleRadius: CGFloat = 0.065
    private let playerRadius: CGFloat = 0.055
    private let spawnY: CGFloat = -0.08
    private let despawnBelowY: CGFloat = 1.12

    func ingestFaceSnapshot(_ snap: ObstacleDodgeFaceSnapshot) {
        trackingLost = !snap.hasFace

        if phase == .playing {
            if !snap.hasFace {
                phase = .paused
                stopDisplayLink()
                return
            }
        } else if phase == .paused, snap.hasFace {
            phase = .playing
            lastTick = nil
            startDisplayLinkIfNeeded()
        }

        guard snap.hasFace else { return }

        if phase == .playing {
            if !baselineReady {
                yawBaseline += snap.headYawRadians
                pitchBaseline += snap.headPitchRadians
                baselineSamples += 1
                if baselineSamples >= baselineSampleTarget {
                    yawBaseline /= Float(baselineSampleTarget)
                    pitchBaseline /= Float(baselineSampleTarget)
                    baselineReady = true
                    analog.reset()
                    playerPosition = CGPoint(x: 0.5, y: 0.74)
                }
                lastYawRelRadians = 0
                lastPitchRelRadians = 0
                return
            }

            let yRel = snap.headYawRadians - yawBaseline
            let pRel = snap.headPitchRadians - pitchBaseline
            lastYawRelRadians = yRel
            lastPitchRelRadians = pRel
            playerPosition = analog.position(yawRel: yRel, pitchRel: pRel)
        }
    }

    func startFromTitle(showTutorial: Bool) {
        showTutorialOverlay = showTutorial
        resetRound()
        phase = .playing
        lastTick = nil
        startDisplayLinkIfNeeded()
    }

    func dismissTutorial() {
        showTutorialOverlay = false
    }

    func returnToTitle() {
        stopDisplayLink()
        phase = .title
        obstacleVisuals = []
        score = 0
        combo = 0
        lastGameOverReason = nil
        baselineReady = false
        baselineSamples = 0
        yawBaseline = 0
        pitchBaseline = 0
        analog.reset()
        playerPosition = CGPoint(x: 0.5, y: 0.74)
    }

    func retry() {
        resetRound()
        phase = .playing
        lastTick = nil
        startDisplayLinkIfNeeded()
    }

    private func resetRound() {
        score = 0
        combo = 0
        obstacleVisuals = []
        spawnCooldown = 0.85
        patternIndex = 0
        baselineReady = false
        baselineSamples = 0
        yawBaseline = 0
        pitchBaseline = 0
        analog.reset()
        playerPosition = CGPoint(x: 0.5, y: 0.74)
        lastGameOverReason = nil
        configurePatternForCurrentDifficulty()
    }

    private func configurePatternForCurrentDifficulty() {
        if difficulty == .hell {
            patternMode = .rhythmColumns
            patternQueue = [0.18, 0.34, 0.5, 0.66, 0.82]
            patternIndex = 0
        } else if difficulty.prefersComplexPatterns {
            patternMode = .waveSequence
            patternQueue = [0.22, 0.5, 0.78, 0.36, 0.64, 0.5]
            patternIndex = 0
        } else {
            patternMode = .singleColumn
            patternQueue = [0.5]
            patternIndex = 0
        }
    }

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastTick = nil
    }

    @objc private func tick() {
        guard phase == .playing else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if lastTick == nil {
            lastTick = now
            return
        }
        let dt = now - lastTick!
        lastTick = now
        step(dt: dt)
    }

    private func step(dt: TimeInterval) {
        if showTutorialOverlay { return }
        let speedMul = CGFloat(difficulty.speedMultiplier)
        let vy = baseFallSpeed * speedMul * CGFloat(dt)

        var next = obstacleVisuals
        var toRemove: [UUID] = []

        for i in next.indices {
            var item = next[i]
            var p = item.position
            p.y += vy
            item.position = p
            next[i] = item

            if collisionIfNeeded(obstacleCenter: p) {
                triggerGameOver(reason: "충돌")
                return
            }

            if p.y > despawnBelowY {
                toRemove.append(item.id)
                combo += 1
                score += 10 + combo * 2
            }
        }

        next.removeAll { toRemove.contains($0.id) }
        obstacleVisuals = next

        spawnCooldown -= dt
        if spawnCooldown <= 0 {
            spawnNextObstacle()
            spawnCooldown = rhythmInterval()
        }

        score += Int(dt * 6)
    }

    private func rhythmInterval() -> TimeInterval {
        let base = difficulty.spawnIntervalSeconds
        switch patternMode {
        case .rhythmColumns:
            return max(0.38, base * 0.82)
        case .waveSequence, .singleColumn:
            return base
        }
    }

    private func spawnNextObstacle() {
        let x: CGFloat
        switch patternMode {
        case .singleColumn:
            x = CGFloat.random(in: 0.18 ... 0.82)
        case .waveSequence, .rhythmColumns:
            x = patternQueue[patternIndex % patternQueue.count]
            patternIndex += 1
        }

        let jitter = CGFloat.random(in: -0.03 ... 0.03)
        let clampedX = min(max(x + jitter, 0.1), 0.9)
        let paletteIndex = Int.random(in: 0 ... 3)
        let obs = ObstacleDodgeObstacleVisual(
            id: UUID(),
            paletteIndex: paletteIndex,
            position: CGPoint(x: clampedX, y: spawnY)
        )
        obstacleVisuals.append(obs)
    }

    private func collisionIfNeeded(obstacleCenter: CGPoint) -> Bool {
        let pp = playerPosition
        let dist = hypot(Double(obstacleCenter.x - pp.x), Double(obstacleCenter.y - pp.y))
        return dist < Double(obstacleRadius + playerRadius)
    }

    private func triggerGameOver(reason: String) {
        lastGameOverReason = reason
        phase = .gameOver
        stopDisplayLink()
        obstacleVisuals = []
        combo = 0
    }
}

extension ObstacleDodgeGameModel {
    var obstacleRadiusNormalized: CGFloat { obstacleRadius }
    var playerRadiusNormalized: CGFloat { playerRadius }

    var effectiveSpawnIntervalPreview: Double {
        switch patternMode {
        case .rhythmColumns:
            return max(0.38, difficulty.spawnIntervalSeconds * 0.82)
        case .waveSequence, .singleColumn:
            return difficulty.spawnIntervalSeconds
        }
    }
}
