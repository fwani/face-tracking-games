import SwiftUI

struct FaceSettingsView: View {
    @ObservedObject var tracking: FaceTrackingSessionModel
    let arSupported: Bool
    @Binding var settingsBlinkCalibrationActive: Bool
    @Binding var settingsBlinkJumpTestActive: Bool
    let onRequestARSessionReset: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: onBack) {
                        Text("뒤로")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Rectangle().fill(Color.gray.opacity(0.55)))
                            .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Text("설정")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                facePoseSection

                if arSupported {
                    blinkCalibrationSection
                    Text(
                        "게임에서는 저장된 눈 뜸 기준으로 바로 플레이됩니다. 처음이거나 다시 맞추려면 위에서 측정하세요. 저장 없이 플레이하면 게임 시작 후 잠시 멈춘 상태에서 같은 방식으로 자동 캘리브됩니다."
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.visible)
        .background(Color(red: 0.12, green: 0.14, blue: 0.2).ignoresSafeArea())
        .onChange(of: tracking.isBlinkBaselineLocked) { locked in
            if locked {
                settingsBlinkCalibrationActive = false
            } else {
                settingsBlinkJumpTestActive = false
            }
        }
    }

    private var blinkCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("눈 깜빡임(점프) 기준")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(
                "정면을 유지한 채 눈을 뜬 상태로 약 \(Int(GameParameters.blinkBaselineWindowSeconds))초간 유지하면, 게임 시작과 동일한 방식으로 기준이 잡히고 저장됩니다."
            )
            .font(.body)
            .foregroundStyle(.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)

            if BlinkBaselineStorage.hasStoredCalibration {
                Text("저장된 기준이 있습니다.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green.opacity(0.95))
            }

            ProgressView(value: Double(tracking.blinkCalibrationProgress))
                .tint(.cyan)

            HStack(spacing: 10) {
                Button {
                    settingsBlinkCalibrationActive = true
                } label: {
                    Text(settingsBlinkCalibrationActive && !tracking.isBlinkBaselineLocked ? "측정 중…" : "눈 뜸 기준 측정 시작")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Rectangle().fill(
                                canStartBlinkCalibration ? Color.cyan.opacity(0.95) : Color.gray.opacity(0.45)
                            )
                        )
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                        .foregroundStyle(canStartBlinkCalibration ? .black : .white.opacity(0.7))
                }
                .disabled(!canStartBlinkCalibration)

                Button {
                    BlinkBaselineStorage.clear()
                    tracking.resetBlinkCalibrationForRemeasure()
                    settingsBlinkCalibrationActive = false
                    settingsBlinkJumpTestActive = false
                } label: {
                    Text("다시 측정")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Rectangle().fill(Color.orange.opacity(0.85)))
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
                        .foregroundStyle(.black)
                }
            }

            if tracking.isBlinkBaselineLocked {
                Text("점프 인식 확인")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                Text("아래를 켠 뒤 눈을 깜빡이면, 게임과 같은 조건으로 감지된 횟수가 올라갑니다.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    "깜빡임 감도: 왼쪽은 연속 인식 간격(시간)만 짧게 해 빠른 연속 깜빡임을 잡기 쉽습니다. 오른쪽은 그 간격을 길게 합니다. 깊이·델타 판정은 게임 기본값을 씁니다."
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("빠른 연속")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        Text("긴 간격")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Slider(
                        value: Binding(
                            get: { Double(tracking.blinkStrictness) },
                            set: { tracking.setBlinkStrictness(Float($0)) }
                        ),
                        in: 0...1
                    )
                    .tint(.cyan)
                }
                .padding(.top, 6)

                Button {
                    tracking.resetBlinkTuningToAppDefaults()
                } label: {
                    Text("감도 기본값으로")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Rectangle().fill(
                                blinkStrictnessIsDefault ? Color.gray.opacity(0.35) : Color.white.opacity(0.2)
                            )
                        )
                        .overlay(Rectangle().stroke(Color.white.opacity(0.35), lineWidth: 2))
                        .foregroundStyle(.white)
                }
                .disabled(blinkStrictnessIsDefault)
                .padding(.top, 4)

                if settingsBlinkJumpTestActive {
                    Text("\(tracking.settingsBlinkJumpCount)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                Button {
                    settingsBlinkJumpTestActive.toggle()
                } label: {
                    Text(settingsBlinkJumpTestActive ? "점프 테스트 끄기" : "점프 인식 테스트")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Rectangle().fill(
                                canToggleJumpTest ? Color.green.opacity(0.88) : Color.gray.opacity(0.45)
                            )
                        )
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                        .foregroundStyle(canToggleJumpTest ? .black : .white.opacity(0.7))
                }
                .disabled(!canToggleJumpTest)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Rectangle().fill(Color.white.opacity(0.1)))
        .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 2))
        .padding(.horizontal, 16)
    }

    private var canToggleJumpTest: Bool {
        tracking.snapshot.hasFace
    }

    private var canStartBlinkCalibration: Bool {
        tracking.snapshot.hasFace
            && !(settingsBlinkCalibrationActive && !tracking.isBlinkBaselineLocked)
            && !tracking.isBlinkBaselineLocked
    }

    private var blinkStrictnessIsDefault: Bool {
        abs(tracking.blinkStrictness - BlinkDetectionTuning.defaultStrictness) < 0.002
    }

    private var facePoseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("얼굴 인식")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            if arSupported {
                Text("아래를 누르면 얼굴 추적이 초기화되고, 잠시 후 얼굴이 다시 잡히면 그 순간의 정면(좌우 기준 중앙)을 저장합니다. 정면을 카메라에 맞춘 뒤 누르세요.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Circle()
                        .fill(tracking.snapshot.hasFace ? Color.green : Color.orange.opacity(0.9))
                        .frame(width: 12, height: 12)
                    Text(tracking.snapshot.hasFace ? "얼굴 감지됨" : "얼굴을 화면 중앙에 맞춰 주세요")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                }

                Button {
                    onRequestARSessionReset()
                    tracking.requestRecalibrateHeadNeutralAfterARReset()
                } label: {
                    Text("기준 자세 저장")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Rectangle().fill(Color.cyan.opacity(0.95)))
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                        .foregroundStyle(.black)
                }

                Text("좌우(고개) 반응 테스트")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                Text("고개를 위·아래로가 아니라 왼쪽·오른쪽으로 돌려 보세요. 막대는 저장한 정면을 중앙으로 두고, 왼쪽으로 돌리면 ‘뒤’, 오른쪽으로 돌리면 ‘앞’ 방향으로 반응합니다. (게임 캐릭터도 같은 요 입력을 씁니다.)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                yawTurnGauge
            } else {
                Text("이 기기(또는 시뮬레이터)에서는 AR 얼굴 추적을 쓸 수 없습니다. 게임은 화면 하단 시뮬 조작으로 플레이됩니다.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Rectangle().fill(Color.white.opacity(0.12)))
        .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 2))
        .padding(.horizontal, 16)
    }

    private var yawTurnGauge: some View {
        let cap = GameParameters.settingsYawGaugeMaxRadians
        let relativeYaw = tracking.snapshot.headYawRadians - tracking.neutralYawBaselineRadians
        let t = max(-1, min(1, relativeYaw / cap))

        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let half = w * 0.5
                let fillW = half * CGFloat(abs(t))
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(tracking.snapshot.hasFace ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    if tracking.snapshot.hasFace {
                        if t >= 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.mint.opacity(0.9))
                                .frame(width: max(2, fillW), height: h)
                                .offset(x: half)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.mint.opacity(0.9))
                                .frame(width: max(2, fillW), height: h)
                                .offset(x: half - fillW)
                        }
                    }
                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 2, height: h * 0.92)
                        .offset(x: half - 1)
                }
            }
            .frame(height: 24)

            HStack {
                Text("왼쪽 · 뒤")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("오른쪽 · 앞")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }
}
