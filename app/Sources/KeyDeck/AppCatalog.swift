import AppKit

/// One installed application discovered on disk.
struct InstalledApp: Identifiable, Hashable {
    let id: String      // bundle identifier
    let name: String
    let path: String

    var icon: NSImage { NSWorkspace.shared.icon(forFile: path) }

    static func == (l: InstalledApp, r: InstalledApp) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Scans the standard application folders so users pick from a list instead of
/// typing bundle identifiers.
enum AppCatalog {
    static func installed() -> [InstalledApp] {
        let home = NSHomeDirectory()
        let dirs = [
            "/Applications", "/Applications/Utilities",
            "/System/Applications", "/System/Applications/Utilities",
            home + "/Applications",
        ]
        let fm = FileManager.default
        var seen = Set<String>()
        var out: [InstalledApp] = []
        for dir in dirs {
            guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let path = dir + "/" + item
                guard let bundle = Bundle(path: path), let id = bundle.bundleIdentifier else { continue }
                if seen.contains(id) { continue }
                seen.insert(id)
                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? (item as NSString).deletingPathExtension
                out.append(InstalledApp(id: id, name: name, path: path))
            }
        }
        return out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
