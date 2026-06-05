import AppKit

@MainActor
enum IconCatalog {
    private static var resourceCache: [String: NSImage] = [:]

    static func image(named name: String?) -> NSImage? {
        guard let name else { return nil }
        if let cached = resourceCache[name] { return cached }
        if let image = resourceImage(named: name) {
            resourceCache[name] = image
            return image
        }
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    static func drawTemplate(_ image: NSImage, in rect: NSRect, color: NSColor) {
        let tinted = NSImage(size: rect.size)
        tinted.lockFocus()
        let drawRect = NSRect(origin: .zero, size: rect.size)
        color.setFill()
        drawRect.fill()
        image.draw(in: drawRect, from: .zero, operation: .destinationIn, fraction: 1)
        tinted.unlockFocus()
        tinted.draw(in: rect)
    }

    private static func resourceImage(named name: String) -> NSImage? {
        guard let url = resourceURL(named: name),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = true
        return image
    }

    private static func resourceURL(named name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Icons")
            ?? Bundle.module.url(forResource: "Icons/\(name)", withExtension: "svg")
            ?? Bundle.module.url(forResource: name, withExtension: "svg")
    }
}
