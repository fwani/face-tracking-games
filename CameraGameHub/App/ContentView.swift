import SwiftUI

private enum AppShell {
    case hub
    case game(HubGame)
}

struct ContentView: View {
    @State private var shell: AppShell = .hub

    var body: some View {
        Group {
            switch shell {
            case .hub:
                CameraGameHubView { game in
                    shell = .game(game)
                }
            case .game(let game):
                switch game {
                case .faceFly:
                    FaceFlyRootView {
                        shell = .hub
                    }
                case .obstacleDodge:
                    ObstacleDodgeRootView {
                        shell = .hub
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
