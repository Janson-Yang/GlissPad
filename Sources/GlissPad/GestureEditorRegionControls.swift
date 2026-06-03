import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makeRegionEditor(labelWidth: CGFloat? = nil) -> NSView {
        let label = NSTextField(labelWithString: "Trigger region")
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        if let labelWidth {
            label.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        }

        let regionStack = NSStackView(views: [regionSelectionView, makeRegionValueRow()])
        regionStack.orientation = .vertical
        regionStack.alignment = .leading
        regionStack.spacing = 8
        let stack = NSStackView(views: [label, regionStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return stack
    }

    func configureRegionSelection() {
        regionSelectionView.onRegionChanged = { [weak self] region in
            self?.updateRegionFields(region)
        }
        regionSelectionView.onRegionCommitted = { [weak self] _ in
            guard let self else { return }
            configurationControlChanged(regionSelectionView)
        }
    }

    func updateRegionFromSelectedCorner() {
        guard let title = cornerPresetPopup.selectedItem?.title,
              let corner = TrackpadCorner.allCases.first(where: { $0.displayName == title }),
              corner != .custom else { return }
        updateRegionFields(corner.defaultRegion)
        regionSelectionView.region = corner.defaultRegion
    }

    private func makeRegionValueRow() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8

        zip(["x1", "x2", "y1", "y2"], regionValueFields).forEach { label, field in
            let labelView = NSTextField(labelWithString: label)
            labelView.textColor = .tertiaryLabelColor
            labelView.font = .systemFont(ofSize: 11, weight: .medium)
            stack.addArrangedSubview(labelView)
            stack.addArrangedSubview(field)
        }
        return stack
    }

    private var regionValueFields: [NSTextField] {
        [regionFields.minX, regionFields.maxX, regionFields.minY, regionFields.maxY]
    }
}
