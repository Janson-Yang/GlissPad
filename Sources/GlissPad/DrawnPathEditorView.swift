import AppKit
import GlissPadCore

@MainActor
final class DrawnPathEditorView: NSControl {
    var points: [NormalizedPoint] = CustomPathGestureRule.defaultDrawnPathPoints {
        didSet { needsDisplay = true }
    }
    var onPointsChanged: (([NormalizedPoint]) -> Void)?
    var onPointsCommitted: (([NormalizedPoint]) -> Void)?

    private var isDrawing = false
    private var pointsBeforeDrawing: [NormalizedPoint] = []

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        let preferredWidth = widthAnchor.constraint(equalToConstant: 340)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        heightAnchor.constraint(equalToConstant: 220).isActive = true
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
        drawEndpoint(points.first, color: .systemGreen, label: "S")
        drawEndpoint(points.last, color: .systemRed, label: "E")
    }

    override func mouseDown(with event: NSEvent) {
        isDrawing = true
        pointsBeforeDrawing = points
        points = [normalizedPoint(for: convert(event.locationInWindow, from: nil))]
        onPointsChanged?(points)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDrawing else { return }
        appendPoint(normalizedPoint(for: convert(event.locationInWindow, from: nil)))
    }

    override func mouseUp(with event: NSEvent) {
        guard isDrawing else { return }
        isDrawing = false
        appendPoint(normalizedPoint(for: convert(event.locationInWindow, from: nil)))
        let committed = simplified(points)
        guard committed.count >= 2 else {
            points = pointsBeforeDrawing
            return
        }
        onPointsCommitted?(committed)
    }

    private func appendPoint(_ point: NormalizedPoint) {
        guard points.last.map({ distance($0, point) }) ?? .infinity >= 0.008 else { return }
        points.append(point)
        onPointsChanged?(points)
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
        path.lineWidth = 2.5
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.stroke()
    }

    private func drawEndpoint(_ point: NormalizedPoint?, color: NSColor, label: String) {
        guard let point else { return }
        let center = viewPoint(for: point)
        let rect = NSRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)
        let path = NSBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1.1
        path.stroke()
        drawLabel(label, in: rect)
    }

    private func drawLabel(_ label: String, in rect: NSRect) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: style
        ]
        label.draw(in: rect.insetBy(dx: 0, dy: 4), withAttributes: attributes)
    }

    private func simplified(_ source: [NormalizedPoint]) -> [NormalizedPoint] {
        guard source.count > 120 else { return source }
        let step = Double(source.count - 1) / 119.0
        return (0..<120).map { source[min(Int((Double($0) * step).rounded()), source.count - 1)] }
    }

    private func normalizedPoint(for point: NSPoint) -> NormalizedPoint {
        let rect = trackpadRect
        let x = clamp(Double((point.x - rect.minX) / rect.width), min: 0, max: 1)
        let y = clamp(Double((point.y - rect.minY) / rect.height), min: 0, max: 1)
        return NormalizedPoint(x: x, y: y)
    }

    private func viewPoint(for point: NormalizedPoint) -> NSPoint {
        let rect = trackpadRect
        return NSPoint(x: rect.minX + rect.width * CGFloat(point.x), y: rect.minY + rect.height * CGFloat(point.y))
    }

    private func distance(_ first: NormalizedPoint, _ second: NormalizedPoint) -> Double {
        let deltaX = first.x - second.x
        let deltaY = first.y - second.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }

    private var trackpadRect: NSRect {
        let insetBounds = bounds.insetBy(dx: 18, dy: 22)
        let width = min(insetBounds.width, insetBounds.height * 1.62)
        return NSRect(x: insetBounds.midX - width / 2, y: insetBounds.midY - width / 3.24, width: width, height: width / 1.62)
    }

    private var trackpadFill: NSColor {
        LiquidGlassStyle.isDarkMode(for: self)
            ? NSColor.black.withAlphaComponent(0.28)
            : NSColor.white.withAlphaComponent(0.72)
    }

    private var trackpadBorder: NSColor {
        LiquidGlassStyle.isDarkMode(for: self)
            ? NSColor.white.withAlphaComponent(0.22)
            : NSColor.black.withAlphaComponent(0.18)
    }
}
