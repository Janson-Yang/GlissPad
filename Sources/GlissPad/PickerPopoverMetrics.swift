import AppKit

enum PickerPopoverMetrics {
    static let width: CGFloat = 320
    static let rowHeight: CGFloat = 36
    static let titleHeight: CGFloat = 16
    static let verticalInset: CGFloat = 18
    static let rowSpacing: CGFloat = 8

    static func contentSize(buttonCount: Int, titleCount: Int = 1) -> NSSize {
        let rowCount = buttonCount + titleCount
        let height = verticalInset * 2
            + CGFloat(buttonCount) * rowHeight
            + CGFloat(titleCount) * titleHeight
            + CGFloat(max(0, rowCount - 1)) * rowSpacing
        return NSSize(width: width, height: ceil(height))
    }
}
