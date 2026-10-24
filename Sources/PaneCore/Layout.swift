import Foundation
import CoreGraphics

public enum Layout: String, CaseIterable {
    case left, right, top, bottom
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, middleThird, lastThird
    case maximize, center

    /// Repeating a directional placement toggles half ↔ quarter on that axis.
    /// Inspect actual geometry so moving a window manually resets the cycle.
    public func nextFrame(in bounds: CGRect, current: CGRect, gap: CGFloat) -> CGRect {
        let half = frame(in: bounds, current: current, gap: gap)
        guard [.left, .right, .top, .bottom].contains(self),
              abs(current.minX - half.minX) < 3, abs(current.minY - half.minY) < 3,
              abs(current.width - half.width) < 3, abs(current.height - half.height) < 3 else { return half }
        let gap = min(max(0, gap), min(bounds.width, bounds.height) / 10)
        let area = bounds.insetBy(dx: gap, dy: gap)
        var quarter = half
        switch self {
        case .left, .right:
            quarter.size.width = (area.width - 3 * gap) / 4
            if self == .right { quarter.origin.x = area.maxX - quarter.width }
        case .top, .bottom:
            quarter.size.height = (area.height - 3 * gap) / 4
            if self == .bottom { quarter.origin.y = area.maxY - quarter.height }
        default: break
        }
        return quarter
    }

    /// All rectangles use Accessibility's top-left coordinate system, in points.
    public func frame(in bounds: CGRect, current: CGRect, gap: CGFloat) -> CGRect {
        let gap = min(max(0, gap), min(bounds.width, bounds.height) / 10)
        let area = bounds.insetBy(dx: gap, dy: gap)
        if self == .center {
            let size = CGSize(width: min(current.width, area.width), height: min(current.height, area.height))
            return CGRect(x: area.midX - size.width / 2, y: area.midY - size.height / 2,
                          width: size.width, height: size.height)
        }
        let columns: Int
        let rows: Int
        let column: Int
        let row: Int
        switch self {
        case .left: (columns, rows, column, row) = (2, 1, 0, 0)
        case .right: (columns, rows, column, row) = (2, 1, 1, 0)
        case .top: (columns, rows, column, row) = (1, 2, 0, 0)
        case .bottom: (columns, rows, column, row) = (1, 2, 0, 1)
        case .topLeft: (columns, rows, column, row) = (2, 2, 0, 0)
        case .topRight: (columns, rows, column, row) = (2, 2, 1, 0)
        case .bottomLeft: (columns, rows, column, row) = (2, 2, 0, 1)
        case .bottomRight: (columns, rows, column, row) = (2, 2, 1, 1)
        case .firstThird: (columns, rows, column, row) = (3, 1, 0, 0)
        case .middleThird: (columns, rows, column, row) = (3, 1, 1, 0)
        case .lastThird: (columns, rows, column, row) = (3, 1, 2, 0)
        case .maximize, .center: (columns, rows, column, row) = (1, 1, 0, 0)
        }
        let width = (area.width - CGFloat(columns - 1) * gap) / CGFloat(columns)
        let height = (area.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
        return CGRect(x: area.minX + CGFloat(column) * (width + gap),
                      y: area.minY + CGFloat(row) * (height + gap), width: width, height: height)
    }
}

public enum ScreenGeometry {
    public static func accessibilityFrame(fromAppKit frame: CGRect, primaryTop: CGFloat) -> CGRect {
        CGRect(x: frame.minX, y: primaryTop - frame.maxY, width: frame.width, height: frame.height)
    }

    public static func bestScreen(for window: CGRect, screens: [CGRect]) -> Int? {
        guard !screens.isEmpty else { return nil }
        let overlaps = screens.map { screen -> CGFloat in
            let intersection = screen.intersection(window)
            return intersection.isNull ? 0 : intersection.width * intersection.height
        }
        if let largest = overlaps.max(), largest > 0 { return overlaps.firstIndex(of: largest) }
        return screens.indices.min { a, b in
            distance(window, screens[a]) < distance(window, screens[b])
        }
    }

    private static func distance(_ a: CGRect, _ b: CGRect) -> CGFloat {
        pow(a.midX - b.midX, 2) + pow(a.midY - b.midY, 2)
    }

    public static func move(_ window: CGRect, from source: CGRect, to destination: CGRect) -> CGRect {
        let width = min(window.width, destination.width)
        let height = min(window.height, destination.height)
        let xRatio = max(0, min(1, (window.minX - source.minX) / max(1, source.width - window.width)))
        let yRatio = max(0, min(1, (window.minY - source.minY) / max(1, source.height - window.height)))
        return CGRect(x: destination.minX + xRatio * (destination.width - width),
                      y: destination.minY + yRatio * (destination.height - height),
                      width: width, height: height)
    }
}
