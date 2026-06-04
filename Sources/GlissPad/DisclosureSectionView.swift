import AppKit

final class DisclosureSectionView: NSStackView {
    private let toggleButton = NSButton()
    private let contentStack = NSStackView()
    private let minimumWidth: CGFloat
    private var expanded = false

    init(title: String, views: [NSView], minimumWidth: CGFloat) {
        self.minimumWidth = minimumWidth
        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = 10
        configureToggleButton(title: title)
        configureContentStack(views)
        addArrangedSubview(toggleButton)
        addArrangedSubview(contentStack)
        widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
        updateExpandedState()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func configureToggleButton(title: String) {
        toggleButton.title = title
        toggleButton.isBordered = false
        toggleButton.alignment = .left
        toggleButton.imagePosition = .imageLeading
        toggleButton.font = .systemFont(ofSize: 12, weight: .semibold)
        toggleButton.contentTintColor = .secondaryLabelColor
        toggleButton.target = self
        toggleButton.action = #selector(toggle)
        toggleButton.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func configureContentStack(_ views: [NSView]) {
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 10
        views.forEach { view in
            view.setContentHuggingPriority(.required, for: .horizontal)
            contentStack.addArrangedSubview(view)
        }
        contentStack.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
    }

    @objc private func toggle() {
        expanded.toggle()
        updateExpandedState()
    }

    private func updateExpandedState() {
        contentStack.isHidden = !expanded
        let symbol = expanded ? "chevron.down" : "chevron.right"
        toggleButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        invalidateIntrinsicContentSize()
        needsLayout = true
        scheduleScrollRefresh()
    }

    private func scheduleScrollRefresh() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.layoutSubtreeIfNeeded()
            if let scrollView = self.enclosingScrollView as? InspectorScrollView {
                scrollView.scheduleContentSizeRefresh()
            } else {
                self.enclosingScrollView?.needsLayout = true
            }
        }
    }
}
