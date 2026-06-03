import AppKit
import GlissPadCore

@MainActor
final class PathEditorView: NSControl {
    var points: [NormalizedPoint] = CustomPathGestureRule.defaultPoints {
        didSet { needsDisplay = true }
    }
    var onPointsChanged: (([NormalizedPoint]) -> Void)?
    var onPointsCommitted: (([NormalizedPoint]) -> Void)?

    private var draggedPointIndex: Int?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        let preferredWidth = widthAnchor.constraint(equalToConstant: 320)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        heightAnchor.constraint(equalToConstant: 180).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        drawTrackpad()
        drawPath()
        points.enumerated().forEach { drawHandle(index: $0.offset, point: $0.element) }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        draggedPointIndex = nearestPointIndex(to: point)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let index = draggedPointIndex, points.indices.contains(index) else { return }
        let point = convert(event.locationInWindow, from: nil)
        points[index] = normalizedPoint(for: point)
        onPointsChanged?(points)
    }

    override func mouseUp(with event: NSEvent) {
        guard draggedPointIndex != nil else { return }
        draggedPointIndex = nil
        onPointsCommitted?(points)
    }

    private func drawTrackpad() {
        let path = NSBezierPath(roundedRect: trackpadRect, xRadius: 16, yRadius: 16)
        trackpadFill.setFill()
        path.fill()
        trackpadBorder.setStroke()
        path.lineWidth = 1.2
        path.stroke()
    }

    private func drawPath() {
        guard let first = points.first else { return }
        let path = NSBezierPath()
        path.move(to: viewPoint(for: first))
        points.dropFirst().forEach { path.line(to: viewPoint(for: $0)) }
        NSColor.controlAccentColor.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func drawHandle(index: Int, point: NormalizedPoint) {
        let center = viewPoint(for: point)
        let size: CGFloat = 20
        let rect = NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
        let path = NSBezierPath(ovalIn: rect)
        NSColor.controlAccentColor.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1.2
        path.stroke()
        drawIndex(index + 1, in: rect)
    }

    private func drawIndex(_ index: Int, in rect: NSRect) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style
        ]
        let textRect = rect.insetBy(dx: 0, dy: 3)
        "\(index)".draw(in: textRect, withAttributes: attributes)
    }

    private func nearestPointIndex(to point: NSPoint) -> Int? {
        let candidates = points.enumerated().map { ($0.offset, viewPoint(for: $0.element)) }
        return candidates.first(where: { $0.1.distance(to: point) <= 18 })?.0
    }

    private func normalizedPoint(for point: NSPoint) -> NormalizedPoint {
        let rect = trackpadRect
        let x = clamp(Double((point.x - rect.minX) / rect.width), min: 0, max: 1)
        let y = clamp(Double((point.y - rect.minY) / rect.height), min: 0, max: 1)
        return NormalizedPoint(x: x, y: y)
    }

    private func viewPoint(for point: NormalizedPoint) -> NSPoint {
        let rect = trackpadRect
        return NSPoint(
            x: rect.minX + rect.width * CGFloat(point.x),
            y: rect.minY + rect.height * CGFloat(point.y)
        )
    }

    private var trackpadRect: NSRect {
        let insetBounds = bounds.insetBy(dx: 18, dy: 18)
        let aspect: CGFloat = 1.62
        let width = min(insetBounds.width, insetBounds.height * aspect)
        let height = width / aspect
        return NSRect(x: insetBounds.midX - width / 2, y: insetBounds.midY - height / 2, width: width, height: height)
    }

    private var isDark: Bool {
        LiquidGlassStyle.isDarkMode(for: self)
    }

    private var trackpadFill: NSColor {
        isDark ? NSColor.black.withAlphaComponent(0.28) : NSColor.white.withAlphaComponent(0.72)
    }

    private var trackpadBorder: NSColor {
        isDark ? NSColor.white.withAlphaComponent(0.22) : NSColor.black.withAlphaComponent(0.18)
    }
}
