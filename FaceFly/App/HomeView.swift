import SwiftUI

struct HomeView: View {
    var needsBlinkBaselineSetup: Bool = false
    let onPlay: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.75, blue: 0.95), Color(red: 0.2, green: 0.45, blue: 0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("FaceFly")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 2)

                Button(action: onPlay) {
                    Text("플레이")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: 260)
                        .padding(.vertical, 16)
                        .background(Rectangle().fill(Color.yellow.opacity(0.95)))
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                        .foregroundStyle(.black)
                }

                Button(action: onSettings) {
                    HStack(spacing: 8) {
                        if needsBlinkBaselineSetup {
                            Text("권장")
                                .font(.caption2.weight(.heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange))
                                .foregroundStyle(.white)
                        }
                        Text("설정")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: 260)
                    .padding(.vertical, 14)
                    .background(Rectangle().fill(needsBlinkBaselineSetup ? Color.cyan.opacity(0.35) : Color.white.opacity(0.92)))
                    .overlay(
                        Rectangle().stroke(
                            needsBlinkBaselineSetup ? Color.cyan : Color.black,
                            lineWidth: needsBlinkBaselineSetup ? 4 : 3
                        )
                    )
                    .foregroundStyle(.black)
                }

                if needsBlinkBaselineSetup {
                    VStack(alignment: .leading, spacing: 10) {
                        (
                            Text("눈 깜빡임 점프가 잘 맞도록, 먼저 ")
                                + Text("설정").fontWeight(.heavy)
                                + Text("에서 눈 뜸 기준을 측정해 저장하는 것을 권장합니다.")
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        Button(action: onSettings) {
                            Text("설정에서 측정하기")
                                .font(.subheadline.weight(.bold))
                                .underline()
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 300)
                    .background(Rectangle().fill(Color.black.opacity(0.28)))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.45), lineWidth: 2))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    HomeView(needsBlinkBaselineSetup: true, onPlay: {}, onSettings: {})
}
