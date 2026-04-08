import ARKit
import AVFoundation
import SwiftUI

private enum ObstacleDodgeShellRoute {
    /// 난이도·시작 (카메라 끔)
    case title
    /// 옵션 화면 (카메라 켬 — FaceFly `settings`와 동일 정책)
    case settings
    /// 플레이 세션 (진행·일시정지만 카메라 켬, 게임오버·튜토리얼 오버레이 시 끔)
    case game
}

/// ObstacleDodge 진입 루트 — 권한·AR 세션·게임 화면 (`plan.md` Phase 1).
struct ObstacleDodgeRootView: View {
    var onExitToHub: () -> Void

    @StateObject private var game = ObstacleDodgeGameModel()
    @State private var shellRoute: ObstacleDodgeShellRoute = .title
    @State private var cameraAuthorized: Bool?
    @State private var arResetNonce = 0
    @AppStorage("obstacleDodgeDemoAutoRestart") private var demoAutoRestart = false
    @AppStorage("obstacleDodgeMuteEffects") private var muteEffects = false

    private var arActive: Bool {
        cameraAuthorized == true && ARFaceTrackingConfiguration.isSupported
    }

    /// 플레이(playing·paused) 또는 설정 화면에서만 추적 — 타이틀·게임오버·허브 등에서는 `pause`.
    private var arFaceTrackingSessionActive: Bool {
        guard arActive else { return false }
        switch shellRoute {
        case .title:
            return false
        case .settings:
            return true
        case .game:
            return game.phase == .playing || game.phase == .paused
        }
    }

    var body: some View {
        ZStack {
            if arActive {
                ObstacleDodgeARView(
                    onSnapshot: { game.ingestFaceSnapshot($0) },
                    arSessionResetNonce: arResetNonce,
                    isTrackingActive: arFaceTrackingSessionActive
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            switch shellRoute {
            case .title:
                titleLayer
            case .settings:
                settingsLayer
            case .game:
                ObstacleDodgePlayView(
                    game: game,
                    demoAutoRestart: demoAutoRestart,
                    onBackToHub: onExitToHub,
                    onReturnToMenu: {
                        game.returnToTitle()
                        shellRoute = .title
                    }
                )
            }
        }
        .onAppear {
            requestCameraIfNeeded()
        }
    }

    private var titleLayer: some View {
        ZStack {
            Color.black.opacity(0.72)
            VStack(spacing: 20) {
                Text("장애물 피하기")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                if cameraAuthorized == false {
                    Text("카메라 권한이 필요합니다. 설정에서 허용해 주세요.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal)
                    Button("설정 열기") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else if !ARFaceTrackingConfiguration.isSupported {
                    Text("이 기기에서는 AR 얼굴 추적을 사용할 수 없습니다. 실제 아이폰·아이패드에서 실행해 주세요.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal)
                } else {
                    Picker("난이도", selection: $game.difficulty) {
                        ForEach(ObstacleDodgeDifficulty.allCases) { d in
                            Text(d.displayTitle).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(.white)

                    Button("게임 시작") {
                        let showTutorial = !UserDefaults.standard.bool(forKey: "obstacleDodgeTutorialSeen")
                        shellRoute = .game
                        arResetNonce += 1
                        game.startFromTitle(showTutorial: showTutorial)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("설정") {
                        shellRoute = .settings
                        arResetNonce += 1
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.9))
                }

                Button("허브로 돌아가기") {
                    onExitToHub()
                }
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(24)
        }
        .ignoresSafeArea()
    }

    private var settingsLayer: some View {
        ZStack {
            Color.black.opacity(0.78)
            VStack(alignment: .leading, spacing: 20) {
                Text("설정")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                Toggle("전시: 게임오버 후 자동 재시작", isOn: $demoAutoRestart)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.95))
                    .tint(.cyan)
                Toggle("효과음 끄기", isOn: $muteEffects)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.95))
                    .tint(.orange)

                Text("이 화면에서는 카메라·얼굴 추적이 켜져 옵션을 조정할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 16) {
                    Button("완료") {
                        shellRoute = .title
                    }
                    .buttonStyle(.borderedProminent)

                    Button("허브로") {
                        onExitToHub()
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
        .ignoresSafeArea()
    }

    private func requestCameraIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { ok in
                DispatchQueue.main.async {
                    cameraAuthorized = ok
                    if ok { arResetNonce += 1 }
                }
            }
        case .denied, .restricted:
            cameraAuthorized = false
        @unknown default:
            cameraAuthorized = false
        }
    }
}
