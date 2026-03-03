import CoreGraphics

enum RulerUnit: Int, CaseIterable {
    case centimeter = 0
    case inch = 1

    var title: String {
        switch self {
        case .centimeter:
            return "cm"
        case .inch:
            return "in"
        }
    }

    var subdivisions: Int {
        switch self {
        case .centimeter:
            return 10
        case .inch:
            return 16
        }
    }

    var centimetersPerUnit: CGFloat {
        switch self {
        case .centimeter:
            return 1
        case .inch:
            return 2.54
        }
    }
}
