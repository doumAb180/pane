import XCTest
import CoreGraphics
@testable import PaneCore

final class LayoutTests: XCTestCase {
    let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)
    let floating = CGRect(x: 200, y: 100, width: 600, height: 500)

    func testDirectionalCycleOnEveryEdge() {
        for layout in [Layout.left, .right, .top, .bottom] {
            let half = layout.nextFrame(in: screen, current: floating, gap: 0)
            let quarter = layout.nextFrame(in: screen, current: half, gap: 0)
            let again = layout.nextFrame(in: screen, current: quarter, gap: 0)
            XCTAssertEqual(half, again)
            if layout == .left || layout == .right {
                XCTAssertEqual(half.width, 720)
                XCTAssertEqual(quarter.width, 360)
                XCTAssertEqual(quarter.height, 876)
                XCTAssertEqual(layout == .left ? quarter.minX : quarter.maxX,
                               layout == .left ? screen.minX : screen.maxX)
            } else {
                XCTAssertEqual(half.height, 438)
                XCTAssertEqual(quarter.height, 219)
                XCTAssertEqual(quarter.width, 1440)
                XCTAssertEqual(layout == .top ? quarter.minY : quarter.maxY,
                               layout == .top ? screen.minY : screen.maxY)
            }
        }
    }

    func testGapDoesNotDoubleBetweenAdjacentWindows() {
        let left = Layout.left.frame(in: screen, current: floating, gap: 8)
        let right = Layout.right.frame(in: screen, current: floating, gap: 8)
        XCTAssertEqual(left.minX, 8)
        XCTAssertEqual(right.maxX, 1432)
        XCTAssertEqual(right.minX - left.maxX, 8)
        let quarter = Layout.right.nextFrame(in: screen, current: right, gap: 8)
        XCTAssertEqual(quarter.maxX, right.maxX)
        XCTAssertEqual(quarter.width, 350)
    }

    func testManualMovementResetsCycle() {
        var half = Layout.left.frame(in: screen, current: floating, gap: 8)
        half.origin.x += 20
        XCTAssertEqual(Layout.left.nextFrame(in: screen, current: half, gap: 8),
                       Layout.left.frame(in: screen, current: floating, gap: 8))
    }

    func testEveryLayoutStaysInsideNegativeOriginMonitor() {
        let bounds = CGRect(x: -1920, y: -500, width: 1920, height: 1080)
        for layout in Layout.allCases {
            let frame = layout.frame(in: bounds, current: floating, gap: 12)
            XCTAssertTrue(bounds.contains(frame), "\(layout)")
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
        }
    }

    func testThirdsHaveEqualWidthsAndSpacing() {
        let thirds = [Layout.firstThird, .middleThird, .lastThird].map {
            $0.frame(in: screen, current: floating, gap: 8)
        }
        XCTAssertEqual(thirds[0].width, thirds[2].width)
        XCTAssertEqual(thirds[1].minX - thirds[0].maxX, 8, accuracy: 0.001)
        XCTAssertEqual(thirds[2].maxX, screen.maxX - 8, accuracy: 0.001)
    }

    func testScreenCoordinatesForDisplaysAboveAndLeft() {
        XCTAssertEqual(ScreenGeometry.accessibilityFrame(fromAppKit: CGRect(x: -1000, y: 900, width: 1000, height: 700), primaryTop: 900),
                       CGRect(x: -1000, y: -700, width: 1000, height: 700))
        XCTAssertEqual(ScreenGeometry.accessibilityFrame(fromAppKit: CGRect(x: 0, y: 0, width: 1440, height: 876), primaryTop: 900), screen)
    }

    func testScreenSelectionUsesLargestIntersectionAndNearestFallback() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 900), CGRect(x: 1000, y: 0, width: 1000, height: 900)]
        XCTAssertEqual(ScreenGeometry.bestScreen(for: CGRect(x: 900, y: 50, width: 500, height: 300), screens: screens), 1)
        XCTAssertEqual(ScreenGeometry.bestScreen(for: CGRect(x: -900, y: 50, width: 100, height: 100), screens: screens), 0)
        XCTAssertNil(ScreenGeometry.bestScreen(for: floating, screens: []))
    }

    func testMoveToSmallerDisplayClampsSizeAndPreservesAlignment() {
        let source = CGRect(x: 0, y: 0, width: 2000, height: 1200)
        let destination = CGRect(x: -1000, y: 200, width: 1000, height: 800)
        let oversized = CGRect(x: 0, y: 0, width: 2000, height: 1200)
        XCTAssertEqual(ScreenGeometry.move(oversized, from: source, to: destination), destination)
        let right = CGRect(x: 1500, y: 600, width: 500, height: 600)
        let moved = ScreenGeometry.move(right, from: source, to: destination)
        XCTAssertEqual(moved.maxX, destination.maxX)
        XCTAssertEqual(moved.maxY, destination.maxY)
        XCTAssertEqual(moved.size, right.size)
    }
}
