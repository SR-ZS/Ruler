import XCTest
@testable import RulerCore

final class DeviceScaleModelTests: XCTestCase {
    func testKnownPhoneIdentifierUsesCatalogNameAndPPI() {
        let model = DeviceScaleModel.resolve(
            identifier: "iPhone16,1",
            category: .phone,
            pixelsPerPoint: 3,
            simulatorName: nil
        )

        XCTAssertEqual(model.displayName, "iPhone 15 Pro")
        XCTAssertEqual(model.ppi, 460, accuracy: 0.0001)
        XCTAssertEqual(model.pointsPerCentimeter, 60.3674, accuracy: 0.001)
    }

    func testUnknownPadUsesPadFallbackPPI() {
        let model = DeviceScaleModel.resolve(
            identifier: "iPad99,9",
            category: .pad,
            pixelsPerPoint: 2,
            simulatorName: nil
        )

        XCTAssertEqual(model.ppi, 264, accuracy: 0.0001)
        XCTAssertEqual(model.displayName, "iPad99,9")
        XCTAssertEqual(model.pointsPerCentimeter, 51.9685, accuracy: 0.001)
    }

    func testUnknownPadMiniSimulatorUsesMiniFallback() {
        let model = DeviceScaleModel.resolve(
            identifier: "iPad99,10",
            category: .pad,
            pixelsPerPoint: 2,
            simulatorName: "iPad mini (A17 Pro)"
        )

        XCTAssertEqual(model.ppi, 326, accuracy: 0.0001)
        XCTAssertEqual(model.displayName, "iPad mini (A17 Pro)")
    }

    func testResolveNormalizesInvalidInputs() {
        let model = DeviceScaleModel.resolve(
            identifier: "",
            category: .unknown,
            pixelsPerPoint: 0,
            simulatorName: "Simulator Device"
        )

        XCTAssertEqual(model.identifier, "UnknownDevice")
        XCTAssertEqual(model.displayName, "Simulator Device")
        XCTAssertEqual(model.pixelsPerPoint, 1, accuracy: 0.0001)
        XCTAssertEqual(model.ppi, 326, accuracy: 0.0001)
    }
}
