import AppKit
import GlissPadCore

@MainActor
enum TriggerPickerPopover {
    static func show(from sender: NSButton, target: AnyObject, action: Selector) -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        let controller = TriggerPickerViewController(target: target, action: action)
        controller.popover = popover
        popover.contentViewController = controller
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        return popover
    }
}

@MainActor
private final class TriggerPickerViewController: NSViewController {
    private let actionTarget: AnyObject
    private let actionSelector: Selector
    private let panel = GlassPanelView(material: .hudWindow)
    private let stack = NSStackView()
    weak var popover: NSPopover?

    init(target: AnyObject, action: Selector) {
        actionTarget = target
        actionSelector = action
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = panel
        configureStack()
        showRoot()
    }

    private func configureStack() {
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor, constant: -18)
        ])
    }

    private func showRoot() {
        let buttons = [oneFingerCategoryButton(), twoFingerCategoryButton()] + rootTriggerButtons()
        replaceStack(with: [title("Add Trigger")] + buttons, buttonCount: buttons.count)
    }

    @objc private func showOneFingerGestures() {
        let back = backButton()
        let triggerButtons = oneFingerTriggerButtons()
        replaceStack(with: [back, title("One Finger Gestures")] + triggerButtons, buttonCount: triggerButtons.count + 1)
    }

    @objc private func showTwoFingerGestures() {
        let back = backButton()
        let triggerButtons = twoFingerTriggerButtons()
        replaceStack(with: [back, title("Two Finger Gestures")] + triggerButtons, buttonCount: triggerButtons.count + 1)
    }

    @objc private func goBack() {
        showRoot()
    }

    private func replaceStack(with views: [NSView], buttonCount: Int) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        views.forEach(stack.addArrangedSubview)
        popover?.contentSize = PickerPopoverMetrics.contentSize(buttonCount: buttonCount)
    }

    private func title(_ value: String) -> NSTextField {
        let label = NSTextField(labelWithString: value)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func rootTriggerButtons() -> [NSButton] {
        GestureTriggerType.allCases
            .filter { !Self.oneFingerTypes.contains($0) }
            .filter { !Self.twoFingerTypes.contains($0) }
            .filter { !Self.hiddenTypes.contains($0) }
            .map(triggerButton)
    }

    private func oneFingerTriggerButtons() -> [NSButton] {
        Self.oneFingerTypes.map(triggerButton)
    }

    private func twoFingerTriggerButtons() -> [NSButton] {
        Self.twoFingerTypes.map(triggerButton)
    }

    private func oneFingerCategoryButton() -> NSButton {
        let button = pickerButton(
            title: "One Finger Gestures",
            symbolName: "hand.point.up.left.fill",
            accessorySymbolName: "line.3.horizontal",
            target: self,
            action: #selector(showOneFingerGestures)
        )
        return button
    }

    private func twoFingerCategoryButton() -> NSButton {
        pickerButton(
            title: "Two Finger Gestures",
            symbolName: "hand.raised.fingers.spread.fill",
            accessorySymbolName: "line.3.horizontal",
            target: self,
            action: #selector(showTwoFingerGestures)
        )
    }

    private func backButton() -> NSButton {
        pickerButton(
            title: "Back",
            symbolName: "chevron.left",
            target: self,
            action: #selector(goBack)
        )
    }

    private func triggerButton(_ type: GestureTriggerType) -> NSButton {
        let button = pickerButton(
            title: type.displayName,
            symbolName: type.symbolName,
            target: actionTarget,
            action: actionSelector
        )
        button.identifier = NSUserInterfaceItemIdentifier(type.rawValue)
        return button
    }

    private func pickerButton(
        title: String,
        symbolName: String,
        accessorySymbolName: String? = nil,
        target: AnyObject,
        action: Selector
    ) -> NSButton {
        let button = GlassListItemButton(
            title: title,
            symbolName: symbolName,
            accessorySymbolName: accessorySymbolName,
            target: target,
            action: action
        )
        button.widthAnchor.constraint(equalToConstant: 272).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        LiquidGlassStyle.configureListButton(button, selected: false)
        return button
    }

    private static let oneFingerTypes: [GestureTriggerType] = [
        .oneFingerTouchStart,
        .oneFingerLongPress,
        .oneFingerCircle,
        .oneFingerSquare,
        .oneFingerTriangle,
        .oneFingerCornerClick,
        .oneFingerTap,
        .oneFingerDoubleTap,
        .oneFingerCustomPath,
        .oneFingerDrawnPath
    ]

    private static let twoFingerTypes: [GestureTriggerType] = [
        .twoFingerTouchStart,
        .twoFingerHold,
        .twoFingerTap,
        .tipTap,
        .pinchIn,
        .pinchOut,
        .rotateLeft,
        .rotateRight,
        .freeformTwoFingerSwipe,
        .regionTwoFingerSwipe
    ]

    private static let hiddenTypes: [GestureTriggerType] = [
        .oneFingerPress,
        .upperLeftForcePress,
        .upperRightForcePress,
        .leftEdgeTwoFingerSwipe
    ]
}
