import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makeSwipeRegionEditors(labelWidth: CGFloat? = nil) -> NSView {
        let start = makeSwipeRegionEditor(
            title: "Start region",
            view: swipeStartRegionView,
            fields: swipeStartRegionFields
        )
        let end = makeSwipeRegionEditor(
            title: "End region",
            view: swipeEndRegionView,
            fields: swipeEndRegionFields
        )
        let stack = NSStackView(views: [start, end])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        if let labelWidth {
            stack.widthAnchor.constraint(greaterThanOrEqualToConstant: labelWidth).isActive = true
        }
        return stack
    }

    func configureSwipeRegionSelection() {
        swipeStartRegionView.onRegionChanged = { [weak self] region in
            self?.updateSwipeStartRegionFields(region)
        }
        swipeStartRegionView.onRegionCommitted = { [weak self] _ in
            guard let self else { return }
            configurationControlChanged(swipeStartRegionView)
        }
        swipeEndRegionView.onRegionChanged = { [weak self] region in
            self?.updateSwipeEndRegionFields(region)
        }
        swipeEndRegionView.onRegionCommitted = { [weak self] _ in
            guard let self else { return }
            configurationControlChanged(swipeEndRegionView)
        }
    }

    func loadSwipeRegions(start: NormalizedRegion?, end: NormalizedRegion?) {
        let start = start ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
        let end = end ?? NormalizedRegion(minX: 0, maxX: 1, minY: 0, maxY: 1)
        updateSwipeStartRegionFields(start)
        updateSwipeEndRegionFields(end)
        swipeStartRegionView.region = start
        swipeEndRegionView.region = end
    }

    func visibleSwipeStartRegion() throws -> NormalizedRegion {
        try visibleSwipeRegion(fields: swipeStartRegionFields, name: "start region")
    }

    func visibleSwipeEndRegion() throws -> NormalizedRegion {
        try visibleSwipeRegion(fields: swipeEndRegionFields, name: "end region")
    }

    func selectedMultiFingerSwipePreset() throws -> MultiFingerSwipePathPreset {
        guard let title = multiFingerSwipePresetPopup.selectedItem?.title,
              let preset = MultiFingerSwipePathPreset.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("swipe path preset")
        }
        return preset
    }

    func syncPathPointsToSelectedSwipePreset() {
        guard let preset = try? selectedMultiFingerSwipePreset(), preset != .custom else { return }
        rebuildPathPointRows(preset.defaultPoints)
    }

    private func makeSwipeRegionEditor(
        title: String,
        view: RegionSelectionView,
        fields: (minX: NSTextField, maxX: NSTextField, minY: NSTextField, maxY: NSTextField)
    ) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [label, view, makeSwipeRegionValueRow(fields)])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        return stack
    }

    private func makeSwipeRegionValueRow(
        _ fields: (minX: NSTextField, maxX: NSTextField, minY: NSTextField, maxY: NSTextField)
    ) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        zip(["x1", "x2", "y1", "y2"], [fields.minX, fields.maxX, fields.minY, fields.maxY]).forEach {
            stack.addArrangedSubview(regionLabel($0.0))
            stack.addArrangedSubview($0.1)
        }
        return stack
    }

    private func regionLabel(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.textColor = .tertiaryLabelColor
        label.font = .systemFont(ofSize: 11, weight: .medium)
        return label
    }

    private func updateSwipeStartRegionFields(_ region: NormalizedRegion) {
        updateSwipeRegionFields(swipeStartRegionFields, region: region)
    }

    private func updateSwipeEndRegionFields(_ region: NormalizedRegion) {
        updateSwipeRegionFields(swipeEndRegionFields, region: region)
    }

    private func updateSwipeRegionFields(
        _ fields: (minX: NSTextField, maxX: NSTextField, minY: NSTextField, maxY: NSTextField),
        region: NormalizedRegion
    ) {
        fields.minX.stringValue = regionCoordinate(region.minX)
        fields.maxX.stringValue = regionCoordinate(region.maxX)
        fields.minY.stringValue = regionCoordinate(region.minY)
        fields.maxY.stringValue = regionCoordinate(region.maxY)
    }

    private func visibleSwipeRegion(
        fields: (minX: NSTextField, maxX: NSTextField, minY: NSTextField, maxY: NSTextField),
        name: String
    ) throws -> NormalizedRegion {
        NormalizedRegion(
            minX: try doubleValue(fields.minX, name: "\(name) minX"),
            maxX: try doubleValue(fields.maxX, name: "\(name) maxX"),
            minY: try doubleValue(fields.minY, name: "\(name) minY"),
            maxY: try doubleValue(fields.maxY, name: "\(name) maxY")
        )
    }

    private func regionCoordinate(_ value: Double) -> String {
        String(format: "%.3g", value)
    }
}
