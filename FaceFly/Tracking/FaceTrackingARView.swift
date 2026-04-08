@preconcurrency import ARKit
import SwiftUI

/// Runs `ARFaceTrackingConfiguration` and forwards blend shapes + yaw (PRD §5.1–5.2).
struct FaceTrackingARView: UIViewRepresentable {
    var onSnapshot: @MainActor (FaceInputSnapshot) -> Void
    /// 값이 바뀔 때마다 추적을 초기화해 얼굴 앵커를 다시 잡습니다.
    var arSessionResetNonce: Int = 0
    /// `false`이면 세션을 `pause()`해 홈 등에서 카메라·추적 부하를 줄입니다(설정/플레이에서만 동작).
    var isTrackingActive: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(onSnapshot: onSnapshot)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session.delegate = context.coordinator
        view.automaticallyUpdatesLighting = false
        view.isUserInteractionEnabled = false
        context.coordinator.lastAppliedResetNonce = arSessionResetNonce
        context.coordinator.shouldRunSession = isTrackingActive
        if isTrackingActive {
            context.coordinator.attach(session: view.session, resetTracking: true)
        }
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.onSnapshot = onSnapshot
        context.coordinator.shouldRunSession = isTrackingActive

        if context.coordinator.lastAppliedResetNonce != arSessionResetNonce {
            context.coordinator.lastAppliedResetNonce = arSessionResetNonce
            if isTrackingActive {
                context.coordinator.attach(session: uiView.session, resetTracking: true)
            }
        } else if context.coordinator.lastIsTrackingActive != isTrackingActive {
            if isTrackingActive {
                context.coordinator.resumeSession(uiView.session)
            } else {
                uiView.session.pause()
            }
        }
        context.coordinator.lastIsTrackingActive = isTrackingActive
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate, @unchecked Sendable {
        var onSnapshot: @MainActor (FaceInputSnapshot) -> Void
        var lastAppliedResetNonce: Int = 0
        /// `updateUIView`에서 갱신 — 인터럽트 복구 시 불필요한 `run` 방지.
        var shouldRunSession: Bool = true
        var lastIsTrackingActive: Bool?

        init(onSnapshot: @escaping @MainActor (FaceInputSnapshot) -> Void) {
            self.onSnapshot = onSnapshot
        }

        private func makeFaceTrackingConfiguration() -> ARFaceTrackingConfiguration {
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = false
            config.maximumNumberOfTrackedFaces = 1
            return config
        }

        func attach(session: ARSession, resetTracking: Bool) {
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = makeFaceTrackingConfiguration()
            let options: ARSession.RunOptions = resetTracking ? [.resetTracking, .removeExistingAnchors] : []
            session.run(config, options: options)
        }

        /// `pause()` 이후 재개 — 트래킹 리셋 없이 세션만 이어갑니다.
        func resumeSession(_ session: ARSession) {
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = makeFaceTrackingConfiguration()
            session.run(config, options: [])
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            var latest: FaceInputSnapshot?
            for anchor in anchors {
                guard let face = anchor as? ARFaceAnchor else { continue }
                let bs = face.blendShapes
                let left = bs[.eyeBlinkLeft]?.floatValue ?? 0
                let right = bs[.eyeBlinkRight]?.floatValue ?? 0
                let jaw = bs[.jawOpen]?.floatValue ?? 0
                let yaw = HeadPose.yawRadians(from: face.transform)
                let pitch = HeadPose.pitchRadians(from: face.transform)
                let t = session.currentFrame?.timestamp ?? ProcessInfo.processInfo.systemUptime
                latest = FaceInputSnapshot(
                    eyeBlinkLeft: left,
                    eyeBlinkRight: right,
                    jawOpen: jaw,
                    headYawRadians: yaw,
                    headPitchRadians: pitch,
                    hasFace: true,
                    timestamp: t
                )
            }
            guard let snap = latest else { return }
            let callback = onSnapshot
            Task { @MainActor in
                callback(snap)
            }
        }

        nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                guard anchor is ARFaceAnchor else { continue }
                let t = session.currentFrame?.timestamp ?? ProcessInfo.processInfo.systemUptime
                let callback = onSnapshot
                Task { @MainActor in
                    callback(
                        FaceInputSnapshot(
                            eyeBlinkLeft: 0,
                            eyeBlinkRight: 0,
                            jawOpen: 0,
                            headYawRadians: 0,
                            headPitchRadians: 0,
                            hasFace: false,
                            timestamp: t
                        )
                    )
                }
            }
        }

        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            emitLost(session: session)
        }

        nonisolated func sessionInterruptionEnded(_ session: ARSession) {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.shouldRunSession else { return }
                self.attach(session: session, resetTracking: true)
            }
        }

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            emitLost(session: session)
        }

        nonisolated private func emitLost(session: ARSession) {
            let t = session.currentFrame?.timestamp ?? ProcessInfo.processInfo.systemUptime
            let callback = onSnapshot
            Task { @MainActor in
                callback(
                    FaceInputSnapshot(
                        eyeBlinkLeft: 0,
                        eyeBlinkRight: 0,
                        jawOpen: 0,
                        headYawRadians: 0,
                        headPitchRadians: 0,
                        hasFace: false,
                        timestamp: t
                    )
                )
            }
        }
    }
}
