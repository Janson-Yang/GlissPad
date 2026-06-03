import AppKit
import GlissPadCore

@MainActor
final class RegionSelectionView: NSControl {
    var region = NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1) {
        didSet { needsDisplay = true }
    }
    var onRegionChanged: ((NormalizedRegion) -> Void)?
    var onRegionCommitted: ((NormalizedRegion) -> Void)?

    private var dragState: DragState?
    private let minimumSize = 0.04

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        let preferredWidth = widthAnchor.constraint(equalToConstant: 320)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        heightAnchor.constraint(equalToConstant: 156).isActive = true
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
        drawSelection()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragState = DragState(target: hitTarget(at: point), startPoint: point, startRegion: region)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragState else { return }
        let point = convert(event.locationInWindow, from: nil)
        region = updatedRegion(for: dragState, currentPoint: point)
        onRegionChanged?(region)
    }

    override func mouseUp(with event: NSEvent) {
        guard dragState != nil else { return }
        dragState = nil
        onRegionCommitted?(region)
    }

    private func drawTrackpad() {
        let path = NSBezierPath(roundedRect: trackpadRect, xRadius: 16, yRadius: 16)
        trackpadFill.setFill()
        path.fill()
        trackpadBorder.setStroke()
        path.lineWidth = 1.2
        path.stroke()
    }

    private func drawSelection() {
        let selectionPath = NSBezierPath(roundedRect: selectionRect, xRadius: 9, yRadius: 9)
        NSColor.controlAccentColor.withAlphaComponent(isDark ? 0.34 : 0.24).setFill()
        selectionPath.fill()
        NSColor.controlAccentColor.withAlphaComponent(0.9).setStroke()
        selectionPath.lineWidth = 2
        selectionPath.stroke()
        handlePoints.forEach(drawHandle(at:))
    }

    private func drawHandle(at point: NSPoint) {
        let size: CGFloat = 10
        let rect = NSRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        let path = NSBezierPath(ovalIn: rect)
        NSColor.controlAccentColor.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1.4
        path.stroke()
    }

    private func hitTarget(at point: NSPoint) -> DragTarget {
        let handles = Corner.allCases.map { ($0, handlePoint(for: $0)) }
        if let corner = handles.first(where: { $0.1.distance(to: point) <= 16 })?.0 {
            return .corner(corner)
        }
        return selectionRect.contains(point) ? .body : .none
    }

    private func updatedRegion(for drag: DragState, currentPoint: NSPoint) -> NormalizedRegion {
        switch drag.target {
        case .none:
            return drag.startRegion
        case .body:
            return translatedRegion(from: drag, currentPoint: currentPoint)
        case .corner(let corner):
            return resizedRegion(from: drag.startRegion, corner: corner, point: currentPoint)
        }
    }

    private func translatedRegion(from drag: DragState, currentPoint: NSPoint) -> NormalizedRegion {
        let start = normalizedPoint(for: drag.startPoint)
        let current = normalizedPoint(for: currentPoint)
        let width = drag.startRegion.maxX - drag.startRegion.minX
        let height = drag.startRegion.maxY - drag.startRegion.minY
        let minX = clamp(drag.startRegion.minX + current.x - start.x, min: 0, max: 1 - width)
        let minY = clamp(drag.startRegion.minY + current.y - start.y, min: 0, max: 1 - height)
        return NormalizedRegion(minX: minX, maxX: minX + width, minY: minY, maxY: minY + height)
    }

    private func resizedRegion(from start: NormalizedRegion, corner: Corner, point: NSPoint) -> NormalizedRegion {
        let point = normalizedPoint(for: point)
        var region = start
        switch corner {
        case .minXMinY:
            region.minX = clamp(point.x, min: 0, max: start.maxX - minimumSize)
            region.minY = clamp(point.y, min: 0, max: start.maxY - minimumSize)
        case .maxXMinY:
            region.maxX = clamp(point.x, min: start.minX + minimumSize, max: 1)
            region.minY = clamp(point.y, min: 0, max: start.maxY - minimumSize)
        case .minXMaxY:
            region.minX = clamp(point.x, min: 0, max: start.maxX - minimumSize)
            region.maxY = clamp(point.y, min: start.minY + minimumSize, max: 1)
        case .maxXMaxY:
            region.maxX = clamp(point.x, min: start.minX + minimumSize, max: 1)
            region.maxY = clamp(point.y, min: start.minY + minimumSize, max: 1)
        }
        return region
    }

    private func normalizedPoint(for point: NSPoint) -> RegionPoint {
        let rect = trackpadRect
        let x = clamp(Double((point.x - rect.minX) / rect.width), min: 0, max: 1)
        let y = clamp(Double((point.y - rect.minY) / rect.height), min: 0, max: 1)
        return RegionPoint(x: x, y: y)
    }

    private var trackpadRect: NSRect {
        let insetBounds = bounds.insetBy(dx: 18, dy: 18)
        let aspect: CGFloat = 1.62
        let width = min(insetBounds.width, insetBounds.height * aspect)
        let height = width / aspect
        return NSRect(
            x: insetBounds.midX - width / 2,
            y: insetBounds.midY - height / 2,
            width: width,
            height: height
        )
    }

    private var selectionRect: NSRect {
        let rect = trackpadRect
        return NSRect(
            x: rect.minX + rect.width * region.minX,
            y: rect.minY + rect.height * region.minY,
            width: rect.width * (region.maxX - region.minX),
            height: rect.height * (region.maxY - region.minY)
        )
    }

    private var handlePoints: [NSPoint] {
        Corner.allCases.map(handlePoint(for:))
    }

    private func handlePoint(for corner: Corner) -> NSPoint {
        let rect = selectionRect
        switch corner {
        case .minXMinY: return NSPoint(x: rect.minX, y: rect.minY)
        case .maxXMinY: return NSPoint(x: rect.maxX, y: rect.minY)
        case .minXMaxY: return NSPoint(x: rect.minX, y: rect.maxY)
        case .maxXMaxY: return NSPoint(x: rect.maxX, y: rect.maxY)
        }
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
