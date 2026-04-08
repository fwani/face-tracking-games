import ARKit
import SwiftUI

private enum AppRoute {
    case home
    case settings
    case playing
}

/// FaceFly 전용 플로우 — 얼굴 트래킹 입력 · 홈 · 설정 · 플레이.
struct FaceFlyRootView: View {
    let onBackToHub: () -> Void

    @StateObject private var tracking = FaceTrackingSessionModel()
    @StateObject private var game = FlappyGameModel()

    @AppStorage(GameParameters.tutorialDefaultsKey) private var tutorialDone = false
    @State private var route: AppRoute = .home
    @State private var showTutorial = false
    @State private var showDebug = false
    @State private var lastTick = Date()
    @State private var simJumpPulse = false
    @State private var simBoostHeld = false
    @State private var settingsBlinkCalibrationActive = false
    @State private var settingsBlinkJumpTestActive = false
    @State private var arSessionResetNonce = 0
    @State private var showPlayWithoutBaselineConfirm = false
    @State private var selectedDifficulty: Difficulty = .normal

    private let arSupported = ARFaceTrackingConfiguration.isSupported

    private var arFaceTrackingSessionActive: Bool {
        arSupported && (route == .settings || route == .playing)
    }

    private var needsBlinkBaselineSetup: Bool {
        arSupported && !BlinkBaselineStorage.hasStoredCalibration
    }

    private let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            FaceTrackingARView(
                onSnapshot: { snap in
                    let calibrateBlink = arSupported && (
                        (route == .playing && !showTutorial && !tracking.isBlinkBaselineLocked)
                            || (route == .settings && settingsBlinkCalibrationActive && !tracking.isBlinkBaselineLocked)
                    )
                    let commitDisk = route == .settings && settingsBlinkCalibrationActive
                    let jumpTest = route == .settings && settingsBlinkJumpTestActive
                    tracking.ingest(
                        snap,
                        blinkCalibrationAllowed: calibrateBlink,
                        commitSettingsCalibrationToDisk: commitDisk,
                        settingsBlinkJumpTestActive: jumpTest
                    )
                },
                arSessionResetNonce: arSessionResetNonce,
                isTrackingActive: arFaceTrackingSessionActive
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)

            switch route {
            case .home:
                homeLayer
            case .settings:
                FaceSettingsView(
                    tracking: tracking,
                    arSupported: arSupported,
                    settingsBlinkCalibrationActive: $settingsBlinkCalibrationActive,
                    settingsBlinkJumpTestActive: $settingsBlinkJumpTestActive,
                    onRequestARSessionReset: { arSessionResetNonce += 1 }
                ) {
                    settingsBlinkCalibrationActive = false
                    settingsBlinkJumpTestActive = false
                    route = .home
                }
            case .playing:
                playingLayer
            }
        }
        .onReceive(timer) { now in
            guard route == .playing else { return }
            guard !showTutorial else { return }
            guard !arSupported || tracking.isBlinkBaselineLocked else { return }
            let dt = CGFloat(min(now.timeIntervalSince(lastTick), 0.05))
            lastTick = now
            let input = effectiveInput()
            game.tick(dt: dt, input: input, pauseForTracking: pauseForTracking)
            simJumpPulse = false
        }
        .onAppear {
            lastTick = Date()
        }
        .onChange(of: route) { new in
            if new == .playing {
                tracking.notifyPlaySessionStarted()
            } else {
                tracking.notifyPlaySessionEnded()
            }
            if new == .settings {
                tracking.applyStoredBlinkBaselineIfNeeded()
            }
            if new != .settings {
                tracking.cancelPendingHeadNeutralRecalibration()
            }
        }
        .onChange(of: settingsBlinkJumpTestActive) { _ in
            tracking.resetSettingsBlinkJumpTestSession()
        }
    }

    private var homeLayer: some View {
        HomeView(
            needsBlinkBaselineSetup: needsBlinkBaselineSetup,
            selectedDifficulty: $selectedDifficulty,
            onPlay: {
                if needsBlinkBaselineSetup {
                    showPlayWithoutBaselineConfirm = true
                } else {
                    startPlayFromHome()
                }
            },
            onSettings: { route = .settings },
            onBackToHub: {
                onBackToHub()
                showTutorial = false
                showDebug = false
                game.restart()
            }
        )
        .confirmationDialog(
            "저장된 눈 뜸 기준이 없습니다. 설정에서 측정할까요?",
            isPresented: $showPlayWithoutBaselineConfirm,
            titleVisibility: .visible
        ) {
            Button("설정으로") {
                route = .settings
            }
            Button("바로 플레이") {
                startPlayFromHome()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정에서 측정하면 게임 시작 후 바로 플레이할 수 있습니다.")
        }
    }

    private func startPlayFromHome() {
        game.configure(difficulty: selectedDifficulty)
        route = .playing
        if !tutorialDone {
            showTutorial = true
        }
        lastTick = Date()
    }

    private var playingLayer: some View {
        ZStack {
            GamePlayfieldView(game: game)
                .ignoresSafeArea()

            VStack {
                ZStack {
                    Text("\(game.score)")
                        .font(.system(size: FlappyHorseTheme.scoreFontSize, weight: .bold, design: .monospaced))
                        .foregroundStyle(FlappyHorseTheme.hudCream)
                        .shadow(color: FlappyHorseTheme.hudShadow, radius: 0, x: 2, y: 2)

                    HStack {
                        Button {
                            route = .home
                        } label: {
                            Text("홈")
                                .font(.caption.weight(.bold))
                                .monospaced()
                                .foregroundStyle(FlappyHorseTheme.hudCream)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FlappyHorseTheme.gameOverPanel.opacity(0.55))
                                )
                        }
                        Spacer()
                        Button {
                            showDebug.toggle()
                        } label: {
                            Text("DBG")
                                .font(.caption2.bold())
                                .monospaced()
                                .foregroundStyle(FlappyHorseTheme.hudCream)
                                .frame(width: 44, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.35))
                                )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                Spacer()
            }

            if !arSupported {
                simControlsBar
            }

            if pauseForTracking {
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                Text("얼굴 인식 대기")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }

            if game.isGameOver {
                gameOverCard
            }

            if showTutorial {
                tutorialCard
            }

            if showDebug {
                debugPanel
            }
        }
    }

    private var pauseForTracking: Bool {
        arSupported && tracking.gameInput.trackingLost
    }

    private func effectiveInput() -> GameInput {
        tracking.gameInput.mergingSimulator(
            jumpPulse: simJumpPulse,
            boostHeld: simBoostHeld,
            arSupported: arSupported
        )
    }

    private var simControlsBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Text("시뮬")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Rectangle().fill(Color.purple.opacity(0.85)))
                Button {
                    simJumpPulse = true
                } label: {
                    Text("점프")
                        .font(.caption.bold())
                        .monospaced()
                        .foregroundStyle(FlappyHorseTheme.buttonText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(FlappyHorseTheme.goldenButton)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(showTutorial || game.isGameOver)
                Toggle("부스터", isOn: $simBoostHeld)
                    .tint(.orange)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Rectangle().fill(Color.black.opacity(0.45)))
            }
            .padding(.bottom, 24)
        }
    }

    private var gameOverCard: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("게임 오버")
                    .font(.title.bold())
                    .monospaced()
                    .foregroundStyle(FlappyHorseTheme.hudCream)
                Text("점수 \(game.score)")
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(FlappyHorseTheme.hudCream)
                Button {
                    game.restart()
                } label: {
                    Text("다시")
                        .font(.headline.weight(.bold))
                        .monospaced()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(FlappyHorseTheme.goldenButton)
                        .foregroundStyle(FlappyHorseTheme.buttonText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: 220)
                Button {
                    route = .home
                } label: {
                    Text("홈으로")
                        .font(.subheadline.weight(.semibold))
                        .monospaced()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(FlappyHorseTheme.hudCream)
                }
                .frame(width: 220)
            }
            .padding(32)
            .background(FlappyHorseTheme.gameOverPanel.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var tutorialCard: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text("조작 안내")
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: 8) {
                    labelRow(color: .orange, text: "눈 깜빡임 → 점프")
                    labelRow(color: .red, text: "입 벌리기 → 부스터")
                    labelRow(color: .blue, text: "고개 좌우 → 이동")
                }
                .font(.body.weight(.medium))
                Button {
                    tutorialDone = true
                    showTutorial = false
                    game.restart()
                } label: {
                    Text("시작")
                        .font(.headline.weight(.bold))
                        .monospaced()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(FlappyHorseTheme.goldenButton)
                        .foregroundStyle(FlappyHorseTheme.buttonText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Rectangle().fill(Color.white))
            .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
        }
    }

    private func labelRow(color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(color)
                .frame(width: 14, height: 14)
            Text(text)
        }
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("입력")
                .font(.caption.bold())
            Text("Blink μ \(fmt((tracking.snapshot.eyeBlinkLeft + tracking.snapshot.eyeBlinkRight) * 0.5))")
            Text("Jaw \(fmt(tracking.snapshot.jawOpen))")
            Text("Jump \(tracking.gameInput.jumpImpulse ? "Y" : "—") Boost \(tracking.gameInput.boostActive ? "Y" : "—")")
            Text("X̂ \(fmt(tracking.gameInput.horizontalNormalized))")
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(8)
        .background(.ultraThinMaterial)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(8)
        .allowsHitTesting(false)
    }

    private func fmt(_ v: Float) -> String {
        String(format: "%.2f", v)
    }
}

#Preview {
    FaceFlyRootView(onBackToHub: {})
}
