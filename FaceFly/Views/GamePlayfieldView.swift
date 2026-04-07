import SwiftUI

/// 단순 사각형만 사용하는 플레이필드 (PRD §6.1).
struct GamePlayfieldView: View {
    @ObservedObject var game: FlappyGameModel

    private let skyTop = Color(red: 0.52, green: 0.78, blue: 0.96)
    private let skyBottom = Color(red: 0.42, green: 0.68, blue: 0.90)
    private let stripe = Color(red: 0.38, green: 0.62, blue: 0.82).opacity(0.35)
    private let ground = Color(red: 0.52, green: 0.48, blue: 0.42)
    private let pipeColor = Color(red: 0.28, green: 0.62, blue: 0.34)
    private let birdColor = Color(red: 0.98, green: 0.52, blue: 0.12)
    private let flameColor = Color(red: 0.95, green: 0.22, blue: 0.12)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pw = CGFloat(GameParameters.pipeHalfWidthNorm) * w
            let bw = CGFloat(GameParameters.birdHalfWidthNorm) * w * 2
            let bh = CGFloat(GameParameters.birdHalfHeightNorm) * h * 2

            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                stripeLayer(width: w, height: h)

                ForEach(game.pipes) { pipe in
                    pipeViews(pipe: pipe, w: w, h: h, pw: pw, pipeColor: pipeColor)
                }

                Rectangle()
                    .fill(ground)
                    .frame(width: w, height: h * 0.07)
                    .position(x: w / 2, y: h - (h * 0.07) / 2)

                if game.showBoostFX {
                    boostSquares(centerX: game.birdX * w, centerY: h - game.birdY * h, flameColor: flameColor)
                }

                Rectangle()
                    .fill(birdColor)
                    .frame(width: bw, height: bh)
                    .scaleEffect(game.playerScale)
                    .position(x: game.birdX * w, y: h - game.birdY * h)
            }
            .frame(width: w, height: h)
        }
    }

    private func stripeLayer(width w: CGFloat, height h: CGFloat) -> some View {
        let phase = game.worldScrollPhase.truncatingRemainder(dividingBy: 1)
        return HStack(spacing: 0) {
            ForEach(0 ..< 12, id: \.self) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? stripe : Color.clear)
                    .frame(width: w / 8)
            }
        }
        .offset(x: -phase * w * 0.25)
        .allowsHitTesting(false)
    }

    private func pipeViews(
        pipe: FlappyGameModel.Pipe,
        w: CGFloat,
        h: CGFloat,
        pw: CGFloat,
        pipeColor: Color
    ) -> some View {
        let gapTop = pipe.gapMidY + CGFloat(GameParameters.pipeGapHalfHeightNorm)
        let gapBot = pipe.gapMidY - CGFloat(GameParameters.pipeGapHalfHeightNorm)
        let topPipeH = max(0.01, (1 - gapTop)) * h
        let botPipeH = max(0.01, gapBot) * h
        let cx = pipe.x * w

        return Group {
            Rectangle()
                .fill(pipeColor)
                .frame(width: pw, height: topPipeH)
                .position(x: cx, y: topPipeH / 2)
            Rectangle()
                .fill(pipeColor)
                .frame(width: pw, height: botPipeH)
                .position(x: cx, y: h - botPipeH / 2)
        }
    }

    private func boostSquares(centerX: CGFloat, centerY: CGFloat, flameColor: Color) -> some View {
        Group {
            Rectangle()
                .fill(flameColor)
                .frame(width: 10, height: 10)
                .position(x: centerX - 22, y: centerY + 4)
            Rectangle()
                .fill(flameColor.opacity(0.85))
                .frame(width: 8, height: 14)
                .position(x: centerX - 32, y: centerY + 2)
            Rectangle()
                .fill(flameColor.opacity(0.7))
                .frame(width: 6, height: 6)
                .position(x: centerX - 18, y: centerY - 8)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    GamePlayfieldView(game: FlappyGameModel())
}
