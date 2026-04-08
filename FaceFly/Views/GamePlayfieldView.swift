import SwiftUI

private enum PlayfieldLayoutKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

/// Flappy Horse 플레이필드 — [docs/flappy-horse-design-guide.md] 패럴랙스 + Asset SVG.
struct GamePlayfieldView: View {
    @ObservedObject var game: FlappyGameModel

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let pw = CGFloat(GameParameters.pipeHalfWidthNorm) * w
            let groundH = h * FlappyHorseTheme.groundBandHeightNorm
            let horseW = w * CGFloat(GameParameters.birdVisualWidthNorm)
            let horseH = horseW * CGFloat(GameParameters.horseAssetViewHeight) / CGFloat(GameParameters.horseAssetViewWidth)

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [FlappyHorseTheme.skyTop, FlappyHorseTheme.skyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                mountainLayer(width: w, height: h)
                    .allowsHitTesting(false)

                cloudLayer(width: w, height: h)
                    .allowsHitTesting(false)

                midGrassLayer(width: w, height: h, groundH: groundH)
                    .allowsHitTesting(false)

                leafLayer(width: w, height: h, groundH: groundH)
                    .allowsHitTesting(false)

                ForEach(game.pipes) { pipe in
                    pillarPair(pipe: pipe, w: w, h: h, pw: pw, groundH: groundH)
                }

                groundScrollLayer(width: w, groundH: groundH, totalHeight: h)
                    .allowsHitTesting(false)

                horseStack(
                    centerX: game.birdX * w,
                    centerY: h - game.birdY * h,
                    horseW: horseW,
                    horseH: horseH
                )

                if game.showBoostFX {
                    boostFX(centerX: game.birdX * w, centerY: h - game.birdY * h)
                }
            }
            .frame(width: w, height: h)
            .clipped()
            .preference(key: PlayfieldLayoutKey.self, value: geo.size)
        }
        .onPreferenceChange(PlayfieldLayoutKey.self) { size in
            guard size.width > 0, size.height > 0 else { return }
            game.updatePlayfieldAspect(width: size.width, height: size.height)
        }
    }

    private func mountainLayer(width w: CGFloat, height h: CGFloat) -> some View {
        let period = w
        let shift = game.worldScrollPhase * w * 0.2
        let ox = shift.truncatingRemainder(dividingBy: period)
        return ZStack(alignment: .topLeading) {
            ForEach(0 ..< 4, id: \.self) { i in
                mountainSilhouette(width: w, height: h)
                    .offset(x: CGFloat(i) * period - ox)
            }
        }
        .frame(width: w, height: h, alignment: .topLeading)
        .clipped()
    }

    private func mountainSilhouette(width w: CGFloat, height h: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: h * 0.5))
            path.addQuadCurve(
                to: CGPoint(x: w * 0.22, y: h * 0.44),
                control: CGPoint(x: w * 0.1, y: h * 0.38)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.48, y: h * 0.48),
                control: CGPoint(x: w * 0.35, y: h * 0.4)
            )
            path.addQuadCurve(
                to: CGPoint(x: w * 0.72, y: h * 0.45),
                control: CGPoint(x: w * 0.6, y: h * 0.39)
            )
            path.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.52),
                control: CGPoint(x: w * 0.86, y: h * 0.42)
            )
            path.addLine(to: CGPoint(x: w, y: h * 0.62))
            path.addLine(to: CGPoint(x: 0, y: h * 0.62))
            path.closeSubpath()
        }
        .fill(FlappyHorseTheme.mountain.opacity(0.55))
        .frame(width: w, height: h)
    }

    private func cloudLayer(width w: CGFloat, height h: CGFloat) -> some View {
        let shift = game.worldScrollPhase * w * 0.4
        let period = w * 0.52
        let ox = shift.truncatingRemainder(dividingBy: period)
        let cloudW = w * 0.36
        return ZStack(alignment: .topLeading) {
            ForEach(0 ..< 8, id: \.self) { i in
                let slot = CGFloat(i) * period - ox - period
                let y = h * (0.06 + CGFloat(i % 3) * 0.055 + sin(CGFloat(i) * 1.1) * 0.02)
                Image("cloud")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cloudW)
                    .position(x: slot + cloudW * 0.48 + CGFloat(i % 2) * 22, y: y)
            }
        }
        .frame(width: w, height: h * 0.48, alignment: .topLeading)
        .clipped()
    }

    private func midGrassLayer(width w: CGFloat, height h: CGFloat, groundH: CGFloat) -> some View {
        let bandH = max(groundH * 0.35, h * 0.06)
        let shift = game.worldScrollPhase * w * 0.7
        let period = w
        let ox = shift.truncatingRemainder(dividingBy: period)
        return ZStack(alignment: .leading) {
            ForEach(0 ..< 4, id: \.self) { i in
                Rectangle()
                    .fill(FlappyHorseTheme.midField)
                    .frame(width: period, height: bandH)
                    .offset(x: CGFloat(i) * period - ox)
            }
        }
        .frame(width: w, height: bandH, alignment: .leading)
        .clipped()
        .position(x: w / 2, y: h - groundH - bandH / 2)
    }

    private func pillarPair(pipe: FlappyGameModel.Pipe, w: CGFloat, h: CGFloat, pw: CGFloat, groundH: CGFloat) -> some View {
        let gapTop = pipe.gapMidY + CGFloat(GameParameters.pipeGapHalfHeightNorm)
        let gapBot = pipe.gapMidY - CGFloat(GameParameters.pipeGapHalfHeightNorm)
        let topPipeH = max(2, (1 - gapTop) * h)
        let rawBotScreenH = gapBot * h
        let botPipeH = max(2, rawBotScreenH - groundH)
        let cx = pipe.x * w
        let topOfBottomPillar = h - rawBotScreenH
        let bottomPillarCenterY = topOfBottomPillar + botPipeH / 2

        return ZStack(alignment: .topLeading) {
            Image("pillar_top")
                .renderingMode(.original)
                .resizable(resizingMode: .stretch)
                .interpolation(.high)
                .frame(width: pw, height: topPipeH)
                .position(x: cx, y: topPipeH / 2)

            Image("pillar_bottom")
                .renderingMode(.original)
                .resizable(resizingMode: .stretch)
                .interpolation(.high)
                .frame(width: pw, height: botPipeH)
                .position(x: cx, y: bottomPillarCenterY)
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    private func leafLayer(width w: CGFloat, height h: CGFloat, groundH: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let scroll = Double(game.worldScrollPhase * w * 0.9)
            let yBand = h - groundH - h * 0.08
            let yTop = h * 0.06
            ZStack {
                ForEach(0 ..< 16, id: \.self) { i in
                    let id = Double(i)
                    let seed = id * 97.3 + 13.0
                    let periodX = Double(w) + 140.0
                    let xWrapped = (seed + scroll + sin(t * 0.7 + id) * 18.0).truncatingRemainder(dividingBy: periodX)
                    let x = CGFloat(xWrapped) - 50.0
                    let fall = (t * 0.09 + id * 0.27).truncatingRemainder(dividingBy: 1.0)
                    let y = yTop + CGFloat(fall) * (yBand - yTop)
                    let sway = sin(t * 2.2 + id) * 12.0
                    let rot = Angle(degrees: sin(t * 1.5 + id) * 25)
                    Image(i % 2 == 0 ? "leaf_round" : "leaf_star")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: i % 2 == 0 ? 18 : 15)
                        .rotationEffect(rot)
                        .position(x: x + CGFloat(sway), y: y)
                }
            }
            .frame(width: w, height: h)
        }
    }

    private func groundScrollLayer(width w: CGFloat, groundH: CGFloat, totalHeight h: CGFloat) -> some View {
        let aspect: CGFloat = 400.0 / 80.0
        let tileW = max(1, groundH * aspect)
        let shift = game.worldScrollPhase * w
        let ox = shift.truncatingRemainder(dividingBy: tileW)
        let tileCount = max(5, Int(ceil((w + 2 * tileW) / tileW)) + 2)

        return HStack(spacing: 0) {
            ForEach(0 ..< tileCount, id: \.self) { _ in
                Image("ground_band")
                    .renderingMode(.original)
                    .resizable(resizingMode: .stretch)
                    .frame(width: tileW, height: groundH)
            }
        }
        .offset(x: -ox)
        .frame(width: w, height: groundH, alignment: .leading)
        .clipped()
        .position(x: w / 2, y: h - groundH / 2)
    }

    private func horseStack(centerX: CGFloat, centerY: CGFloat, horseW: CGFloat, horseH: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let wobble = sin(t * Double.pi * 2.0 / 0.4) * 1.2
            let useJump = game.birdVy > 0
            let gallopY = game.runAnimationPhase ? 1.0 : -1.0

            ZStack {
                Image(useJump ? "horse_jump" : "horse_run")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: horseW, height: horseH)
                    .scaleEffect(game.playerScale)
                    .scaleEffect(x: 1, y: useJump ? 1 : 1 + CGFloat(gallopY) * 0.015, anchor: .center)
                    .offset(y: wobble)
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)

                if game.hitFlashActive {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.45))
                        .frame(width: horseW * 1.05, height: horseH * 1.05)
                }
            }
            .position(x: centerX, y: centerY)
        }
        .allowsHitTesting(false)
    }

    private func boostFX(centerX: CGFloat, centerY: CGFloat) -> some View {
        Group {
            RoundedRectangle(cornerRadius: 3)
                .fill(FlappyHorseTheme.boostFlame)
                .frame(width: 10, height: 10)
                .position(x: centerX - 22, y: centerY + 4)
            RoundedRectangle(cornerRadius: 3)
                .fill(FlappyHorseTheme.boostFlame.opacity(0.85))
                .frame(width: 8, height: 14)
                .position(x: centerX - 32, y: centerY + 2)
            RoundedRectangle(cornerRadius: 3)
                .fill(FlappyHorseTheme.boostFlame.opacity(0.7))
                .frame(width: 6, height: 6)
                .position(x: centerX - 18, y: centerY - 8)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    GamePlayfieldView(game: FlappyGameModel())
}
