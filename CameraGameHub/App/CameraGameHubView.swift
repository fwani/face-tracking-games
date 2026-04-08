import SwiftUI

/// 앱 루트 — Camera Game Hub (`docs/game-hub.md`).
struct CameraGameHubView: View {
    let onSelectGame: (HubGame) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.18),
                    Color(red: 0.16, green: 0.18, blue: 0.26),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("카메라 게임 허브")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Camera Game Hub")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 8)

                Text("플레이할 게임을 선택하세요")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Button {
                    onSelectGame(.faceFly)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FaceFly")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("전면 카메라 · 얼굴로 조작하는 플래피 스타일")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onSelectGame(.obstacleDodge)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("장애물 피하기")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("고개 방향으로 날아오는 장애물 회피")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    CameraGameHubView(onSelectGame: { _ in })
}
