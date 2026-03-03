import XCTest
@testable import RulerCore

final class RulerScaleMathTests: XCTestCase {
    func testPointsPerUnitForCentimeterAndInch() {
        let cm = RulerScaleMath.pointsPerUnit(pointsPerCentimeter: 50, unit: .centimeter)
        let inch = RulerScaleMath.pointsPerUnit(pointsPerCentimeter: 50, unit: .inch)

        XCTAssertEqual(cm, 50, accuracy: 0.0001)
        XCTAssertEqual(inch, 127, accuracy: 0.0001)
    }

    func testMinorTickRangeAddsOneTickPadding() {
        let range = RulerScaleMath.minorTickRange(
            offset: 0,
            viewportStart: 56,
            viewportEnd: 200,
            minorStep: 10
        )

        XCTAssertEqual(range, 4...21)
    }

    func testMajorTickRangeReturnsNilForInvalidStep() {
        let range = RulerScaleMath.majorTickRange(
            offset: 0,
            viewportStart: 56,
            viewportEnd: 200,
            pointsPerUnit: 0
        )

        XCTAssertNil(range)
    }

    func testCoordinateValueUsesMidpointAndOffset() {
        let value = RulerScaleMath.coordinateValue(
            viewportMid: 200,
            offset: 50,
            pointsPerUnit: 100
        )

        XCTAssertEqual(value, 2.5, accuracy: 0.0001)
    }
}
