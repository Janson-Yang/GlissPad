import AppKit

enum ActionExecutionState: Equatable {
    case idle
    case running
    case succeeded
    case failed
}

@MainActor
class GlassListItemButton: NSButton {
    var itemTitle: String { didSet { title = itemTitle; needsDisplay = true } }
    var itemSubtitle: String? { didSet { needsDisplay = true } }
    var symbolName: String? { didSet { needsDisplay = true } }
    var accessorySymbolName: String? { didSet { needsDisplay = true } }
    var isSelectedItem = false { didSet { needsDisplay = true } }
    var executionState: ActionExecutionState = .idle { didSet { needsDisplay = true } }

    init(
        title: String,
        subtitle: String? = nil,
        symbolName: String?,
        accessorySymbolName: String? = nil,
        target: AnyObject?,
        action: Selector?
    ) {
        itemTitle = title
        itemSubtitle = subtitle
        self.symbolName = symbolName
        self.accessorySymbolName = accessorySymbolName
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        drawBackground()
        drawSymbol()
        drawAccessorySymbol()
        drawText()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    private func drawBackground() {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11)
        backgroundColor.setFill()
        path.fill()
        borderColor.setStroke()
        path.lineWidth = isSelectedItem ? 1.25 : 1
        path.stroke()
    }

    private func drawSymbol() {
        guard let symbolName,
              let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return
        }
        let rect = NSRect(x: 18, y: bounds.midY - 8, width: 16, height: 16)
        image.draw(in: rect)
    }

    private func drawAccessorySymbol() {
        guard let accessorySymbolName,
              let image = NSImage(systemSymbolName: accessorySymbolName, accessibilityDescription: nil) else {
            return
        }
        let rect = NSRect(x: bounds.maxX - 34, y: bounds.midY - 8, width: 16, height: 16)
        image.draw(in: rect)
    }

    private func drawText() {
        let x: CGFloat = 48
        let accessoryWidth: CGFloat = accessorySymbolName == nil ? 28 : 52
        let width = max(0, bounds.width - x - accessoryWidth)
        if let itemSubtitle, !itemSubtitle.isEmpty {
            draw(itemTitle, in: NSRect(x: x, y: bounds.midY - 15, width: width, height: 16), weight: .semibold)
            draw(itemSubtitle, in: NSRect(x: x, y: bounds.midY + 1, width: width, height: 14), weight: .regular)
            return
        }
        draw(itemTitle, in: NSRect(x: x, y: bounds.midY - 9, width: width, height: 18), weight: .medium)
    }

    private func draw(_ textValue: String, in rect: NSRect, weight: NSFont.Weight) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: weight == .regular ? 11 : 13, weight: weight),
            .foregroundColor: textColor(for: weight),
            .paragraphStyle: paragraph
        ]
        let text = NSAttributedString(string: textValue, attributes: attributes)
        text.draw(with: rect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    }

    private func textColor(for weight: NSFont.Weight) -> NSColor {
        guard weight != .regular else { return .tertiaryLabelColor }
        return isSelectedItem ? .labelColor : .secondaryLabelColor
    }

    private var backgroundColor: NSColor {
        LiquidGlassStyle.listItemFill(for: self, selected: isSelectedItem, highlighted: isHighlighted)
    }

    private var borderColor: NSColor {
        LiquidGlassStyle.listItemBorder(for: self, selected: isSelectedItem)
    }

}
