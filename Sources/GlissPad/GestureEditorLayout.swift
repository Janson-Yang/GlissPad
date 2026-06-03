import AppKit

@MainActor
extension GestureEditorWindowController {
    private var listScrollerOuterInset: CGFloat { 4 }
    private var listScrollerContentGutter: CGFloat { 18 }
    private var actionBadgeTopGutter: CGFloat { 8 }

    func makeContentView() -> NSView {
        let root = LiquidGlassStyle.rootView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = splitColumnDelegate
        splitView.addArrangedSubview(makeTriggerPane())
        splitView.addArrangedSubview(makeActionPane())
        splitView.addArrangedSubview(makeInspectorPane())
        splitView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(splitView)
        let transferControls = makeConfigurationTransferControls()
        transferControls.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(transferControls)
        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: root.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            transferControls.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),
            transferControls.topAnchor.constraint(equalTo: root.topAnchor, constant: 14)
        ])
        return root
    }

    func makeTriggerPane() -> NSView {
        let pane = glassColumn(material: .sidebar)
        configureTriggerListStack()
        let title = columnTitle("Trigger")
        let scrollArea = triggerScrollArea()
        title.translatesAutoresizingMaskIntoConstraints = false
        scrollArea.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(title)
        pane.addSubview(scrollArea)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 14),
            title.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -14),
            title.topAnchor.constraint(equalTo: pane.topAnchor, constant: 54),
            scrollArea.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 14),
            scrollArea.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -listScrollerOuterInset),
            scrollArea.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            scrollArea.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -16)
        ])
        rebuildTriggerList()
        return pane
    }

    func makeActionPane() -> NSView {
        let pane = glassColumn(material: .hudWindow)
        configureActionListStack()
        let title = columnTitle("Actions Executed On Trigger")
        let scrollArea = actionScrollArea()
        let testButton = testScriptButton()
        title.translatesAutoresizingMaskIntoConstraints = false
        scrollArea.translatesAutoresizingMaskIntoConstraints = false
        testButton.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(title)
        pane.addSubview(scrollArea)
        pane.addSubview(testButton)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -16),
            title.topAnchor.constraint(equalTo: pane.topAnchor, constant: 54),
            scrollArea.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            scrollArea.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -listScrollerOuterInset),
            scrollArea.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            scrollArea.bottomAnchor.constraint(equalTo: testButton.topAnchor, constant: -12),
            testButton.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            testButton.trailingAnchor.constraint(lessThanOrEqualTo: pane.trailingAnchor, constant: -16),
            testButton.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -16)
        ])
        return pane
    }

    func makeInspectorPane() -> NSView {
        let pane = NSVisualEffectView()
        pane.material = .underWindowBackground
        pane.blendingMode = .withinWindow
        pane.state = .active
        inspectorStack.orientation = .vertical
        inspectorStack.alignment = .width
        inspectorStack.distribution = .fill
        inspectorStack.spacing = 28
        inspectorStack.edgeInsets = NSEdgeInsets(top: 54, left: 0, bottom: 0, right: 0)
        attachInspectorStack(inspectorStack, to: pane)
        configureEditor()
        return pane
    }

    private func attachInspectorStack(_ stack: NSStackView, to pane: NSView) {
        stack.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: LiquidGlassStyle.inspectorInset),
            stack.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -LiquidGlassStyle.inspectorInset),
            stack.topAnchor.constraint(equalTo: pane.topAnchor),
            stack.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -LiquidGlassStyle.inspectorInset)
        ])
    }

    func makeInspectorHeader() -> NSView {
        let container = NSView()
        let titleRow = NSStackView(views: [titleLabel, enabledSwitch])
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 10
        let headerStack = NSStackView(views: [titleRow, statusLabel])
        headerStack.orientation = .vertical
        headerStack.alignment = .leading
        headerStack.spacing = 4
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            headerStack.topAnchor.constraint(equalTo: container.topAnchor),
            headerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    func addTriggerButton() -> NSButton {
        let button = ContextMenuButton(title: "", target: self, action: #selector(showAddTriggerMenu(_:)))
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.contextMenuProvider = { [weak self] in
            TriggerListItemContextMenu(index: nil, target: self).makeMenu()
        }
        LiquidGlassStyle.configureGhostButton(button)
        addButtonContent(title: "Add Trigger", to: button)
        return button
    }

    func triggerScrollArea() -> NSView {
        let content = columnStack(topInset: 0)
        content.alignment = .width
        content.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        addFullWidthArrangedSubview(triggerListStack, to: content)
        addFullWidthArrangedSubview(addTriggerButton(), to: content)
        let scrollView = StackScrollView(stack: content, trailingContentInset: listScrollerContentGutter)
        triggerScrollView = scrollView
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        return scrollView
    }

    func actionButton(for action: ActionSlot) -> NSButton {
        let scriptAction = selectedSlot.actions(in: configuration)[action.index]
        let button = ReorderableListItemButton(
            title: action.title(for: scriptAction),
            subtitle: action.subtitle(for: scriptAction),
            symbolName: action.symbolName(for: scriptAction),
            target: self,
            action: #selector(selectAction(_:))
        )
        button.identifier = NSUserInterfaceItemIdentifier("\(action.index)")
        button.contextMenuProvider = { [weak self] in
            ActionListItemContextMenu(index: action.index, target: self).makeMenu()
        }
        button.dragCallbacks = ListItemDragCallbacks(
            begin: { [weak self] in self?.beginActionReorder(from: action.index) ?? false },
            update: { [weak self] point in self?.updateActionReorder(windowPoint: point) },
            end: { [weak self] in self?.endActionReorder() }
        )
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        LiquidGlassStyle.configureActionButton(button, selected: action == selectedAction && inspectorMode == .action)
        actionButtons[action] = button
        return button
    }

    func actionRow(for action: ActionSlot) -> NSView {
        let row = NSView()
        let button = actionButton(for: action)
        let statusBadge = actionStatusBadge(for: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(button)
        row.addSubview(statusBadge, positioned: .above, relativeTo: button)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 54),
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            button.topAnchor.constraint(equalTo: row.topAnchor),
            button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            statusBadge.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: 5),
            statusBadge.topAnchor.constraint(equalTo: row.topAnchor, constant: -5),
            statusBadge.widthAnchor.constraint(equalToConstant: 22),
            statusBadge.heightAnchor.constraint(equalToConstant: 22)
        ])
        return row
    }

    func actionStatusBadge(for action: ActionSlot) -> ActionStatusBadgeView {
        let badge = ActionStatusBadgeView()
        badge.state = actionExecutionState(for: action)
        actionStatusBadges[action] = badge
        return badge
    }

    func addActionButton() -> NSButton {
        let button = ContextMenuButton(title: "", target: self, action: #selector(showAddActionMenu(_:)))
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.contextMenuProvider = { [weak self] in
            ActionListItemContextMenu(index: nil, target: self).makeMenu()
        }
        LiquidGlassStyle.configureGhostButton(button)
        addActionButtonContent(to: button)
        return button
    }

    func actionScrollArea() -> NSView {
        let content = columnStack(topInset: 0)
        content.alignment = .width
        content.edgeInsets = NSEdgeInsets(top: actionBadgeTopGutter, left: 0, bottom: 4, right: 0)
        addFullWidthArrangedSubview(actionListStack, to: content)
        addFullWidthArrangedSubview(addActionButton(), to: content)
        let scrollView = StackScrollView(
            stack: content,
            contentSizing: .arrangedSubviewHeights,
            trailingContentInset: listScrollerContentGutter
        )
        actionScrollView = scrollView
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        return scrollView
    }

    func rebuildActionList() {
        actionListStack.arrangedSubviews.forEach {
            actionListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        actionButtons.removeAll()
        actionStatusBadges.removeAll()
        let actions = selectedSlot.actions(in: configuration)
        for index in actions.indices {
            if index > 0 {
                addFullWidthArrangedSubview(ActionOrderSeparatorView(), to: actionListStack)
            }
            addFullWidthArrangedSubview(actionRow(for: ActionSlot(index: index)), to: actionListStack)
        }
        refreshSelectionVisuals()
        actionScrollView?.scheduleContentSizeRefresh()
    }

    func rebuildTriggerList() {
        triggerListStack.arrangedSubviews.forEach {
            triggerListStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        triggerButtons.removeAll()
        triggerStatusLights.removeAll()
        for index in configuration.gestures.triggers.indices {
            addFullWidthArrangedSubview(triggerRow(for: GestureSlot(index: index)), to: triggerListStack)
        }
        refreshSelectionVisuals()
        triggerScrollView?.scheduleContentSizeRefresh()
    }

}
