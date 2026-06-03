import SwiftUI

@main
struct KeyDeckApp: App {
    var body: some Scene {
        WindowGroup("KeyDeck") {
            RootView()
        }
        .windowResizability(.contentSize)
    }
}
