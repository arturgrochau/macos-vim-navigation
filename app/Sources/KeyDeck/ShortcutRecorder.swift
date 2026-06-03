import SwiftUI
import AppKit
import KeyDeckCore

/// A click-to-record shortcut field — the standard macOS pattern. Click it, press a
/// shortcut, done. Esc cancels, Delete clears. Replaces the old modifier-checkbox row.
final class RecorderNSView: NSView {
    var binding = KeyBinding()
    var captureModifiers = true
    var onChange: ((KeyBinding) -> Void)?
    private var recording = false { didSet { needsDisplay = true } }

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { recording = true; return true }
    override func resignFirstResponder() -> Bool { recording = false; return true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        recording = true
    }

    override func keyDown(with event: NSEvent) {
        guard recording else { super.keyDown(with: event); return }
        let code = Int(event.keyCode)
        if code == 53 {                                   // escape → cancel
            stop(); return
        }
        if code == 51 || code == 117 {                    // delete → clear
            binding = KeyBinding(); onChange?(binding); stop(); return
        }
        if KeyNames.isModifierKeyCode(code) { return }    // ignore bare modifier presses
        guard let key = KeyNames.keyName(forKeyCode: code, characters: event.charactersIgnoringModifiers) else { return }
        var mods = KeyNames.modifierNames(rawFlags: event.modifierFlags.rawValue)
        if !captureModifiers { mods = mods.filter { $0 == "shift" } }
        binding = KeyBinding(mods: mods, key: key)
        onChange?(binding)
        stop()
    }

    private func stop() { recording = false; window?.makeFirstResponder(nil) }

    private var displayText: String {
        binding.key.isEmpty ? "" : Validation.display(mods: binding.mods, key: binding.key)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        (recording ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor).setFill()
        path.fill()
        (recording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = recording ? 2 : 1
        path.stroke()

        let label = recording ? "Press a shortcut…" : (displayText.isEmpty ? "Click to set" : displayText)
        let dimmed = recording || displayText.isEmpty
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: displayText.isEmpty ? .regular : .medium),
            .foregroundColor: dimmed ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]
        let s = (label as NSString).size(withAttributes: attrs)
        (label as NSString).draw(at: NSPoint(x: (bounds.width - s.width) / 2,
                                             y: (bounds.height - s.height) / 2), withAttributes: attrs)
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var binding: KeyBinding
    var captureModifiers = true

    func makeNSView(context: Context) -> RecorderNSView {
        let v = RecorderNSView()
        v.captureModifiers = captureModifiers
        v.binding = binding
        v.onChange = { binding = $0 }
        return v
    }

    func updateNSView(_ v: RecorderNSView, context: Context) {
        v.captureModifiers = captureModifiers
        v.onChange = { binding = $0 }
        if v.binding != binding { v.binding = binding; v.needsDisplay = true }
    }
}
