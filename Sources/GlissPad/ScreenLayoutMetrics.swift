import AppKit

@MainActor
struct ScreenLayoutMetrics {
    private static let minimumWindowWidthRatio: CGFloat = 0.70
    private static let minimumWindowHeightRatio: CGFloat = 0.75
    private static let triggerColumnWidthRatio: CGFloat = 0.20
    private static let actionColumnWidthRatio: CGFloat = 0.20
    private static let inspectorColumnWidthRatio: CGFloat = 0.30
    private static let fallbackScreenSize = NSSize(width: 1200, height: 800)
    private static let fallbackInitialWindowSize = NSSize(width: 1240, height: 740)

    private let visibleFrame: NSRect

    static func current(for window: NSWindow?) -> ScreenLayoutMetrics {
        let frame = usableFrame(window?.screen?.visibleFrame)
            ?? largestUsableScreenFrame()
            ?? NSRect(origin: .zero, size: fallbackScreenSize)
        return ScreenLayoutMetrics(visibleFrame: frame)
    }

    var initialWindowRect: NSRect {
        let size = initialWindowSize
        return NSRect(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    var minimumWindowSize: NSSize {
        NSSize(
            width: visibleFrame.width * Self.minimumWindowWidthRatio,
            height: visibleFrame.height * Self.minimumWindowHeightRatio
        )
    }

    var initialWindowSize: NSSize {
        let minimum = minimumWindowSize
        return NSSize(
            width: max(Self.fallbackInitialWindowSize.width, minimum.width),
            height: max(Self.fallbackInitialWindowSize.height, minimum.height)
        )
    }

    var triggerColumnMinimumWidth: CGFloat {
        visibleFrame.width * Self.triggerColumnWidthRatio
    }

    var actionColumnMinimumWidth: CGFloat {
        visibleFrame.width * Self.actionColumnWidthRatio
    }

    var inspectorColumnMinimumWidth: CGFloat {
        visibleFrame.width * Self.inspectorColumnWidthRatio
    }

    private static func largestUsableScreenFrame() -> NSRect? {
        NSScreen.screens
            .compactMap { usableFrame($0.visibleFrame) }
            .max { $0.area < $1.area }
    }

    private static func usableFrame(_ frame: NSRect?) -> NSRect? {
        guard let frame, frame.width > 0, frame.height > 0 else { return nil }
        return frame
    }
}

private extension NSRect {
    var area: CGFloat {
        width * height
    }
}
