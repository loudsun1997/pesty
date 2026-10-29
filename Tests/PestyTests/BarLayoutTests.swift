import XCTest
@testable import Pesty

final class BarLayoutTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    func testLeftDockDoesNotInsetOrNarrowTheStrip() {
        let layout = BarResizeGeometry.layoutFrame(
            screenFrame: screen,
            visibleFrame: CGRect(x: 80, y: 0, width: 1360, height: 875))
        XCTAssertEqual(layout, CGRect(x: 0, y: 0, width: 1440, height: 875))
        XCTAssertEqual(BarResizeGeometry.panelFrame(for: 430, in: layout),
                       CGRect(x: 0, y: 0, width: 1440, height: 430))
    }

    func testRightDockDoesNotNarrowTheStrip() {
        let layout = BarResizeGeometry.layoutFrame(
            screenFrame: screen,
            visibleFrame: CGRect(x: 0, y: 0, width: 1360, height: 875))
        XCTAssertEqual(layout, CGRect(x: 0, y: 0, width: 1440, height: 875))
    }

    func testBottomDockAndMenuBarKeepTheirVerticalExclusions() {
        let visible = CGRect(x: 0, y: 80, width: 1440, height: 795)
        let layout = BarResizeGeometry.layoutFrame(screenFrame: screen, visibleFrame: visible)
        XCTAssertEqual(layout, visible)
        XCTAssertEqual(BarResizeGeometry.panelFrame(for: 430, in: layout),
                       CGRect(x: 0, y: 80, width: 1440, height: 430))
    }

    func testSecondaryDisplayKeepsItsNegativeOrigin() {
        let layout = BarResizeGeometry.layoutFrame(
            screenFrame: CGRect(x: -1600, y: -900, width: 1600, height: 900),
            visibleFrame: CGRect(x: -1520, y: -900, width: 1520, height: 875))
        XCTAssertEqual(layout, CGRect(x: -1600, y: -900, width: 1600, height: 875))
        XCTAssertEqual(BarResizeGeometry.panelFrame(for: 430, in: layout),
                       CGRect(x: -1600, y: -900, width: 1600, height: 430))
    }

    func testLiveResizeAndCancellationKeepTheFullDisplayWidth() {
        let layout = BarResizeGeometry.layoutFrame(
            screenFrame: screen,
            visibleFrame: CGRect(x: 80, y: 0, width: 1360, height: 875))
        let session = BarResizeSession(initialPanelHeight: 430, initialScreenY: 100,
                                       visibleFrame: layout)
        XCTAssertEqual(session.frame(atScreenY: 200),
                       CGRect(x: 0, y: 0, width: 1440, height: 530))
        XCTAssertEqual(session.cancelledFrame,
                       CGRect(x: 0, y: 0, width: 1440, height: 430))
    }
}
