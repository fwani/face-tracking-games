import AudioToolbox
import SwiftUI

/// PRD §8 — 플레이어·장애물·점수·피드백.
struct ObstacleDodgePlayView: View {
    @ObservedObject var game: ObstacleDodgeGameModel
    var demoAutoRestart: Bool
    var onBackToHub: () -> Void
    var onReturnToMenu: () -> Void

    @State private var shake: CGFloat = 0
    @State private var redFlash: Double = 0
    @AppStorage("obstacleDodgeTutorialSeen") private var tutorialSeen = false
    @AppStorage("obstacleDodgeMuteEffects") private var muteEffects = false

    var body: some View {
        ZStack {
            playfield

            VStack {
                HStack {
                    Button("허브") {
                        onBackToHub()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("점수 \(game.score)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                        if game.combo > 0 {
                            Text("콤보 ×\(game.combo)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                        Text(String(format: "스폰 간격 %.2fs", game.effectiveSpawnIntervalPreview))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()
            }

            if game.phase == .paused {
                pausedOverlay
            }

            if game.phase == .gameOver {
                gameOverOverlay
            }

            if game.showTutorialOverlay {
                tutorialOverlay
            }
        }
        .background(Color.clear)
        .onChange(of: game.phase) { new in
            if new == .gameOver {
                shakeGameOver()
                playEffect(1521)
                if demoAutoRestart {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        guard game.phase == .gameOver else { return }
                        game.retry()
                    }
                }
            }
        }
        .onChange(of: game.combo) { new in
            if new > 0, game.phase == .playing {
                playEffect(1104)
            }
        }
    }

    private func playEffect(_ id: SystemSoundID) {
        guard !muteEffects else { return }
        AudioServicesPlaySystemSound(id)
    }

    private var playfield: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.45), Color(red: 0.12, green: 0.1, blue: 0.18).opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ForEach(game.obstacleVisuals) { o in
                    let cx = o.position.x * w
                    let cy = o.position.y * h
                    Circle()
                        .fill(obstacleColor(paletteIndex: o.paletteIndex))
                        .frame(width: game.obstacleRadiusNormalized * 2 * w, height: game.obstacleRadiusNormalized * 2 * w)
                        .position(x: cx, y: cy)
                }

                let px = game.playerPosition.x * w
                let py = game.playerPosition.y * h
                Circle()
                    .strokeBorder(.white, lineWidth: 3)
                    .background(Circle().fill(Color.cyan.opacity(0.35)))
                    .frame(width: game.playerRadiusNormalized * 2 * w, height: game.playerRadiusNormalized * 2 * w)
                    .position(x: px, y: py)

                Text("고개로 이동 · 위에서 장애물 낙하")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
                    .position(x: w * 0.5, y: h * 0.92)
            }
            .offset(x: shake)
            .overlay {
                Color.red.opacity(redFlash)
                    .allowsHitTesting(false)
            }
        }
    }

    private func obstacleColor(paletteIndex: Int) -> Color {
        switch paletteIndex % 4 {
        case 0: return .orange
        case 1: return .yellow
        case 2: return .mint
        default: return .pink
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
            VStack(spacing: 12) {
                Text("얼굴 추적이 끊겼습니다")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("정면을 바라보세요. 잡히면 자동으로 재개됩니다.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal)
            }
        }
        .ignoresSafeArea()
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.72)
            VStack(spacing: 20) {
                Text("게임 오버")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                Text("점수 \(game.score)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                if let r = game.lastGameOverReason {
                    Text(r)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Button("다시 하기") {
                    game.retry()
                }
                .buttonStyle(.borderedProminent)

                Button("타이틀로") {
                    onReturnToMenu()
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(32)
        }
        .ignoresSafeArea()
    }

    private var tutorialOverlay: some View {
        ZStack {
            Color.black.opacity(0.78)
            VStack(alignment: .leading, spacing: 16) {
                Text("고개로 캐릭터를 움직여 피하세요")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 8) {
                    Text("· 얼굴 yaw/pitch에 맞춰 화면 안에서 연속 이동합니다.")
                    Text("· 장애물은 위에서 아래로 떨어집니다.")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                Button("시작") {
                    tutorialSeen = true
                    game.dismissTutorial()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(28)
        }
        .ignoresSafeArea()
    }

    private func shakeGameOver() {
        redFlash = 0.45
        withAnimation(.easeOut(duration: 0.35)) {
            shake = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { shake = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { shake = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation { shake = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { redFlash = 0 }
        }
    }
}
