import SwiftUI

/// [docs/flappy-horse-design-guide.md] §2·§6·§8 — 뷰/코드 레이어용 색상·레이아웃 (SVG 내부 색은 에셋에 유지).
enum FlappyHorseTheme {
    static let skyTop = Color(red: 0.788, green: 0.875, blue: 0.949) // #C9DFF2
    static let skyBottom = Color(red: 0.961, green: 0.851, blue: 0.722) // #F5D9B8
    static let mountain = Color(red: 0.663, green: 0.439, blue: 0.251) // #A97040
    static let midField = Color(red: 0.769, green: 0.573, blue: 0.227) // #C4923A
    static let hudCream = Color(red: 0.992, green: 0.945, blue: 0.894) // #FDF1E4
    static let hudShadow = Color(red: 0.420, green: 0.243, blue: 0.149) // #6B3E26
    static let goldenButton = Color(red: 0.910, green: 0.627, blue: 0.125) // #E8A020
    static let buttonText = Color(red: 0.227, green: 0.102, blue: 0.039) // #3A1A0A
    static let gameOverPanel = Color(red: 0.545, green: 0.369, blue: 0.235) // #8B5E3C
    static let goldenButtonPressed = Color(red: 0.753, green: 0.439, blue: 0.063) // #C07010
    static let boostFlame = Color(red: 0.753, green: 0.439, blue: 0.063)

    /// 지면 밴드 높이 (화면 비율). 가이드 15~20% 중앙값.
    static let groundBandHeightNorm: CGFloat = 0.175
    static let groundCollisionEpsilon: CGFloat = 0.012

    static let scoreFontSize: CGFloat = 36
    static let levelFontSize: CGFloat = 18
}
