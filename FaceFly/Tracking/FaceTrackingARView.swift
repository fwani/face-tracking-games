import ARKit
import SwiftUI

/// Runs `ARFaceTrackingConfiguration` and forwards blend shapes + yaw (PRD §5.1–5.2).
struct FaceTrackingARView: UIViewRepresentable {
    var onSnapshot: @MainActor (FaceInputSnapshot) -> Void
    /// 값이 바뀔 때마다 추적을 초기화해 얼굴 앵커를 다시 잡습니다.
    var arSessionResetNonce: Int = 0

    func makeCoordinator() -> Coordinator {
        Coordinator(onSnapshot: onSnapshot)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session.delegate = context.coordinator
        view.automaticallyUpdatesLighting = true
        view.isUserInteractionEnabled = false
        context.coordinator.attach(session: view.session)
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.onSnapshot = onSnapshot
        if context.coordinator.lastAppliedResetNonce != arSessionResetNonce {
            context.coordinator.lastAppliedResetNonce = arSessionResetNonce
            context.coordinator.attach(session: uiView.session)
        }
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        var onSnapshot: @MainActor (FaceInputSnapshot) -> Void
        var lastAppliedResetNonce: Int = 0

        init(onSnapshot: @escaping @MainActor (FaceInputSnapshot) -> Void) {
            self.onSnapshot = onSnapshot
        }

        func attach(session: ARSession) {
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = ARFaceTrackingConfiguration()
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
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
                self?.attach(session: session)
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
