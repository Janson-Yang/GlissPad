import AppKit

@MainActor
final class RotationGestureHintView: NSView {
    enum Direction {
        case left
        case right
    }

    private let direction: Direction
    private let animationStep: CGFloat = 0.01
    private let travelPhaseLimit: CGFloat = 0.78
    private let trailPhaseSpan: CGFloat = 0.28
    private let trailSampleCount = 14
    private var timer: Timer?
    private var phase: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    init(direction: Direction) {
        self.direction = direction
        super.init(frame: .zero)
        wantsLayer = true
        heightAnchor.constraint(equalToConstant: 118).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 260, height: 118)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window == nil ? stopAnimation() : startAnimation()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let trackpad = bounds.insetBy(dx: 22, dy: 14)
        drawTrackpad(trackpad)
        drawMotion(in: trackpad)
    }

    private func startAnimation() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.advanceAnimation() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    private func advanceAnimation() {
        phase = phase >= 1 ? 0 : min(1, phase + animationStep)
    }

    private func drawTrackpad(_ rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14)
        NSColor.controlBackgroundColor.withAlphaComponent(0.58).setFill()
        path.fill()
        NSColor.separatorColor.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func drawMotion(in rect: NSRect) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.25
        drawFingerTrail(index: 0, center: center, radius: radius)
        drawFingerTrail(index: 1, center: center, radius: radius)
        drawFingerPair(fingerPair(center: center, radius: radius, phase: phase))
    }

    private func drawFingerTrail(index: Int, center: NSPoint, radius: CGFloat) {
        let startPhase = max(0, phase - trailPhaseSpan)
        let path = NSBezierPath()
        for sample in 0...trailSampleCount {
            let progress = CGFloat(sample) / CGFloat(trailSampleCount)
            let samplePhase = startPhase + (phase - startPhase) * progress
            let point = pointForFinger(index: index, center: center, radius: radius, phase: samplePhase)
            sample == 0 ? path.move(to: point) : path.line(to: point)
        }
        NSColor.controlAccentColor.withAlphaComponent(0.62).setStroke()
        path.lineWidth = 5
        path.lineCapStyle = .round
        path.stroke()
    }

    private func fingerPair(center: NSPoint, radius: CGFloat, phase: CGFloat) -> (NSPoint, NSPoint) {
        let progress = min(phase / travelPhaseLimit, 1)
        let eased = 0.5 - cos(progress * .pi) / 2
        let sweep: CGFloat = direction == .left ? 82 : -82
        let angle = (-sweep / 2 + sweep * eased) * .pi / 180
        let vector = NSPoint(x: cos(angle) * radius, y: sin(angle) * radius)
        return (
            NSPoint(x: center.x - vector.x, y: center.y - vector.y),
            NSPoint(x: center.x + vector.x, y: center.y + vector.y)
        )
    }

    private func pointForFinger(index: Int, center: NSPoint, radius: CGFloat, phase: CGFloat) -> NSPoint {
        let pair = fingerPair(center: center, radius: radius, phase: phase)
        return index == 0 ? pair.0 : pair.1
    }

    private func drawFingerPair(_ pair: (NSPoint, NSPoint)) {
        drawFinger(at: pair.0)
        drawFinger(at: pair.1)
    }

    private func drawFinger(at point: NSPoint) {
        let rect = NSRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
        let path = NSBezierPath(ovalIn: rect)
        NSColor.controlAccentColor.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.82).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}
