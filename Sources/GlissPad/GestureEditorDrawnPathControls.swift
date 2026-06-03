import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makeDrawnPathEditor(labelWidth: CGFloat? = nil) -> NSView {
        let label = NSTextField(labelWithString: "Draw path")
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        if let labelWidth {
            label.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        }
        let hint = NSTextField(labelWithString: "Press and drag inside the trackpad to redraw the gesture.")
        hint.font = .systemFont(ofSize: 11, weight: .regular)
        hint.textColor = .tertiaryLabelColor
        hint.lineBreakMode = .byWordWrapping
        hint.maximumNumberOfLines = 2
        let stack = NSStackView(views: [label, drawnPathEditorView, hint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        return stack
    }

    func configureDrawnPathEditor() {
        drawnPathEditorView.onPointsChanged = { [weak self] points in
            self?.statusLabel.stringValue = "Drawing path with \(points.count) points."
        }
        drawnPathEditorView.onPointsCommitted = { [weak self] points in
            guard let self else { return }
            drawnPathEditorView.points = points
            configurationControlChanged(drawnPathEditorView)
        }
    }

    func visibleCustomPathPoints() throws -> [NormalizedPoint] {
        guard selectedSlot.trigger(in: configuration)?.type == .oneFingerDrawnPath else {
            return try visiblePathPoints()
        }
        return drawnPathEditorView.points
    }
}
