import AppKit

@MainActor
final class ActionStatusBadgeView: NSView {
    var state: ActionExecutionState = .idle {
        didSet {
            isHidden = state == .idle
            needsDisplay = true
        }
    }

    init() {
        super.init(frame: .zero)
        isHidden = true
        wantsLayer = true
        layer?.zPosition = 1
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        switch state {
        case .idle:
            return
        case .running:
            drawRunning()
        case .succeeded:
            drawSuccess()
        case .failed:
            drawFailure()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func drawRunning() {
        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(ovalIn: bounds.insetBy(dx: 3, dy: 3))
        path.lineWidth = 2
        path.stroke()
    }

    private func drawSuccess() {
        NSColor.systemGreen.setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 2, dy: 2)).fill()
        NSColor.white.setStroke()
        let check = NSBezierPath()
        check.move(to: NSPoint(x: 6, y: 10))
        check.line(to: NSPoint(x: 9, y: 7))
        check.line(to: NSPoint(x: 15, y: 14))
        check.lineWidth = 2
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        check.stroke()
    }

    private func drawFailure() {
        guard let image = LiquidGlassStyle.symbol("xmark.circle.fill") else { return }
        NSColor.systemRed.set()
        image.draw(in: bounds.insetBy(dx: 2, dy: 2))
    }
}
