import SwiftUI

@main
struct KeyDeckApp: App {
    var body: some Scene {
        WindowGroup("KeyDeck") {
            ContentView()
                .frame(minWidth: 560, minHeight: 560)
        }
        .windowResizability(.contentSize)
    }
}
