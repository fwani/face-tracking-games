import ARKit
import simd

enum HeadPose {
    /// Yaw about world-up from face anchor orientation (radians).
    static func yawRadians(from faceTransform: simd_float4x4) -> Float {
        let q = simd_quaternion(faceTransform)
        let qv = q.vector
        let sinYaw = 2 * (qv.w * qv.y + qv.x * qv.z)
        let cosYaw = 1 - 2 * (qv.y * qv.y + qv.z * qv.z)
        return atan2(sinYaw, cosYaw)
    }

    /// Pitch (nod): radians, positive ≈ chin down toward screen on typical front-camera setup.
    static func pitchRadians(from faceTransform: simd_float4x4) -> Float {
        let q = simd_quaternion(faceTransform)
        let qv = q.vector
        let sinPitch = 2 * (qv.w * qv.x - qv.y * qv.z)
        let clamped = min(1, max(-1, sinPitch))
        return asin(clamped)
    }
}
