import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func makePathEditor(labelWidth: CGFloat? = nil) -> NSView {
        let label = NSTextField(labelWithString: "Path points")
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        if let labelWidth {
            label.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        }
        configurePathPointStack()
        let stack = NSStackView(views: [label, pathEditorView, pathPointListStack, pathButtonRow()])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        return stack
    }

    func configurePathEditor() {
        pathEditorView.onPointsChanged = { [weak self] points in
            self?.updatePathPointFields(points)
        }
        pathEditorView.onPointsCommitted = { [weak self] _ in
            guard let self else { return }
            configurationControlChanged(pathEditorView)
        }
    }

    func rebuildPathPointRows(_ points: [NormalizedPoint]) {
        pathPointFields.removeAll()
        pathPointListStack.arrangedSubviews.forEach {
            pathPointListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        points.enumerated().forEach { index, point in
            pathPointListStack.addArrangedSubview(pathPointRow(index: index, point: point))
        }
        pathEditorView.points = points
    }

    func visiblePathPoints() throws -> [NormalizedPoint] {
        try pathPointFields.map { fields in
            NormalizedPoint(
                x: try doubleValue(fields.x, name: "path point x"),
                y: try doubleValue(fields.y, name: "path point y")
            )
        }
    }

    @objc func addPathPoint() {
        guard !isLoadingSelection else { return }
        let points = (try? visiblePathPoints()) ?? pathEditorView.points
        guard points.count < 12 else { return }
        let newPoint = nextPathPoint(after: points.last)
        rebuildPathPointRows(points + [newPoint])
        configurationControlChanged(pathEditorView)
    }

    @objc func removePathPoint() {
        guard !isLoadingSelection else { return }
        var points = (try? visiblePathPoints()) ?? pathEditorView.points
        guard points.count > 2 else { return }
        points.removeLast()
        rebuildPathPointRows(points)
        configurationControlChanged(pathEditorView)
    }

    private func configurePathPointStack() {
        pathPointListStack.orientation = .vertical
        pathPointListStack.alignment = .leading
        pathPointListStack.spacing = 6
    }

    private func pathButtonRow() -> NSView {
        let add = FormFactory.button("Add Point", target: self, action: #selector(addPathPoint))
        let remove = FormFactory.button("Remove Last Point", target: self, action: #selector(removePathPoint))
        let row = NSStackView(views: [add, remove])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func pathPointRow(index: Int, point: NormalizedPoint) -> NSView {
        let number = NSTextField(labelWithString: "\(index + 1)")
        number.font = .systemFont(ofSize: 12, weight: .bold)
        number.textColor = .controlAccentColor
        number.widthAnchor.constraint(equalToConstant: 18).isActive = true
        let xField = pathCoordinateField(point.x)
        let yField = pathCoordinateField(point.y)
        pathPointFields.append((x: xField, y: yField))
        let row = NSStackView(views: [number, pointLabel("x"), xField, pointLabel("y"), yField])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 7
        return row
    }

    private func pathCoordinateField(_ value: Double) -> NSTextField {
        let field = FormFactory.textField(width: 58)
        field.stringValue = String(format: "%.3g", value)
        field.delegate = self
        field.target = self
        field.action = #selector(configurationControlChanged(_:))
        return field
    }

    private func pointLabel(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.textColor = .tertiaryLabelColor
        label.font = .systemFont(ofSize: 11, weight: .medium)
        return label
    }

    private func updatePathPointFields(_ points: [NormalizedPoint]) {
        guard points.count == pathPointFields.count else { return }
        for (point, fields) in zip(points, pathPointFields) {
            fields.x.stringValue = String(format: "%.3g", point.x)
            fields.y.stringValue = String(format: "%.3g", point.y)
        }
    }

    private func nextPathPoint(after previous: NormalizedPoint?) -> NormalizedPoint {
        guard let previous else { return NormalizedPoint(x: 0.5, y: 0.5) }
        return NormalizedPoint(
            x: clamp(previous.x + 0.12, min: 0, max: 1),
            y: clamp(previous.y, min: 0, max: 1)
        )
    }
}
