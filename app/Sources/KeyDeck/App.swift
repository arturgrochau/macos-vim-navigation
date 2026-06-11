import SwiftUI

@main
struct KeyDeckApp: App {
    var body: some Scene {
        WindowGroup("KeyDeck") {
            MainView()
        }
        .windowResizability(.contentSize)
    }
}
