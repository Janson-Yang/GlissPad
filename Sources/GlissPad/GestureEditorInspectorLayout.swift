import AppKit

@MainActor
extension GestureEditorWindowController {
    func setInitialSplitPositionsIfNeeded() {
        guard !didSetInitialSplitPositions, splitView.bounds.width > 0 else { return }
        didSetInitialSplitPositions = true
        let metrics = ScreenLayoutMetrics.current(for: window)
        let firstDivider = metrics.triggerColumnMinimumWidth
        let secondDivider = firstDivider
            + splitView.dividerThickness
            + metrics.actionColumnMinimumWidth
        splitView.setPosition(firstDivider, ofDividerAt: 0)
        splitView.setPosition(secondDivider, ofDividerAt: 1)
    }

    func rebuildInspector() {
        inspectorStack.arrangedSubviews.forEach {
            inspectorStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        switch inspectorMode {
        case .trigger:
            inspectorStack.addArrangedSubview(makeInspectorHeader())
            addInspectorPanel(scrollableInspectorPanel(makeSelectedTriggerConfigPanel()))
        case .action:
            addInspectorPanel(scrollableInspectorPanel(makeActionParameterPanel()))
        }
    }

    private func addInspectorPanel(_ panel: NSView) {
        panel.setContentHuggingPriority(.defaultLow, for: .vertical)
        inspectorStack.addArrangedSubview(panel)
    }

    private func makeSelectedTriggerConfigPanel() -> NSView {
        guard let trigger = selectedSlot.trigger(in: configuration) else {
            return makeNoTriggerPanel()
        }
        switch trigger.type {
        case .oneFingerTouchStart:
            return makeOneFingerTouchStartConfigPanel()
        case .oneFingerLongPress:
            return makeOneFingerLongPressConfigPanel()
        case .oneFingerCircle:
            return makeOneFingerCircleConfigPanel()
        case .oneFingerSquare, .oneFingerTriangle:
            return makeOneFingerShapeConfigPanel()
        case .oneFingerCornerClick:
            return makeOneFingerCornerClickConfigPanel()
        case .oneFingerTap:
            return makeOneFingerTapConfigPanel(isDoubleTap: false)
        case .oneFingerDoubleTap:
            return makeOneFingerTapConfigPanel(isDoubleTap: true)
        case .oneFingerPress:
            return makeOneFingerPressConfigPanel()
        case .oneFingerCustomPath:
            return makeCustomPathConfigPanel()
        case .oneFingerDrawnPath:
            return makeDrawnPathConfigPanel()
        case .twoFingerTouchStart:
            return makeTwoFingerTouchStartConfigPanel()
        case .twoFingerTap:
            return makeTwoFingerTapConfigPanel()
        case .tipTap:
            return makeTipTapConfigPanel()
        case .pinchIn, .pinchOut, .rotateLeft, .rotateRight:
            return makeTwoFingerTransformConfigPanel()
        case .freeformTwoFingerSwipe:
            return makeMultiFingerSwipeConfigPanel(needsRegions: false)
        case .regionTwoFingerSwipe:
            return makeMultiFingerSwipeConfigPanel(needsRegions: true)
        case .leftEdgeTwoFingerSwipe:
            return makeSwipeConfigPanel()
        case .twoFingerHold:
            return makeHoldConfigPanel()
        case .releaseLastFinger:
            return makeReleaseConfigPanel()
        case .threeFingerForcePress, .upperLeftForcePress, .upperRightForcePress:
            return makeTriggerConfigPanel()
        case .threeFingerTouch, .threeFingerTap, .threeFingerPress, .threeFingerSwipe,
             .threeFingerTipTap, .threeFingerTipSwipe, .thumbTwoFingerScale, .threeFingerDrawing:
            return makeThreeFingerConfigPanel(type: trigger.type)
        case .fourFingerTouch, .fourFingerTap, .fourFingerPress, .fourFingerSwipe,
             .thumbThreeFingerScale, .fourFingerTipTap, .fourFingerDrawing:
            return makeThreeFingerConfigPanel(type: trigger.type)
        }
    }

    private func scrollableInspectorPanel(_ content: NSView) -> NSScrollView {
        let scrollView = InspectorScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        let documentView = FlippedInspectorDocumentView()
        content.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(content)
        scrollView.documentView = documentView
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            content.topAnchor.constraint(equalTo: documentView.topAnchor),
            content.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor)
        ])
        return scrollView
    }
}

final class InspectorScrollView: NSScrollView {
    override func layout() {
        super.layout()
        resizeDocumentView()
    }

    override func viewWillDraw() {
        super.viewWillDraw()
        resizeDocumentView()
    }

    func scheduleContentSizeRefresh() {
        needsLayout = true
        DispatchQueue.main.async { [weak self] in
            self?.layoutSubtreeIfNeeded()
            self?.resizeDocumentView()
        }
    }

    private func resizeDocumentView() {
        guard let documentView else { return }
        let width = contentView.bounds.width
        documentView.frame.size.width = width
        documentView.layoutSubtreeIfNeeded()
        let height = max(contentView.bounds.height, measuredContentHeight(in: documentView))
        documentView.frame = NSRect(x: 0, y: 0, width: width, height: height)
    }

    private func measuredContentHeight(in documentView: NSView) -> CGFloat {
        documentView.subviews
            .map { max($0.fittingSize.height, $0.frame.height) }
            .max() ?? documentView.fittingSize.height
    }
}

private final class FlippedInspectorDocumentView: NSView {
    override var isFlipped: Bool { true }
}
