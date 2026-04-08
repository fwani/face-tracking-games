import ARKit
import simd

/// `ARFaceAnchor.transform`(카메라 좌표계)에서 **yaw / pitch** 를 뽑는다. 내부 표현은 **라디안** 고정.
///
/// **부호 규칙 (전면 카메라·일반적인 고개 움직임):**
/// - **yaw**: 양(+) ≈ 고개를 **오른쪽**으로 돌림(화면 기준). 음(-) ≈ **왼쪽**.
/// - **pitch**: 양(+) ≈ **턱을 아래로**(숙임, chin toward chest). 음(-) ≈ **고개를 들어 올림**.
enum ObstacleDodgeHeadPose {
    /// 수평 회전 (yaw), 라디안.
    static func yawRadians(from faceTransform: simd_float4x4) -> Float {
        let q = simd_quaternion(faceTransform)
        let qv = q.vector
        let sinYaw = 2 * (qv.w * qv.y + qv.x * qv.z)
        let cosYaw = 1 - 2 * (qv.y * qv.y + qv.z * qv.z)
        return atan2(sinYaw, cosYaw)
    }

    /// 상하 끄덕임 (pitch), 라디안.
    static func pitchRadians(from faceTransform: simd_float4x4) -> Float {
        let q = simd_quaternion(faceTransform)
        let qv = q.vector
        let sinPitch = 2 * (qv.w * qv.x - qv.y * qv.z)
        let clamped = min(1, max(-1, sinPitch))
        return asin(clamped)
    }
}
