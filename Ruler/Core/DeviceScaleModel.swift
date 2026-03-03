import CoreGraphics
import Foundation

enum DeviceCategory {
    case phone
    case pad
    case tv
    case mac
    case unknown
}

struct DeviceScaleModel: Equatable {
    let identifier: String
    let displayName: String
    let ppi: CGFloat
    let pixelsPerPoint: CGFloat

    var pointsPerCentimeter: CGFloat {
        guard ppi > 0, pixelsPerPoint > 0 else { return 0 }
        return (ppi / 2.54) / pixelsPerPoint
    }

    static func resolve(
        identifier: String,
        category: DeviceCategory,
        pixelsPerPoint: CGFloat,
        simulatorName: String? = nil
    ) -> DeviceScaleModel {
        let normalizedPixelsPerPoint = max(pixelsPerPoint, 1)
        let normalizedIdentifier = identifier.isEmpty ? "UnknownDevice" : identifier
        let knownModel = modelByIdentifier[normalizedIdentifier]
        let ppi = knownModel?.ppi ?? fallbackPPI(for: category, simulatorName: simulatorName)
        let displayName = knownModel?.name ?? simulatorName ?? normalizedIdentifier

        return DeviceScaleModel(
            identifier: normalizedIdentifier,
            displayName: displayName,
            ppi: ppi,
            pixelsPerPoint: normalizedPixelsPerPoint
        )
    }

    private static func fallbackPPI(for category: DeviceCategory, simulatorName: String?) -> CGFloat {
        switch category {
        case .phone:
            return 460
        case .pad:
            if let simulatorName, simulatorName.localizedCaseInsensitiveContains("mini") {
                return 326
            }
            return 264
        case .tv:
            return 326
        case .mac:
            return 220
        case .unknown:
            return 326
        }
    }

    private static let modelByIdentifier: [String: (name: String, ppi: CGFloat)] = [
        "iPhone15,2": ("iPhone 14 Pro", 460),
        "iPhone15,3": ("iPhone 14 Pro Max", 460),
        "iPhone15,4": ("iPhone 15", 460),
        "iPhone15,5": ("iPhone 15 Plus", 460),
        "iPhone16,1": ("iPhone 15 Pro", 460),
        "iPhone16,2": ("iPhone 15 Pro Max", 460),
        "iPhone17,1": ("iPhone 16 Pro", 460),
        "iPhone17,2": ("iPhone 16 Pro Max", 460),
        "iPhone17,3": ("iPhone 16", 460),
        "iPhone17,4": ("iPhone 16 Plus", 460),
        "iPhone17,5": ("iPhone 16e", 460)
    ]
}
