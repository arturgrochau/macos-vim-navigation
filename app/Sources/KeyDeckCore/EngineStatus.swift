import Foundation

/// Heartbeat the engine writes on every load. The app reads it to confirm a reload
/// actually happened (Apply verification) and to detect whether the engine is active.
public struct EngineStatus: Codable, Equatable {
    public var loadedAt: Double   // epoch seconds (os.time())
    public var preset: String
    public var navEnabled: Bool

    public init(loadedAt: Double, preset: String, navEnabled: Bool) {
        self.loadedAt = loadedAt; self.preset = preset; self.navEnabled = navEnabled
    }

    public static var path: String {
        (NSHomeDirectory() as NSString)
            .appendingPathComponent("Library/Application Support/KeyDeck/engine-status.json")
    }

    public static func read() -> EngineStatus? {
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return try? JSONDecoder().decode(EngineStatus.self, from: data)
    }
}
