@preconcurrency import ARKit
import SwiftUI

/// `ARFaceTrackingConfiguration` + `ARFaceAnchor` → `ObstacleDodgeFaceSnapshot` (yaw/pitch 라디안).
struct ObstacleDodgeARView: UIViewRepresentable {
    var onSnapshot: @MainActor (ObstacleDodgeFaceSnapshot) -> Void
    var arSessionResetNonce: Int = 0
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
        var onSnapshot: @MainActor (ObstacleDodgeFaceSnapshot) -> Void
        var lastAppliedResetNonce: Int = 0
        var shouldRunSession: Bool = true
        var lastIsTrackingActive: Bool?

        init(onSnapshot: @escaping @MainActor (ObstacleDodgeFaceSnapshot) -> Void) {
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

        func resumeSession(_ session: ARSession) {
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = makeFaceTrackingConfiguration()
            session.run(config, options: [])
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            var latest: ObstacleDodgeFaceSnapshot?
            for anchor in anchors {
                guard let face = anchor as? ARFaceAnchor else { continue }
                let yaw = ObstacleDodgeHeadPose.yawRadians(from: face.transform)
                let pitch = ObstacleDodgeHeadPose.pitchRadians(from: face.transform)
                let t = session.currentFrame?.timestamp ?? ProcessInfo.processInfo.systemUptime
                latest = ObstacleDodgeFaceSnapshot(
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
                        ObstacleDodgeFaceSnapshot(
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
                    ObstacleDodgeFaceSnapshot(
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
