import SwiftUI

struct HomeView: View {
    var needsBlinkBaselineSetup: Bool = false
    let onPlay: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FlappyHorseTheme.skyTop, FlappyHorseTheme.skyBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("FaceFly")
                    .font(.system(size: 44, weight: .heavy))
                    .monospaced()
                    .foregroundStyle(FlappyHorseTheme.hudCream)
                    .shadow(color: FlappyHorseTheme.hudShadow.opacity(0.6), radius: 0, x: 2, y: 2)

                Button(action: onPlay) {
                    Text("플레이")
                        .font(.title2.weight(.bold))
                        .monospaced()
                        .frame(maxWidth: 260)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .background(FlappyHorseTheme.goldenButton)
                        .foregroundStyle(FlappyHorseTheme.buttonText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onSettings) {
                    HStack(spacing: 8) {
                        if needsBlinkBaselineSetup {
                            Text("권장")
                                .font(.caption2.weight(.heavy))
                                .monospaced()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(FlappyHorseTheme.goldenButtonPressed))
                                .foregroundStyle(FlappyHorseTheme.hudCream)
                        }
                        Text("설정")
                            .font(.headline.weight(.semibold))
                            .monospaced()
                    }
                    .frame(maxWidth: 260)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(needsBlinkBaselineSetup ? FlappyHorseTheme.skyTop.opacity(0.45) : FlappyHorseTheme.hudCream.opacity(0.92))
                    )
                    .foregroundStyle(FlappyHorseTheme.buttonText)
                }

                if needsBlinkBaselineSetup {
                    VStack(alignment: .leading, spacing: 10) {
                        (
                            Text("눈 깜빡임 점프가 잘 맞도록, 먼저 ")
                                + Text("설정").fontWeight(.heavy)
                                + Text("에서 눈 뜸 기준을 측정해 저장하는 것을 권장합니다.")
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FlappyHorseTheme.hudCream)
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        Button(action: onSettings) {
                            Text("설정에서 측정하기")
                                .font(.subheadline.weight(.bold))
                                .monospaced()
                                .underline()
                                .foregroundStyle(FlappyHorseTheme.hudCream)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.28))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(FlappyHorseTheme.hudCream.opacity(0.45), lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    HomeView(needsBlinkBaselineSetup: true, onPlay: {}, onSettings: {})
}
