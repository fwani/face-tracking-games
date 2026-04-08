import Foundation

/// 허브에서 선택 가능한 게임. 새 미니게임은 여기에 케이스를 추가하고 `ContentView`에서 루트 뷰를 연결한다.
enum HubGame: String, CaseIterable, Identifiable {
    case faceFly
    case obstacleDodge

    var id: String { rawValue }
}
