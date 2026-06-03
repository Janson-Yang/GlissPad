import AppKit

@MainActor
struct ListItemDragCallbacks {
    var begin: () -> Bool
    var update: (NSPoint) -> Void
    var end: () -> Void
}

@MainActor
final class ReorderableListItemButton: GlassListItemButton {
    var dragCallbacks: ListItemDragCallbacks?
    var contextMenuProvider: (() -> NSMenu)?
    private let dragThreshold: CGFloat = 5
    private var preview: NSImageView?
    private var previewStartFrame = NSRect.zero
    private var dragStart = NSPoint.zero

    override func mouseDown(with event: NSEvent) {
        guard dragCallbacks != nil else {
            super.mouseDown(with: event)
            return
        }
        handleMouseDown(event)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu = contextMenuProvider?() ?? menu else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
    }

    private func handleMouseDown(_ event: NSEvent) {
        isHighlighted = true
        let start = event.locationInWindow
        var didDrag = false
        while let nextEvent = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            switch nextEvent.type {
            case .leftMouseDragged:
                didDrag = updateDragIfNeeded(nextEvent, start: start, didDrag: didDrag)
            case .leftMouseUp:
                finishMouseDown(didDrag: didDrag)
                return
            default:
                break
            }
        }
        finishMouseDown(didDrag: didDrag)
    }

    private func updateDragIfNeeded(_ event: NSEvent, start: NSPoint, didDrag: Bool) -> Bool {
        let delta = hypot(event.locationInWindow.x - start.x, event.locationInWindow.y - start.y)
        let shouldBegin = !didDrag && delta >= dragThreshold
        if shouldBegin, dragCallbacks?.begin() != true { return false }
        if shouldBegin { beginPreview(at: start) }
        if didDrag || shouldBegin {
            updatePreview(at: event.locationInWindow)
            dragCallbacks?.update(event.locationInWindow)
        }
        return didDrag || shouldBegin
    }

    private func finishMouseDown(didDrag: Bool) {
        isHighlighted = false
        if didDrag {
            endPreview()
            dragCallbacks?.end()
        } else {
            performClick(nil)
        }
    }

    private func beginPreview(at point: NSPoint) {
        guard let contentView = window?.contentView else { return }
        dragStart = point
        previewStartFrame = convert(bounds, to: contentView)
        let imageView = NSImageView(frame: previewStartFrame)
        imageView.image = snapshotImage()
        imageView.imageScaling = .scaleAxesIndependently
        imageView.wantsLayer = true
        imageView.layer?.shadowColor = NSColor.black.cgColor
        imageView.layer?.shadowOpacity = 0.18
        imageView.layer?.shadowRadius = 14
        imageView.layer?.shadowOffset = CGSize(width: 0, height: -4)
        alphaValue = 0.25
        contentView.addSubview(imageView, positioned: .above, relativeTo: nil)
        preview = imageView
    }

    private func updatePreview(at point: NSPoint) {
        guard let preview else { return }
        let delta = NSPoint(x: point.x - dragStart.x, y: point.y - dragStart.y)
        preview.frame.origin = NSPoint(
            x: previewStartFrame.origin.x + delta.x,
            y: previewStartFrame.origin.y + delta.y
        )
    }

    private func endPreview() {
        alphaValue = 1
        preview?.removeFromSuperview()
        preview = nil
    }

    private func snapshotImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }
}
