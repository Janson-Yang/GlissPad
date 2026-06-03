import AppKit

@MainActor
final class SplitColumnDelegate: NSObject, NSSplitViewDelegate {
    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        switch dividerIndex {
        case 0:
            return metrics(for: splitView).triggerColumnMinimumWidth
        case 1:
            return firstColumnWidth(in: splitView)
                + splitView.dividerThickness
                + metrics(for: splitView).actionColumnMinimumWidth
        default:
            return proposedMinimumPosition
        }
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        switch dividerIndex {
        case 0:
            let metrics = metrics(for: splitView)
            return splitView.bounds.width
                - metrics.actionColumnMinimumWidth
                - metrics.inspectorColumnMinimumWidth
                - splitView.dividerThickness * 2
        case 1:
            return splitView.bounds.width
                - metrics(for: splitView).inspectorColumnMinimumWidth
                - splitView.dividerThickness
        default:
            return proposedMaximumPosition
        }
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        false
    }

    private func firstColumnWidth(in splitView: NSSplitView) -> CGFloat {
        guard let firstColumn = splitView.subviews.first else {
            return metrics(for: splitView).triggerColumnMinimumWidth
        }
        return firstColumn.frame.width
    }

    private func metrics(for splitView: NSSplitView) -> ScreenLayoutMetrics {
        ScreenLayoutMetrics.current(for: splitView.window)
    }
}
