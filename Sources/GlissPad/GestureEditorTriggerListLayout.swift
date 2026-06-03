import AppKit

@MainActor
extension GestureEditorWindowController {
    func triggerButton(for slot: GestureSlot) -> NSButton {
        let button = ReorderableListItemButton(
            title: slot.displayName(in: configuration),
            subtitle: slot.title(in: configuration),
            symbolName: slot.symbolName(in: configuration),
            target: self,
            action: #selector(selectGesture(_:))
        )
        button.identifier = NSUserInterfaceItemIdentifier("\(slot.rawValue)")
        button.contextMenuProvider = { [weak self] in
            TriggerListItemContextMenu(index: slot.index, target: self).makeMenu()
        }
        button.dragCallbacks = ListItemDragCallbacks(
            begin: { [weak self] in self?.beginTriggerReorder(from: slot.index) ?? false },
            update: { [weak self] point in self?.updateTriggerReorder(windowPoint: point) },
            end: { [weak self] in self?.endTriggerReorder() }
        )
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        LiquidGlassStyle.configureListButton(button, selected: slot == selectedSlot)
        triggerButtons[slot] = button
        return button
    }

    func triggerRow(for slot: GestureSlot) -> NSView {
        let row = NSView()
        let button = triggerButton(for: slot)
        let light = triggerStatusLight(for: slot)
        button.translatesAutoresizingMaskIntoConstraints = false
        light.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(button)
        row.addSubview(light)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 52),
            button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            button.topAnchor.constraint(equalTo: row.topAnchor),
            button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            light.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            light.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            light.widthAnchor.constraint(equalToConstant: 14),
            light.heightAnchor.constraint(equalToConstant: 14)
        ])
        return row
    }

    func triggerStatusLight(for slot: GestureSlot) -> TriggerStatusLightView {
        let light = TriggerStatusLightView()
        light.isTriggerEnabled = slot.isEnabled(in: configuration)
        triggerStatusLights[slot] = light
        return light
    }
}
