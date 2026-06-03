import AppKit

@MainActor
final class StackScrollView: NSScrollView {
    enum ContentSizing {
        case fittingSize
        case arrangedSubviewHeights
    }

    private let stack: NSStackView
    private let document = FlippedStackDocumentView()
    private let contentSizing: ContentSizing
    private let trailingContentInset: CGFloat

    init(
        stack: NSStackView,
        contentSizing: ContentSizing = .fittingSize,
        trailingContentInset: CGFloat = 0
    ) {
        self.stack = stack
        self.contentSizing = contentSizing
        self.trailingContentInset = trailingContentInset
        super.init(frame: .zero)
        configureScrollView()
        attachStack()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        resizeDocument()
    }

    override func viewWillDraw() {
        super.viewWillDraw()
        resizeDocument()
    }

    func scheduleContentSizeRefresh() {
        needsLayout = true
        DispatchQueue.main.async { [weak self] in
            self?.refreshContentSize()
        }
    }

    func refreshContentSize() {
        layoutSubtreeIfNeeded()
        stack.layoutSubtreeIfNeeded()
        resizeDocument()
    }

    private func configureScrollView() {
        drawsBackground = false
        borderType = .noBorder
        hasVerticalScroller = true
        autohidesScrollers = true
        scrollerStyle = .overlay
        documentView = document
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    private func attachStack() {
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -trailingContentInset),
            stack.topAnchor.constraint(equalTo: document.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: document.bottomAnchor)
        ])
    }

    private func resizeDocument() {
        let width = max(contentView.bounds.width, 1)
        let contentHeight = measuredContentHeight()
        let height = max(contentView.bounds.height, contentHeight)
        document.frame = NSRect(x: 0, y: 0, width: width, height: height)
    }

    private func measuredContentHeight() -> CGFloat {
        switch contentSizing {
        case .fittingSize:
            return stack.fittingSize.height
        case .arrangedSubviewHeights:
            return max(stack.fittingSize.height, StackContentHeightMeasurer.height(for: stack))
        }
    }
}

private final class FlippedStackDocumentView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
private enum StackContentHeightMeasurer {
    static func height(for stack: NSStackView) -> CGFloat {
        let visibleViews = stack.arrangedSubviews.filter { !$0.isHidden }
        let childHeight = visibleViews.reduce(CGFloat.zero) { total, view in
            total + height(for: view)
        }
        let spacing = CGFloat(max(visibleViews.count - 1, 0)) * stack.spacing
        return stack.edgeInsets.top + childHeight + spacing + stack.edgeInsets.bottom
    }

    private static func height(for view: NSView) -> CGFloat {
        if let stack = view as? NSStackView, stack.orientation == .vertical {
            return height(for: stack)
        }
        return max(explicitHeight(for: view), view.fittingSize.height, view.frame.height)
    }

    private static func explicitHeight(for view: NSView) -> CGFloat {
        view.constraints.compactMap { constraint in
            constantHeight(from: constraint, for: view)
        }.max() ?? 0
    }

    private static func constantHeight(from constraint: NSLayoutConstraint, for view: NSView) -> CGFloat? {
        guard constraint.firstItem === view,
              constraint.firstAttribute == .height,
              constraint.secondItem == nil,
              constraint.relation == .equal else {
            return nil
        }
        return max(constraint.constant, 0)
    }
}
