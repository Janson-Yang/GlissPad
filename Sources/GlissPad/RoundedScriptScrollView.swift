import AppKit

@MainActor
final class RoundedScriptScrollView: NSScrollView {
    init() {
        super.init(frame: .zero)
        borderType = .noBorder
        drawsBackground = true
        hasVerticalScroller = true
        hasHorizontalScroller = true
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        layer?.borderWidth = 1.5
        contentView.drawsBackground = true
        applyAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAppearance()
    }

    private func applyAppearance() {
        let background = isDarkMode
            ? NSColor.black.withAlphaComponent(0.82)
            : NSColor.white.withAlphaComponent(0.96)
        backgroundColor = background
        contentView.backgroundColor = background
        layer?.backgroundColor = background.cgColor
        layer?.borderColor = borderColor.cgColor
    }

    private var isDarkMode: Bool {
        effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private var borderColor: NSColor {
        isDarkMode
            ? NSColor.white.withAlphaComponent(0.24)
            : NSColor.black.withAlphaComponent(0.16)
    }
}
